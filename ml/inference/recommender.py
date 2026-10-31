"""
ml/inference/recommender.py

Core inference and ranking engine for TruckLink AI Broker Recommendations.
Enforces hard business rules, builds features, and ranks candidates using
the trained scikit-learn model.
"""

import os
import json
import joblib
from typing import List, Dict, Any, Optional
import pandas as pd
import numpy as np

from training.feature_engineering import (
    CANONICAL_VEHICLE_TYPES,
    build_feature_matrix,
)
from inference.feature_builder import (
    find_nearest_driver_distance,
    build_candidate_row,
    normalize_vehicle_string,
)

BASE_DIR = os.path.dirname(os.path.dirname(__file__))
DEFAULT_MODEL_PATH = os.path.join(BASE_DIR, "models", "broker_recommender.pkl")
DEFAULT_SCHEMA_PATH = os.path.join(BASE_DIR, "models", "feature_schema.json")
DEFAULT_META_PATH = os.path.join(BASE_DIR, "models", "model_metadata.json")


class BrokerRecommender:
    def __init__(
        self,
        model_path: str = DEFAULT_MODEL_PATH,
        schema_path: str = DEFAULT_SCHEMA_PATH,
        meta_path: str = DEFAULT_META_PATH,
        max_driver_distance_km: float = 150.0,
        top_k: int = 3,
    ):
        self.model_path = model_path
        self.schema_path = schema_path
        self.meta_path = meta_path
        self.max_driver_distance_km = max_driver_distance_km
        self.top_k = top_k
        self._load_artifacts()

    def _load_artifacts(self):
        if not os.path.exists(self.model_path):
            raise FileNotFoundError(f"Trained model missing at: {self.model_path}")
        self.model = joblib.load(self.model_path)

        with open(self.schema_path, "r") as f:
            self.schema = json.load(f)

        if os.path.exists(self.meta_path):
            with open(self.meta_path, "r") as f:
                self.metadata = json.load(f)
        else:
            self.metadata = {"model_type": type(self.model).__name__, "version": "1.0.0"}

    @staticmethod
    def generate_reason_codes(candidate: Dict[str, Any]) -> List[str]:
        """Generates clear, explainable reason codes for why this broker was selected."""
        reasons = []
        dist = candidate["nearest_driver_distance_km"]
        comp = candidate["broker_completion_rate"]
        rating = candidate["broker_rating"]
        active_drivers = candidate["active_drivers_count"]
        acc = candidate["broker_acceptance_rate"]

        if dist <= 20.0:
            reasons.append("DRIVER_CLOSE_PROXIMITY")
        elif dist <= 50.0:
            reasons.append("NEARBY_ACTIVE_DRIVER")

        if comp >= 90.0:
            reasons.append("HIGH_COMPLETION_RATE")

        if rating >= 4.5:
            reasons.append("TOP_RATED_BROKER")

        if active_drivers >= 2:
            reasons.append("MULTIPLE_VEHICLES_AVAILABLE")

        if acc >= 85.0:
            reasons.append("HIGH_ACCEPTANCE_RATE")

        if not reasons:
            reasons.append("VERIFIED_VEHICLE_COMPATIBILITY")

        return reasons

    def recommend_brokers(
        self,
        pickup_lat: float,
        pickup_lng: float,
        required_vehicle_type: str,
        brokers_data: List[Dict[str, Any]],
        broker_drivers_map: Dict[str, List[Dict[str, Any]]],
        cargo_type: Optional[str] = None,
    ) -> List[Dict[str, Any]]:
        """
        Ranks eligible brokers for a shipment request.
        
        Step-by-step:
        1. Validates canonical vehicle type.
        2. Applies hard business filters (availability, vehicle match, driver distance).
        3. Extracts model features for all eligible candidates.
        4. Runs model inference.
        5. Returns up to TOP_K recommendations sorted by score.
        """
        norm_vtype = normalize_vehicle_string(required_vehicle_type)
        if norm_vtype not in CANONICAL_VEHICLE_TYPES:
            raise ValueError(
                f"Unsupported vehicle type '{required_vehicle_type}'. "
                f"Must be one of canonical categories: {CANONICAL_VEHICLE_TYPES}"
            )

        candidates = []

        for broker in brokers_data:
            broker_id = broker.get("id") or broker.get("broker_id") or ""
            if not broker_id:
                continue

            # Check broker status (must not be blocked or offline)
            b_status = str(broker.get("status", "active")).lower()
            if b_status in ("blocked", "suspended", "inactive"):
                continue

            # Check driver fleet for this broker
            drivers = broker_drivers_map.get(broker_id, [])
            if not drivers:
                continue

            # Find nearest eligible available driver with required vehicle
            nearest_dist, active_count = find_nearest_driver_distance(
                pickup_lat=pickup_lat,
                pickup_lng=pickup_lng,
                drivers=drivers,
                required_vehicle_type=norm_vtype,
            )

            # Hard constraints:
            # - Broker MUST have at least 1 active driver with required vehicle type
            # - Nearest driver MUST be within acceptable distance
            if nearest_dist is None or active_count == 0:
                continue

            if nearest_dist > self.max_driver_distance_km:
                continue

            cand_row = build_candidate_row(
                broker=broker,
                nearest_driver_dist_km=nearest_dist,
                active_drivers_count=active_count,
                required_vehicle_type=norm_vtype,
            )
            # Store full original broker metadata for presentation
            cand_row["original_broker"] = broker
            candidates.append(cand_row)

        if not candidates:
            return []

        # Feature matrix transformation
        df_candidates = pd.DataFrame(candidates)
        X = build_feature_matrix(df_candidates)

        # Predict probability of successful completion
        scores = self.model.predict_proba(X)[:, 1]

        results = []
        for idx, score in enumerate(scores):
            cand = candidates[idx]
            orig_b = cand["original_broker"]
            broker_id = cand["broker_id"]

            reason_codes = self.generate_reason_codes(cand)

            results.append({
                "broker_id": broker_id,
                "broker_name": orig_b.get("name") or orig_b.get("broker_name") or cand["broker_name"],
                "broker_phone": orig_b.get("phone") or orig_b.get("phone_number") or "",
                "broker_rating": cand["broker_rating"],
                "total_reviews": int(orig_b.get("reviews") or orig_b.get("total_reviews") or 0),
                "nearest_driver_distance_km": cand["nearest_driver_distance_km"],
                "active_drivers_count": cand["active_drivers_count"],
                "recommendation_score": round(float(score), 4),
                "required_vehicle_type": norm_vtype,
                "reason_codes": reason_codes,
                "model_version": self.metadata.get("version", "1.0.0"),
            })

        # Rank descending by recommendation score
        results.sort(key=lambda r: r["recommendation_score"], reverse=True)

        # Slice up to top_k (never fill with ineligible brokers)
        top_recommendations = results[: self.top_k]

        # Assign 1-indexed rank
        for rank, item in enumerate(top_recommendations, 1):
            item["rank"] = rank

        return top_recommendations

