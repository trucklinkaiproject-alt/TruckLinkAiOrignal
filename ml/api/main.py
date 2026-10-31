"""
ml/api/main.py

FastAPI Application for TruckLink AI Broker Recommendations.
Runs 100% locally with free, open-source Python packages (FastAPI, Uvicorn, scikit-learn).
"""

import os
import sys
import logging
from contextlib import asynccontextmanager
from typing import Dict, Any, List
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

# Ensure ml root directory is on PYTHONPATH
ML_ROOT = os.path.dirname(os.path.dirname(__file__))
if ML_ROOT not in sys.path:
    sys.path.insert(0, ML_ROOT)

load_dotenv()

from training.feature_engineering import CANONICAL_VEHICLE_TYPES
from inference.recommender import BrokerRecommender
from api.schemas import (
    RecommendationRequest,
    RecommendationResponse,
    HealthResponse,
    BrokerRecommendationItem,
)
from api.auth import verify_firebase_token
from api.firestore_repository import FirestoreRepository

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
logger = logging.getLogger("trucklink.api")

# Initialize singletons
recommender: BrokerRecommender = None
repository: FirestoreRepository = None


def init_services():
    global recommender, repository
    if recommender is None:
        logger.info("Initializing TruckLink AI Broker Recommendation Service...")
        model_path = os.getenv("MODEL_ARTIFACT_PATH", os.path.join(ML_ROOT, "models", "broker_recommender.pkl"))
        schema_path = os.getenv("FEATURE_SCHEMA_PATH", os.path.join(ML_ROOT, "models", "feature_schema.json"))
        meta_path = os.getenv("MODEL_METADATA_PATH", os.path.join(ML_ROOT, "models", "model_metadata.json"))

        max_dist = float(os.getenv("MAX_ACCEPTABLE_DRIVER_DISTANCE_KM", "150.0"))
        top_k = int(os.getenv("TOP_K_RECOMMENDATIONS", "3"))

        recommender = BrokerRecommender(
            model_path=model_path,
            schema_path=schema_path,
            meta_path=meta_path,
            max_driver_distance_km=max_dist,
            top_k=top_k,
        )
        logger.info(f"Loaded ML model '{recommender.metadata.get('model_type')}' (v{recommender.metadata.get('version', '1.0.0')})")

    if repository is None:
        repository = FirestoreRepository()
        logger.info(f"Firestore Repository initialized. Connected: {repository.is_connected}")


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_services()
    yield


app = FastAPI(
    title="TruckLink AI - Broker Recommendation Engine",
    description="FOSS AI Broker Recommendation Microservice for TruckLink AI",
    version="1.0.0",
    lifespan=lifespan,
)

# Enable CORS for Flutter mobile, web, and emulator clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Auto-initialize on import so TestClient works seamlessly
init_services()


@app.get("/health", response_model=HealthResponse)
def health_check():
    """Returns service health, model version, and Firestore connectivity."""
    return HealthResponse(
        status="healthy",
        model_loaded=recommender is not None and recommender.model is not None,
        model_version=recommender.metadata.get("version", "1.0.0") if recommender else "unknown",
        firestore_connected=repository.is_connected if repository else False,
        canonical_vehicle_types=CANONICAL_VEHICLE_TYPES,
    )


@app.get("/ready")
def readiness_check():
    """
    Readiness probe for cloud orchestrators (Render, Kubernetes).
    Returns 200 OK only if the ML model is fully loaded and ready for inference.
    """
    if recommender is None or recommender.model is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Model is not ready or failed to load.",
        )
    return {
        "status": "ready",
        "model_loaded": True,
        "model_version": recommender.metadata.get("version", "1.0.0"),
        "firestore_connected": repository.is_connected if repository else False,
    }


@app.post("/recommend", response_model=RecommendationResponse)
def recommend_brokers(
    req: RecommendationRequest,
    authenticated_uid: str = Depends(verify_firebase_token),
):
    """
    Ranks eligible brokers for an incoming shipment request.
    Strictly verifies canonical vehicle types, nearest active driver distances,
    and returns top-K suitable brokers.
    """
    logger.info(
        f"Recommendation request from user={authenticated_uid}: "
        f"pickup=({req.pickup_lat}, {req.pickup_lng}), vehicle={req.required_vehicle_type}"
    )

    if recommender is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Recommendation model is not initialized.",
        )

    # 1. Fetch active brokers from Firestore
    brokers = repository.fetch_active_brokers()

    # If live Firestore is empty or running offline in local development,
    # log notice and handle gracefully
    if not brokers:
        logger.warning("No active brokers found in Firestore repository.")
        return RecommendationResponse(
            success=True,
            count=0,
            total_eligible_brokers=0,
            recommendations=[],
            model_version=recommender.metadata.get("version", "1.0.0"),
            message="No online brokers found matching vehicle and driver requirements.",
        )

    # 2. Fetch driver fleet for candidate brokers
    broker_drivers_map: Dict[str, List[Dict[str, Any]]] = {}
    for b in brokers:
        b_id = b.get("id") or b.get("broker_id") or ""
        if b_id:
            broker_drivers_map[b_id] = repository.fetch_broker_drivers(b_id)

    # 3. Execute inference and ranking
    try:
        ranked = recommender.recommend_brokers(
            pickup_lat=req.pickup_lat,
            pickup_lng=req.pickup_lng,
            required_vehicle_type=req.required_vehicle_type,
            brokers_data=brokers,
            broker_drivers_map=broker_drivers_map,
            cargo_type=req.cargo_type,
        )
    except ValueError as ve:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(ve))
    except Exception as e:
        logger.error(f"Inference error: {e}", exc_info=True)
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))

    items = [BrokerRecommendationItem(**r) for r in ranked]

    message = None
    if not items:
        message = f"No eligible brokers currently have an active {req.required_vehicle_type} driver in close proximity."

    return RecommendationResponse(
        success=True,
        count=len(items),
        total_eligible_brokers=len(items),
        recommendations=items,
        model_version=recommender.metadata.get("version", "1.0.0"),
        message=message,
    )


if __name__ == "__main__":
    import uvicorn
    # Render and Heroku bind to dynamic $PORT
    port = int(os.getenv("PORT", "8000"))
    logger.info(f"Starting TruckLink AI API server on 0.0.0.0:{port}...")
    app_target = "ml.api.main:app" if os.path.exists("ml") else "api.main:app"
    uvicorn.run(app_target, host="0.0.0.0", port=port, reload=False)
