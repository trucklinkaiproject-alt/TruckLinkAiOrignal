"""
ml/training/generate_historical_dataset.py

Generates reproducible historical training datasets for the TruckLink AI Broker
Recommendation System, strictly adhering to the discovered canonical categories.

Schema:
- brokers.csv: Historical broker performance statistics
- drivers.csv: Historical driver fleet records linked to brokers
- requests.csv: Historical transportation shipment requests
- history.csv: Historical broker-request evaluation pairs with outcome labels
"""

import os
import random
import numpy as np
import pandas as pd
from datetime import datetime, timedelta

# Fix seed for strict reproducibility
SEED = 42
random.seed(SEED)
np.random.seed(SEED)

# Canonical Categories Discovered from Flutter Source Code
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

# Major Logistics Hubs (Lat, Lng) in Pakistan
LOGISTICS_HUBS = {
    "Karachi": (24.8607, 67.0011),
    "Lahore": (31.5204, 74.3587),
    "Islamabad": (33.6844, 73.0479),
    "Rawalpindi": (33.5651, 73.0169),
    "Faisalabad": (31.4504, 73.1350),
    "Multan": (30.1575, 71.5249),
    "Peshawar": (34.0151, 71.5249),
    "Gujranwala": (32.1877, 74.1945),
}

DATA_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "data")


def haversine_np(lat1, lon1, lat2, lon2):
    """Vectorized Haversine distance in kilometers."""
    R = 6371.0
    dlat = np.radians(lat2 - lat1)
    dlon = np.radians(lon2 - lon1)
    a = (
        np.sin(dlat / 2.0) ** 2
        + np.cos(np.radians(lat1))
        * np.cos(np.radians(lat2))
        * np.sin(dlon / 2.0) ** 2
    )
    c = 2 * np.arcsin(np.sqrt(np.clip(a, 0, 1)))
    return R * c


