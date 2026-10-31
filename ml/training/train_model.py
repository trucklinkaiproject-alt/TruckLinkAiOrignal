"""
ml/training/train_model.py

Reproducible training pipeline for the TruckLink AI Broker Recommender model.
Uses scikit-learn RandomForestClassifier with grouped request splitting to eliminate leakage.
"""

import os
import json
import joblib
import numpy as np
import pandas as pd
from datetime import datetime, timezone
from sklearn.model_selection import GroupShuffleSplit
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import (
    roc_auc_score,
    average_precision_score,
    precision_score,
    recall_score,
    f1_score,
    classification_report,
    ndcg_score,
)

from feature_engineering import (
    build_feature_matrix,
    get_feature_schema,
    MODEL_FEATURE_NAMES,
)

BASE_DIR = os.path.dirname(os.path.dirname(__file__))
DATA_PATH = os.path.join(BASE_DIR, "data", "history.csv")
MODELS_DIR = os.path.join(BASE_DIR, "models")


def compute_ranking_metrics(df_test: pd.DataFrame, y_pred_prob: np.ndarray, top_k: int = 3):
    """Computes Precision@K and NDCG@K grouped by request_id."""
    df_eval = df_test.copy()
    df_eval["score"] = y_pred_prob

    precisions = []
    ndcgs = []

    for _, group in df_eval.groupby("request_id"):
        if len(group) < 2:
            continue

        true_relevance = group["is_successful"].values
        pred_scores = group["score"].values

        # If all items are 0, NDCG is undefined/trivial
        if true_relevance.sum() == 0:
            continue

        # Precision@K
        sorted_indices = np.argsort(pred_scores)[::-1]
        top_k_indices = sorted_indices[:top_k]
        top_k_labels = true_relevance[top_k_indices]
        precisions.append(top_k_labels.sum() / min(top_k, len(top_k_indices)))

        # NDCG@K
        try:
            ndcg = ndcg_score([true_relevance], [pred_scores], k=top_k)
            ndcgs.append(ndcg)
        except Exception:
            pass

    avg_p_at_k = float(np.mean(precisions)) if precisions else 0.0
    avg_ndcg_at_k = float(np.mean(ndcgs)) if ndcgs else 0.0

    return {
        f"precision@{top_k}": round(avg_p_at_k, 4),
        f"ndcg@{top_k}": round(avg_ndcg_at_k, 4),
        "evaluated_requests_count": len(precisions),
    }


