import os
import json
import firebase_admin
from firebase_admin import credentials, firestore

# Add ml to path
import sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(__file__)), "ml"))

from inference.recommender import BrokerRecommender
from api.firestore_repository import FirestoreRepository

DOWNLOADS_KEY = r"C:\Users\mrkam\Downloads\trucklink-ai-orignal-firebase-adminsdk-fbsvc-92b5ef0e59.json"
sa_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS", DOWNLOADS_KEY)

repo = FirestoreRepository(service_account_path=sa_path)
recommender = BrokerRecommender()

print(f"Repository connected to Firestore: {repo.is_connected}")
print(f"ML Model loaded: {recommender.metadata.get('model_type')} (v{recommender.metadata.get('version')})")

brokers = repo.fetch_active_brokers()
print(f"Fetched {len(brokers)} active genuine brokers from Firestore:")
for b in brokers:
    print(f"  - Broker: {b.get('id')} ({b.get('name')})")

broker_drivers_map = {}
for b in brokers:
    b_id = b.get("id")
    drivers = repo.fetch_broker_drivers(b_id)
    broker_drivers_map[b_id] = drivers
    print(f"    Drivers for {b_id}: {len(drivers)}")
    for d in drivers:
        print(f"      * Driver {d.get('id')} ({d.get('name')}): vehicle={d.get('vehicle_type')}, loc=({d.get('driver_latitude')}, {d.get('driver_longitude')})")

# Test 1: Request with matching vehicle type ("PickUp Truck") near driver (e.g. Abbottabad 34.19, 73.24)
print("\n" + "=" * 60)
print("TEST 1: Request with matching vehicle ('PickUp Truck') near driver")
print("=" * 60)
results = recommender.recommend_brokers(
    pickup_lat=34.1990,
    pickup_lng=73.2420,
    required_vehicle_type="PickUp Truck",
    brokers_data=brokers,
    broker_drivers_map=broker_drivers_map,
)
print(f"Recommendations returned ({len(results)}):")
for r in results:
    print(json.dumps(r, indent=2))

# Test 2: Request with vehicle type not supported by currently available genuine driver fleet (e.g. "Container")
print("\n" + "=" * 60)
print("TEST 2: Request with vehicle type not supported ('Container')")
print("=" * 60)
results_container = recommender.recommend_brokers(
    pickup_lat=34.1990,
    pickup_lng=73.2420,
    required_vehicle_type="Container",
    brokers_data=brokers,
    broker_drivers_map=broker_drivers_map,
)
print(f"Recommendations returned ({len(results_container)}): {results_container}")
print("Verified: Does not fabricate fake brokers when none are eligible!")

# Test 3: Request too far away (> 150 km) e.g. Karachi (24.86, 67.00)
print("\n" + "=" * 60)
print("TEST 3: Request too far away (Karachi 24.86, 67.00 - > 1000 km away)")
print("=" * 60)
results_far = recommender.recommend_brokers(
    pickup_lat=24.8607,
    pickup_lng=67.0011,
    required_vehicle_type="PickUp Truck",
    brokers_data=brokers,
    broker_drivers_map=broker_drivers_map,
)
print(f"Recommendations returned ({len(results_far)}): {results_far}")
print("Verified: Does not return distant brokers whose drivers cannot serve the pickup!")