def generate_datasets(num_brokers=50, num_drivers=250, num_requests=1000):
    os.makedirs(DATA_DIR, exist_ok=True)

    # ---------------------------------------------------------
    # 1. Brokers Dataset
    # ---------------------------------------------------------
    broker_ids = [f"broker_{i:03d}" for i in range(1, num_brokers + 1)]
    broker_names = [f"Logistics Broker {i}" for i in range(1, num_brokers + 1)]

    broker_records = []
    for b_id, b_name in zip(broker_ids, broker_names):
        rating = round(float(np.random.normal(4.2, 0.5)), 2)
        rating = float(np.clip(rating, 2.5, 5.0))

        total_requests = int(np.random.randint(15, 200))
        acceptance_rate = round(float(np.random.uniform(50.0, 95.0)), 1)
        accepted = int(round(total_requests * (acceptance_rate / 100.0)))

        completion_rate = round(float(np.random.uniform(65.0, 98.0)), 1)
        completed = int(round(accepted * (completion_rate / 100.0)))

        cancellation_rate = round(100.0 - completion_rate, 1)
        cancelled = accepted - completed

        # Broker primary hub location
        hub_city = random.choice(list(LOGISTICS_HUBS.keys()))
        hub_lat, hub_lng = LOGISTICS_HUBS[hub_city]
        lat = hub_lat + float(np.random.normal(0, 0.08))
        lng = hub_lng + float(np.random.normal(0, 0.08))

        broker_records.append({
            "broker_id": b_id,
            "broker_name": b_name,
            "city": hub_city,
            "rating": rating,
            "total_requests": total_requests,
            "accepted_requests": accepted,
            "completed_requests": completed,
            "cancelled_requests": cancelled,
            "acceptance_rate": acceptance_rate,
            "completion_rate": completionRate if 'completionRate' in locals() else completion_rate,
            "cancellation_rate": cancellation_rate,
            "latitude": round(lat, 5),
            "longitude": round(lng, 5),
            "is_verified": True,
            "status": "active",
        })

    df_brokers = pd.DataFrame(broker_records)
    brokers_path = os.path.join(DATA_DIR, "brokers.csv")
    df_brokers.to_csv(brokers_path, index=False)
    print(f"[Dataset] Generated {len(df_brokers)} brokers -> {brokers_path}")

    # ---------------------------------------------------------
    # 2. Drivers Dataset
    # ---------------------------------------------------------
    driver_records = []
    for d_idx in range(1, num_drivers + 1):
        d_id = f"driver_{d_idx:04d}"
        d_name = f"Driver {d_idx}"
        assigned_broker = random.choice(broker_ids)
        broker_row = df_brokers[df_brokers["broker_id"] == assigned_broker].iloc[0]

        v_type = random.choice(CANONICAL_VEHICLE_TYPES)
        # Driver location clustered around broker hub with random dispersion
        d_lat = broker_row["latitude"] + float(np.random.normal(0, 0.15))
        d_lng = broker_row["longitude"] + float(np.random.normal(0, 0.15))

        is_available = random.random() < 0.85
        d_rating = round(float(np.clip(np.random.normal(4.3, 0.4), 3.0, 5.0)), 2)
        total_trips = int(np.random.randint(5, 120))

        driver_records.append({
            "driver_id": d_id,
            "driver_name": d_name,
            "broker_id": assigned_broker,
            "vehicle_type": v_type,
            "vehicle_number": f"TL-{random.randint(100, 999)}-{random.choice(['A','B','C','K','L'])}",
            "is_available": is_available,
            "availability_status": "online" if is_available else "offline",
            "driver_latitude": round(d_lat, 5),
            "driver_longitude": round(d_lng, 5),
            "driver_rating": d_rating,
            "total_trips": total_trips,
            "status": "active" if is_available else "on-trip",
        })

    df_drivers = pd.DataFrame(driver_records)
    drivers_path = os.path.join(DATA_DIR, "drivers.csv")
    df_drivers.to_csv(drivers_path, index=False)
    print(f"[Dataset] Generated {len(df_drivers)} drivers -> {drivers_path}")

    # ---------------------------------------------------------
    # 3. Requests Dataset
    # ---------------------------------------------------------
    start_time = datetime(2026, 1, 1, 8, 0, 0)
    request_records = []

    for r_idx in range(1, num_requests + 1):
        r_id = f"req_{r_idx:05d}"
        req_time = start_time + timedelta(minutes=int(r_idx * 15 + np.random.randint(0, 10)))

        pickup_city = random.choice(list(LOGISTICS_HUBS.keys()))
        drop_city = random.choice([c for c in LOGISTICS_HUBS.keys() if c != pickup_city])

        p_lat, p_lng = LOGISTICS_HUBS[pickup_city]
        d_lat, d_lng = LOGISTICS_HUBS[drop_city]

        p_lat += float(np.random.normal(0, 0.05))
        p_lng += float(np.random.normal(0, 0.05))
        d_lat += float(np.random.normal(0, 0.05))
        d_lng += float(np.random.normal(0, 0.05))

        v_type = random.choice(CANONICAL_VEHICLE_TYPES)
        c_type = random.choice(CANONICAL_CARGO_TYPES)
        weight = int(np.random.randint(50, 5000))
        quantity = int(np.random.randint(1, 50))

        request_records.append({
            "request_id": r_id,
            "created_at": req_time.strftime("%Y-%m-%d %H:%M:%S"),
            "pickup_city": pickup_city,
            "drop_city": drop_city,
            "pickup_latitude": round(p_lat, 5),
            "pickup_longitude": round(p_lng, 5),
            "drop_latitude": round(d_lat, 5),
            "drop_longitude": round(d_lng, 5),
            "vehicle_type": v_type,
            "cargo_type": c_type,
            "weight": weight,
            "quantity": quantity,
        })

    df_requests = pd.DataFrame(request_records)
    requests_path = os.path.join(DATA_DIR, "requests.csv")
    df_requests.to_csv(requests_path, index=False)
    print(f"[Dataset] Generated {len(df_requests)} requests -> {requests_path}")

    # ---------------------------------------------------------
    # 4. History (Evaluation Candidates & Target Labels)
    # ---------------------------------------------------------
    history_records = []

    for _, req in df_requests.iterrows():
        r_id = req["request_id"]
        req_vtype = req["vehicle_type"]
        p_lat = req["pickup_latitude"]
        p_lng = req["pickup_longitude"]

        # Select 3-6 candidate brokers for this request
        candidate_brokers = random.sample(broker_ids, k=random.randint(3, 6))

        for b_id in candidate_brokers:
            b_row = df_brokers[df_brokers["broker_id"] == b_id].iloc[0]

            # Find drivers of this broker matching the required vehicle type
            b_drivers = df_drivers[
                (df_drivers["broker_id"] == b_id) &
                (df_drivers["vehicle_type"] == req_vtype)
            ]

            has_matching_vehicle = len(b_drivers) > 0
            available_matching_drivers = b_drivers[b_drivers["is_available"] == True]

            if len(available_matching_drivers) > 0:
                # Calculate Haversine distance to nearest available eligible driver
                d_distances = haversine_np(
                    p_lat,
                    p_lng,
                    available_matching_drivers["driver_latitude"].values,
                    available_matching_drivers["driver_longitude"].values
                )
                nearest_driver_dist = float(np.min(d_distances))
                active_drivers_count = len(available_matching_drivers)
            elif has_matching_vehicle:
                # Drivers exist but all offline/on-trip
                d_distances = haversine_np(
                    p_lat,
                    p_lng,
                    b_drivers["driver_latitude"].values,
                    b_drivers["driver_longitude"].values
                )
                nearest_driver_dist = float(np.min(d_distances)) + 50.0
                active_drivers_count = 0
            else:
                # No drivers with required vehicle type in network
                nearest_driver_dist = 999.0
                active_drivers_count = 0

            # Ground truth label assignment based on real operational rules:
            # Must have vehicle capacity, reasonable distance (< 80km), and decent performance
            is_successful = 0
            if has_matching_vehicle and active_drivers_count > 0:
                dist_score = max(0.0, 1.0 - (nearest_driver_dist / 75.0))
                perf_score = (
                    (b_row["rating"] / 5.0) * 0.35 +
                    (b_row["completion_rate"] / 100.0) * 0.35 +
                    (b_row["acceptance_rate"] / 100.0) * 0.30
                )
                combined_prob = 0.55 * dist_score + 0.45 * perf_score

                # Probabilistic outcome based on real operational quality
                if nearest_driver_dist <= 60.0 and combined_prob >= 0.45:
                    is_successful = 1 if random.random() < combined_prob else 0

            history_records.append({
                "request_id": r_id,
                "broker_id": b_id,
                "required_vehicle_type": req_vtype,
                "cargo_type": req["cargo_type"],
                "pickup_latitude": p_lat,
                "pickup_longitude": p_lng,
                "nearest_driver_distance_km": round(nearest_driver_dist, 2),
                "active_drivers_count": active_drivers_count,
                "broker_rating": b_row["rating"],
                "broker_acceptance_rate": b_row["acceptance_rate"],
                "broker_completion_rate": b_row["completion_rate"],
                "broker_cancellation_rate": b_row["cancellation_rate"],
                "total_requests": b_row["total_requests"],
                "is_successful": is_successful,
            })

    df_history = pd.DataFrame(history_records)
    history_path = os.path.join(DATA_DIR, "history.csv")
    df_history.to_csv(history_path, index=False)
    print(f"[Dataset] Generated {len(df_history)} history evaluation records -> {history_path}")
    print(f"[Dataset] Overall Success Rate: {df_history['is_successful'].mean() * 100:.1f}%")


if __name__ == "__main__":
    generate_datasets()

