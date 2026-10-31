"""
ml/api/schemas.py

Pydantic schemas for the TruckLink AI Recommendation API.
Enforces strict input validation on coordinates, canonical vehicle types, and formats.
"""

from typing import List, Optional
from pydantic import BaseModel, Field, field_validator
from training.feature_engineering import CANONICAL_VEHICLE_TYPES, CANONICAL_CARGO_TYPES
from inference.feature_builder import normalize_vehicle_string


class RecommendationRequest(BaseModel):
    user_uid: str = Field(..., description="Firebase UID of the requesting shipper/user")
    pickup_lat: float = Field(..., ge=-90.0, le=90.0, description="Pickup latitude in degrees")
    pickup_lng: float = Field(..., ge=-180.0, le=180.0, description="Pickup longitude in degrees")
    required_vehicle_type: str = Field(..., description="Canonical vehicle type required for transportation")
    drop_lat: Optional[float] = Field(None, ge=-90.0, le=90.0, description="Optional dropoff latitude")
    drop_lng: Optional[float] = Field(None, ge=-180.0, le=180.0, description="Optional dropoff longitude")
    cargo_type: Optional[str] = Field(None, description="Optional canonical cargo type")
    weight: Optional[float] = Field(None, ge=0.0, description="Cargo weight in kg")
    quantity: Optional[int] = Field(None, ge=0, description="Cargo units")
    request_id: Optional[str] = Field(None, description="Optional draft order/request identifier")

    @field_validator("required_vehicle_type")
    @classmethod
    def validate_vehicle_type(cls, val: str) -> str:
        norm = normalize_vehicle_string(val)
        if norm not in CANONICAL_VEHICLE_TYPES:
            raise ValueError(
                f"Invalid vehicle_type '{val}'. Must be one of canonical types: {CANONICAL_VEHICLE_TYPES}"
            )
        return norm

    @field_validator("cargo_type")
    @classmethod
    def validate_cargo_type(cls, val: Optional[str]) -> Optional[str]:
        if val is None or not val.strip():
            return None
        clean = val.strip().title()
        if clean not in CANONICAL_CARGO_TYPES and clean != "Other":
            # Allow case variations or fallback to Other
            return "Other"
        return clean


class BrokerRecommendationItem(BaseModel):
    rank: int = Field(..., ge=1, le=3, description="1-indexed recommendation position")
    broker_id: str
    broker_name: str
    broker_phone: Optional[str] = ""
    broker_rating: float = Field(..., ge=0.0, le=5.0)
    total_reviews: int = Field(default=0)
    nearest_driver_distance_km: float = Field(..., description="Distance in km to nearest available eligible driver")
    active_drivers_count: int = Field(..., description="Count of eligible online drivers in broker fleet")
    recommendation_score: float = Field(..., ge=0.0, le=1.0, description="AI predicted success/suitability score")
    required_vehicle_type: str
    reason_codes: List[str] = Field(default_factory=list, description="Machine explainable reason codes")
    model_version: str


class RecommendationResponse(BaseModel):
    success: bool
    count: int
    total_eligible_brokers: int
    recommendations: List[BrokerRecommendationItem]
    model_version: str
    message: Optional[str] = None


class HealthResponse(BaseModel):
    status: str
    model_loaded: bool
    model_version: str
    firestore_connected: bool
    canonical_vehicle_types: List[str]

