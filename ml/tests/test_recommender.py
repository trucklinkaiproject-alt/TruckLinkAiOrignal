"""
ml/tests/test_recommender.py

Unit and business constraint tests for the BrokerRecommender inference engine.
"""

import pytest
from inference.recommender import BrokerRecommender


@pytest.fixture(scope="module")
def recommender():
    return BrokerRecommender()


def test_recommender_unsupported_vehicle_type(recommender):
    with pytest.raises(ValueError, match="Unsupported vehicle type"):
        recommender.recommend_brokers(
            pickup_lat=31.5204,
            pickup_lng=74.3587,
            required_vehicle_type="RocketShip100",
            brokers_data=[],
            broker_drivers_map={},
        )


def test_recommender_empty_brokers_list(recommender):
    results = recommender.recommend_brokers(
        pickup_lat=31.5204,
        pickup_lng=74.3587,
        required_vehicle_type="Truck",
        brokers_data=[],
        broker_drivers_map={},
    )
    assert results == []


def test_recommender_hard_filtering_and_ranking(recommender):
    brokers = [
        # Broker 1: Eligible, online, high rating, driver nearby (10 km)
        {
            "id": "b1",
            "name": "Alpha Freight",
            "rating": 4.8,
            "acceptance_rate": 92.0,
            "completion_rate": 95.0,
            "status": "active",
        },
        # Broker 2: Eligible, online, lower rating, driver further (40 km)
        {
            "id": "b2",
            "name": "Beta Transport",
            "rating": 4.1,
            "acceptance_rate": 80.0,
            "completion_rate": 85.0,
            "status": "active",
        },
        # Broker 3: Lacks required vehicle type (only has Van)
        {
            "id": "b3",
            "name": "Gamma Logistics",
            "rating": 4.9,
            "acceptance_rate": 99.0,
            "completion_rate": 99.0,
            "status": "active",
        },
        # Broker 4: Blocked status
        {
            "id": "b4",
            "name": "Delta Inactive",
            "rating": 5.0,
            "acceptance_rate": 100.0,
            "completion_rate": 100.0,
            "status": "blocked",
        },
    ]

    # Pickup in Lahore (31.5204, 74.3587)
    broker_drivers = {
        "b1": [
            {
                "id": "d1",
                "vehicle_type": "Truck",
                "is_available": True,
                "driver_latitude": 31.5400,
                "driver_longitude": 74.3800,  # ~3 km away
            }
        ],
        "b2": [
            {
                "id": "d2",
                "vehicle_type": "Truck",
                "is_available": True,
                "driver_latitude": 31.7500,
                "driver_longitude": 74.5500,  # ~30 km away
            }
        ],
        "b3": [
            {
                "id": "d3",
                "vehicle_type": "Van",  # Incompatible vehicle
                "is_available": True,
                "driver_latitude": 31.5200,
                "driver_longitude": 74.3500,
            }
        ],
        "b4": [
            {
                "id": "d4",
                "vehicle_type": "Truck",
                "is_available": True,
                "driver_latitude": 31.5200,
                "driver_longitude": 74.3500,
            }
        ],
    }

    results = recommender.recommend_brokers(
        pickup_lat=31.5204,
        pickup_lng=74.3587,
        required_vehicle_type="Truck",
        brokers_data=brokers,
        broker_drivers_map=broker_drivers,
    )

    # b3 (incompatible) and b4 (blocked) MUST NOT be in results
    rec_ids = [r["broker_id"] for r in results]
    assert "b3" not in rec_ids
    assert "b4" not in rec_ids
    assert "b1" in rec_ids
    assert "b2" in rec_ids

    # b1 has much closer driver and higher performance, so should be rank 1
    assert results[0]["broker_id"] == "b1"
    assert results[0]["rank"] == 1
    assert results[1]["broker_id"] == "b2"
    assert results[1]["rank"] == 2
    assert len(results) == 2  # Exactly 2 eligible, never padded with fake items!


def test_recommender_fewer_than_three_eligible(recommender):
    brokers = [
        {"id": "b1", "name": "Solo Broker", "rating": 4.5, "status": "active"},
    ]
    broker_drivers = {
        "b1": [
            {
                "id": "d1",
                "vehicle_type": "Shahzore",
                "is_available": True,
                "driver_latitude": 33.6844,
                "driver_longitude": 73.0479,
            }
        ]
    }

    results = recommender.recommend_brokers(
        pickup_lat=33.6844,
        pickup_lng=73.0479,
        required_vehicle_type="Shahzore",
        brokers_data=brokers,
        broker_drivers_map=broker_drivers,
    )

    assert len(results) == 1
    assert results[0]["broker_id"] == "b1"
    assert results[0]["rank"] == 1

