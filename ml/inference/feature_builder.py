"""
ml/inference/feature_builder.py

Prepares live candidate feature vectors from real Firestore Broker and Driver documents
for the trained TruckLink AI Broker Recommender model.
"""

import math
from typing import Dict, Any, List, Optional, Tuple
import numpy as np
import pandas as pd

from training.feature_engineering import (
    CANONICAL_VEHICLE_TYPES,
    MODEL_FEATURE_NAMES,
    build_feature_matrix,
)


def haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Computes great-circle distance between two points in kilometers.
    Validates coordinate ranges strictly: lat in [-90, 90], lon in [-180, 180].
    """
    if not (-90.0 <= lat1 <= 90.0 and -180.0 <= lon1 <= 180.0):
        raise ValueError(f"Invalid coordinate point 1: ({lat1}, {lon1})")
    if not (-90.0 <= lat2 <= 90.0 and -180.0 <= lon2 <= 180.0):
        raise ValueError(f"Invalid coordinate point 2: ({lat2}, {lon2})")

    R = 6371.0
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)

    a = (
        math.sin(delta_phi / 2.0) ** 2
        + math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2.0) ** 2
    )
    c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))
    return R * c


def normalize_vehicle_string(v_type: Optional[str]) -> str:
    """Normalizes vehicle string for matching against canonical types."""
    if not v_type:
        return ""
    clean = (
        v_type.strip()
        .lower()
        .replace(" ", "")
        .replace("_", "")
        .replace("-", "")
    )
    # 1. Exact match check against all canonical types
    for canonical in CANONICAL_VEHICLE_TYPES:
        can_clean = (
            canonical.strip()
            .lower()
            .replace(" ", "")
            .replace("_", "")
            .replace("-", "")
        )
        if clean == can_clean:
            return canonical

    # 2. Check compound / partial matches, sorting longest canonical name first
    # This prevents "PickUp Truck" or "Trailer Truck" from prematurely matching "Truck"
    sorted_canonicals = sorted(CANONICAL_VEHICLE_TYPES, key=lambda c: len(c), reverse=True)
    for canonical in sorted_canonicals:
        can_clean = (
            canonical.strip()
            .lower()
            .replace(" ", "")
            .replace("_", "")
            .replace("-", "")
        )
        if clean == can_clean:
            return canonical
        if can_clean in clean:
            if clean.startswith(can_clean) or clean.endswith(can_clean):
                return canonical

    return v_type.strip()


def find_nearest_driver_distance(
    pickup_lat: float,
    pickup_lng: float,
    drivers: List[Dict[str, Any]],
    required_vehicle_type: str,
) -> Tuple[Optional[float], int]:
    """
    Finds distance in km to the nearest eligible, available driver for a broker.
    CRITICAL: Never uses broker office coordinates! Only actual driver coordinates.
    Returns: (nearest_distance_km, active_matching_drivers_count)
    """
    min_dist = float("inf")
    active_count = 0
    norm_required = normalize_vehicle_string(required_vehicle_type)

    for driver in drivers:
        # 1. Vehicle compatibility check
        raw_vtype = driver.get("vehicle_type") or driver.get("vehicleType") or ""
        norm_driver_v = normalize_vehicle_string(raw_vtype)
        if norm_driver_v != norm_required:
            continue

        # 2. Availability check
        is_avail = (
            driver.get("is_available") is True
            or str(driver.get("availability_status", "")).lower() == "online"
            or str(driver.get("status", "")).lower() == "active"
        )
        if not is_avail:
            continue

        # 3. Location validity check
        d_lat = driver.get("driver_latitude") or driver.get("driverLatitude") or driver.get("latitude")
        d_lng = driver.get("driver_longitude") or driver.get("driverLongitude") or driver.get("longitude")

        if d_lat is None or d_lng is None:
            continue
        try:
            d_lat = float(d_lat)
            d_lng = float(d_lng)
        except (ValueError, TypeError):
            continue

        # Reject placeholder 0.0, 0.0 coordinates
        if abs(d_lat) < 0.001 and abs(d_lng) < 0.001:
            continue

        try:
            dist = haversine_km(pickup_lat, pickup_lng, d_lat, d_lng)
            active_count += 1
            if dist < min_dist:
                min_dist = dist
        except ValueError:
            continue

    if min_dist == float("inf"):
        return None, 0

    return round(min_dist, 2), active_count


def build_candidate_row(
    broker: Dict[str, Any],
    nearest_driver_dist_km: float,
    active_drivers_count: int,
    required_vehicle_type: str,
) -> Dict[str, Any]:
    """Builds a single candidate dictionary ready for feature transformation with safe bounds."""
    rating = float(np.clip(float(broker.get("rating") or broker.get("overall_rating") or 4.5), 1.0, 5.0))
    acceptance_rate = float(np.clip(float(broker.get("acceptance_rate") or 85.0), 0.0, 100.0))
    completion_rate = float(np.clip(float(broker.get("completion_rate") or 90.0), 0.0, 100.0))
    cancellation_rate = float(np.clip(float(broker.get("cancellation_rate") or 10.0), 0.0, 100.0))
    total_requests = max(0, int(broker.get("total_requests") or 25))

    return {
        "broker_id": broker.get("id") or broker.get("broker_id") or "",
        "broker_name": broker.get("name") or broker.get("broker_name") or "Broker",
        "required_vehicle_type": normalize_vehicle_string(required_vehicle_type),
        "nearest_driver_distance_km": nearest_driver_dist_km,
        "active_drivers_count": active_drivers_count,
        "broker_rating": rating,
        "broker_acceptance_rate": acceptance_rate,
        "broker_completion_rate": completion_rate,
        "broker_cancellation_rate": cancellation_rate,
        "total_requests": total_requests,
    }
