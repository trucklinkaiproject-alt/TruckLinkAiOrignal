import os
import json
from datetime import datetime, timezone
import firebase_admin
from firebase_admin import credentials, firestore

DOWNLOADS_KEY = r"C:\Users\mrkam\Downloads\trucklink-ai-orignal-firebase-adminsdk-fbsvc-92b5ef0e59.json"
sa_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS", DOWNLOADS_KEY)

cred = credentials.Certificate(sa_path)
if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)

db = firestore.client()

backup_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "backups")
os.makedirs(backup_dir, exist_ok=True)
timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
backup_file = os.path.join(backup_dir, f"firestore_dummy_backup_{timestamp}.json")

backup_data = {
    "metadata": {
        "created_at_utc": datetime.now(timezone.utc).isoformat(),
        "project_id": cred.project_id,
        "purpose": "Pre-deletion backup of dummy/seeded records in TruckLink AI Firestore",
    },
    "brokers": {},
    "drivers": {},
    "users": {},
}

# 1. Target Dummy Brokers
DUMMY_BROKER_IDS = [
    "broker_al_madina",
    "broker_chenab_logistics",
    "broker_faisal_movers",
    "broker_indus_cargo",
    "broker_khyber_express",
    "broker_mehran_freight",
    "broker_pak_swift",
    "broker_tariq_freight",
]

print("Backing up dummy brokers...")
for b_id in DUMMY_BROKER_IDS:
    doc_ref = db.collection("Broker").document(b_id)
    doc = doc_ref.get()
    if doc.exists:
        broker_entry = {
            "data": doc.to_dict(),
            "subcollections": {},
        }
        for subcol in doc_ref.collections():
            broker_entry["subcollections"][subcol.id] = {}
            for s_doc in subcol.stream():
                broker_entry["subcollections"][subcol.id][s_doc.id] = s_doc.to_dict()
        backup_data["brokers"][b_id] = broker_entry
        print(f"  Backed up broker: {b_id} (Subcollections: {list(broker_entry['subcollections'].keys())})")

# 2. Target Dummy Drivers
DUMMY_DRIVER_IDS = [
    "drv_abdul_rehman", "drv_akhtar_rasool", "drv_arshad_nadeem", "drv_asif_mahmood",
    "drv_bilal_shah", "drv_farhan_memon", "drv_gul_khan", "drv_habib_ullah",
    "drv_imran_ali", "drv_kamran_bhatti", "drv_kashif_khan", "drv_mazhar_iqbal",
    "drv_nadir_khan", "drv_nawaz_baloch", "drv_qasim_sheikh", "drv_rashid_minhas",
    "drv_sajjad_haider", "drv_shahid_latif", "drv_sher_afghan", "drv_tanveer_hussain",
    "drv_tariq_mehmood", "drv_usman_warraich", "drv_zahid_paracha",
]

print("\nBacking up dummy drivers...")
for d_id in DUMMY_DRIVER_IDS:
    doc = db.collection("Driver").document(d_id).get()
    if doc.exists:
        backup_data["drivers"][d_id] = doc.to_dict()
        print(f"  Backed up driver: {d_id}")

# 3. Target Dummy Users
DUMMY_USER_IDS = [
    "user_hamza_javed", "user_kamran_ahmed", "user_sana_sheikh",
    "user_usman_farooq", "user_zainab_malik",
]

print("\nBacking up dummy users...")
for u_id in DUMMY_USER_IDS:
    doc = db.collection("User").document(u_id).get()
    if doc.exists:
        backup_data["users"][u_id] = doc.to_dict()
        print(f"  Backed up user: {u_id}")

# Write to file
with open(backup_file, "w", encoding="utf-8") as f:
    json.dump(backup_data, f, default=str, indent=2)

print("\n" + "=" * 60)
print(f"BACKUP COMPLETE: {backup_file}")
print(f"Total dummy brokers backed up: {len(backup_data['brokers'])}")
print(f"Total dummy drivers backed up: {len(backup_data['drivers'])}")
print(f"Total dummy users backed up:   {len(backup_data['users'])}")
print(f"File size: {os.path.getsize(backup_file)} bytes")
print("=" * 60)