def train_recommender():
    os.makedirs(MODELS_DIR, exist_ok=True)

    print("=" * 65)
    print(" TRUCKLINK AI - BROKER RECOMMENDATION MODEL TRAINING PIPELINE")
    print("=" * 65)

    if not os.path.exists(DATA_PATH):
        raise FileNotFoundError(f"Training dataset missing at {DATA_PATH}. Run generate_historical_dataset.py first.")

    df_raw = pd.read_csv(DATA_PATH)
    print(f"[Data] Loaded {len(df_raw)} records across {df_raw['request_id'].nunique()} unique requests.")

    # 1. Group-based train/test split to prevent cross-request leakage
    splitter = GroupShuffleSplit(n_splits=1, test_size=0.20, random_state=42)
    train_idx, test_idx = next(splitter.split(df_raw, groups=df_raw["request_id"]))

    df_train = df_raw.iloc[train_idx].copy()
    df_test = df_raw.iloc[test_idx].copy()

    print(f"[Split] Train Set: {len(df_train)} rows ({df_train['request_id'].nunique()} requests)")
    print(f"[Split] Test Set:  {len(df_test)} rows ({df_test['request_id'].nunique()} requests)")

    # 2. Build feature matrices
    X_train = build_feature_matrix(df_train)
    y_train = df_train["is_successful"].values

    X_test = build_feature_matrix(df_test)
    y_test = df_test["is_successful"].values

    print(f"[Features] Built feature matrix with {X_train.shape[1]} features:")
    for i, col in enumerate(MODEL_FEATURE_NAMES, 1):
        print(f"   {i:02d}. {col}")

    # 3. Model Architecture: Supervised RandomForest with balanced weights
    model = RandomForestClassifier(
        n_estimators=120,
        max_depth=7,
        min_samples_split=6,
        min_samples_leaf=3,
        class_weight="balanced",
        random_state=42,
        n_jobs=-1,
    )

    print("\n[Training] Fitting RandomForestClassifier on training split...")
    model.fit(X_train, y_train)

    # 4. Evaluation
    y_prob_test = model.predict_proba(X_test)[:, 1]
    y_pred_test = (y_prob_test >= 0.50).astype(int)

    roc_auc = float(roc_auc_score(y_test, y_prob_test))
    avg_prec = float(average_precision_score(y_test, y_prob_test))
    f1 = float(f1_score(y_test, y_pred_test, zero_division=0))
    precision = float(precision_score(y_test, y_pred_test, zero_division=0))
    recall = float(recall_score(y_test, y_pred_test, zero_division=0))

    ranking_metrics = compute_ranking_metrics(df_test, y_prob_test, top_k=3)

    print("\n" + "=" * 65)
    print(" EVALUATION RESULTS (TEST SPLIT)")
    print("=" * 65)
    print(f"  - ROC-AUC:            {roc_auc:.4f}")
    print(f"  - Average Precision:  {avg_prec:.4f}")
    print(f"  - Precision:          {precision:.4f}")
    print(f"  - Recall:             {recall:.4f}")
    print(f"  - F1 Score:           {f1:.4f}")
    print(f"  - Precision@3:        {ranking_metrics['precision@3']:.4f}")
    print(f"  - NDCG@3:             {ranking_metrics['ndcg@3']:.4f}")
    print("=" * 65)

    # Feature Importance
    importances = model.feature_importances_
    sorted_feat_indices = np.argsort(importances)[::-1]
    print("\nTop Feature Importances:")
    for rank, idx in enumerate(sorted_feat_indices[:8], 1):
        print(f"  {rank}. {MODEL_FEATURE_NAMES[idx]}: {importances[idx]:.4f}")

    # 5. Save Artifacts
    model_path = os.path.join(MODELS_DIR, "broker_recommender.pkl")
    schema_path = os.path.join(MODELS_DIR, "feature_schema.json")
    meta_path = os.path.join(MODELS_DIR, "model_metadata.json")

    joblib.dump(model, model_path)
    print(f"\n[Artifact] Saved trained model -> {model_path}")

    schema = get_feature_schema()
    with open(schema_path, "w") as f:
        json.dump(schema, f, indent=2)
    print(f"[Artifact] Saved feature schema -> {schema_path}")

    metadata = {
        "model_type": "RandomForestClassifier",
        "library": "scikit-learn",
        "trained_at_utc": datetime.now(timezone.utc).isoformat(),
        "train_samples": len(df_train),
        "test_samples": len(df_test),
        "feature_count": len(MODEL_FEATURE_NAMES),
        "features": MODEL_FEATURE_NAMES,
        "evaluation_metrics": {
            "roc_auc": round(roc_auc, 4),
            "average_precision": round(avg_prec, 4),
            "precision": round(precision, 4),
            "recall": round(recall, 4),
            "f1": round(f1, 4),
            "precision@3": ranking_metrics["precision@3"],
            "ndcg@3": ranking_metrics["ndcg@3"],
        },
        "target_definition": "1 if broker accepted and completed shipment with eligible active driver nearby; 0 otherwise.",
    }

    with open(meta_path, "w") as f:
        json.dump(metadata, f, indent=2)
    print(f"[Artifact] Saved model metadata -> {meta_path}")

    print("\n>>> Phase 3 Training Pipeline Completed Successfully.")


if __name__ == "__main__":
    train_recommender()

