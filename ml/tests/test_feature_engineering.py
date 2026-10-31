"""
ml/tests/test_feature_engineering.py

Unit tests for feature engineering, Haversine formula, and coordinate validation.
"""

import math
import pytest
import pandas as pd
from training.feature_engineering import (
    CANONICAL_VEHICLE_TYPES,
    MODEL_FEATURE_NAMES,
    build_feature_matrix,
)
from inference.feature_builder import (
    haversine_km,
    normalize_vehicle_string,
    find_nearest_driver_distance,
)


def test_haversine_known_distances():
    # Islamabad to Rawalpindi (~15 km)
    d = haversine_km(33.6844, 73.0479, 33.5651, 73.0169)
    assert 12.0 <= d <= 18.0

    # Same location -> 0 km
    d_same = haversine_km(31.5204, 74.3587, 31.5204, 74.3587)
    assert math.isclose(d_same, 0.0, abs_tol=1e-4)


def test_haversine_invalid_coordinates():
    with pytest.raises(ValueError):
        haversine_km(95.0, 70.0, 30.0, 70.0)  # Latitude > 90

    with pytest.raises(ValueError):
        haversine_km(30.0, -195.0, 30.0, 70.0)  # Longitude < -180


def test_vehicle_string_normalization():
    assert normalize_vehicle_string("trailer") == "Trailer"
    assert normalize_vehicle_string("PICKUP TRUCK") == "PickUp Truck"
    assert normalize_vehicle_string("pickup-truck") == "PickUp Truck"
    assert normalize_vehicle_string("shahzore") == "Shahzore"
    assert normalize_vehicle_string("loader_rickshaw") == "Loader Rickshaw"
    assert normalize_vehicle_string("Truck") == "Truck"
    assert normalize_vehicle_string("InvalidType") == "InvalidType"


def test_nearest_driver_distance_filtering():
    drivers = [
        # Driver 1: Available, matching vehicle, in Islamabad
        {
            "id": "d1",
            "vehicle_type": "Trailer",
            "is_available": True,
            "driver_latitude": 33.6844,
            "driver_longitude": 73.0479,
        },
        # Driver 2: Mismatched vehicle
        {
            "id": "d2",
            "vehicle_type": "Van",
            "is_available": True,
            "driver_latitude": 33.6800,
            "driver_longitude": 73.0400,
        },
        # Driver 3: Matching vehicle, but unavailable
        {
            "id": "d3",
            "vehicle_type": "Trailer",
            "is_available": False,
            "driver_latitude": 33.6820,
            "driver_longitude": 73.0420,
        },
    ]

    # Pickup in Islamabad
    dist, count = find_nearest_driver_distance(
        pickup_lat=33.6844,
        pickup_lng=73.0479,
        drivers=drivers,
        required_vehicle_type="Trailer",
    )

    assert count == 1
    assert dist is not None
    assert math.isclose(dist, 0.0, abs_tol=0.1)

    # If required vehicle is Van, count=1, distance is small
    van_dist, van_count = find_nearest_driver_distance(
        pickup_lat=33.6844,
        pickup_lng=73.0479,
        drivers=drivers,
        required_vehicle_type="Van",
    )
    assert van_count == 1
    assert van_dist is not None

    # If required vehicle is Container, count=0, distance=None
    cont_dist, cont_count = find_nearest_driver_distance(
        pickup_lat=33.6844,
        pickup_lng=73.0479,
        drivers=drivers,
        required_vehicle_type="Container",
    )
    assert cont_count == 0
    assert cont_dist is None

