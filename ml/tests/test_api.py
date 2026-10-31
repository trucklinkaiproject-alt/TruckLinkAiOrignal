"""
ml/tests/test_api.py

Integration and endpoint tests for FastAPI recommendation service using TestClient.
"""

import pytest
from fastapi.testclient import TestClient
from api.main import app

client = TestClient(app)


def test_health_endpoint():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["model_loaded"] is True
    assert "Truck" in data["canonical_vehicle_types"]
    assert "Shahzore" in data["canonical_vehicle_types"]


def test_readiness_endpoint():
    response = client.get("/ready")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ready"
    assert data["model_loaded"] is True


def test_recommend_endpoint_invalid_vehicle():
    payload = {
        "user_uid": "test_user_1",
        "pickup_lat": 31.5204,
        "pickup_lng": 74.3587,
        "required_vehicle_type": "Spaceship",
    }
    response = client.post("/recommend", json=payload)
    assert response.status_code == 422
    assert "Invalid vehicle_type" in response.text


def test_recommend_endpoint_invalid_coordinates():
    payload = {
        "user_uid": "test_user_1",
        "pickup_lat": 95.0,  # Invalid latitude > 90
        "pickup_lng": 74.3587,
        "required_vehicle_type": "Truck",
    }
    response = client.post("/recommend", json=payload)
    assert response.status_code == 422


def test_recommend_endpoint_valid_request():
    payload = {
        "user_uid": "test_user_1",
        "pickup_lat": 31.5204,
        "pickup_lng": 74.3587,
        "required_vehicle_type": "Shahzore",
        "cargo_type": "Furniture",
        "weight": 500,
        "quantity": 10,
    }
    response = client.post("/recommend", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "recommendations" in data
    assert isinstance(data["recommendations"], list)

