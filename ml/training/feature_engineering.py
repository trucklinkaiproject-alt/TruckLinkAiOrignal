"""
ml/training/feature_engineering.py

Feature engineering and schema management for TruckLink AI Broker Recommender.
Ensures identical feature calculation and transformation between training and inference.
"""

from typing import List, Dict, Any
import numpy as np
import pandas as pd

# Canonical source-of-truth categories discovered from Flutter application
CANONICAL_VEHICLE_TYPES = [
    "Truck",
    "Van",
    "Trailer",
    "Container",
    "PickUp Truck",
    "Shahzore",
    "Loader Rickshaw",
    "Other",
]

CANONICAL_CARGO_TYPES = [
    "Furniture",
    "Plastic",
    "Glass",
    "Iron",
    "Machinery",
    "Other",
]

# Canonical feature list expected by model
NUMERIC_FEATURES = [
    "nearest_driver_distance_km",
    "active_drivers_count",
    "broker_rating",
    "broker_acceptance_rate",
    "broker_completion_rate",
    "broker_cancellation_rate",
    "total_requests",
]

CATEGORICAL_FEATURES = [
    "required_vehicle_type",
]

# Derived / Engineered features:
# - distance_decay_score = exp(-dist / 30.0)
# - broker_quality_index = (rating / 5.0) * 0.4 + (completion_rate / 100.0) * 0.4 + (acceptance_rate / 100.0) * 0.2
ENGINEERED_FEATURES = [
    "distance_decay_score",
    "broker_quality_index",
]

MODEL_FEATURE_NAMES = (
    NUMERIC_FEATURES
    + ENGINEERED_FEATURES
    + [f"vehicle_{v.lower().replace(' ', '_')}" for v in CANONICAL_VEHICLE_TYPES]
)


def compute_engineered_features(df: pd.DataFrame) -> pd.DataFrame:
    """Computes non-leaking domain features based on physics and operational semantics."""
    df_out = df.copy()

    # Distance decay (closer drivers exponentially preferred, ~0 if distance > 120km)
    dist = df_out["nearest_driver_distance_km"].clip(lower=0.0, upper=999.0)
    df_out["distance_decay_score"] = np.exp(-dist / 25.0)

    # Composite broker quality index (0.0 to 1.0)
    rating_norm = df_out["broker_rating"].clip(1.0, 5.0) / 5.0
    comp_norm = df_out["broker_completion_rate"].clip(0.0, 100.0) / 100.0
    acc_norm = df_out["broker_acceptance_rate"].clip(0.0, 100.0) / 100.0
    df_out["broker_quality_index"] = (
        0.40 * rating_norm + 0.40 * comp_norm + 0.20 * acc_norm
    )

    return df_out


def build_feature_matrix(df: pd.DataFrame) -> pd.DataFrame:
    """Transforms raw candidate records into exact numeric feature matrix for the model."""
    df_feat = compute_engineered_features(df)

    # One-hot encode canonical vehicle types with exact stable columns
    for v in CANONICAL_VEHICLE_TYPES:
        col_name = f"vehicle_{v.lower().replace(' ', '_')}"
        df_feat[col_name] = (
            df_feat["required_vehicle_type"].astype(str).str.strip().str.lower()
            == v.lower()
        ).astype(float)

    # Return only the designated model features in fixed column order
    return df_feat[MODEL_FEATURE_NAMES].fillna(0.0)


def get_feature_schema() -> Dict[str, Any]:
    """Returns metadata describing expected feature types, ranges, and canonical categories."""
    return {
        "version": "1.0.0",
        "canonical_vehicle_types": CANONICAL_VEHICLE_TYPES,
        "numeric_features": NUMERIC_FEATURES,
        "engineered_features": ENGINEERED_FEATURES,
        "model_features": MODEL_FEATURE_NAMES,
        "feature_count": len(MODEL_FEATURE_NAMES),
        "target_column": "is_successful",
    }
