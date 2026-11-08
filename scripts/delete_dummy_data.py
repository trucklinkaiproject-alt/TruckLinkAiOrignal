import os
import json
import firebase_admin
from firebase_admin import credentials, firestore

DOWNLOADS_KEY = r"C:\Users\mrkam\Downloads\trucklink-ai-orignal-firebase-adminsdk-fbsvc-92b5ef0e59.json"
sa_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS", DOWNLOADS_KEY)

cred = credentials.Certificate(sa_path)
if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)

db = firestore.client()

DUMMY_BROKER_IDS = {
    "broker_al_madina",
    "broker_chenab_logistics",
    "broker_faisal_movers",
    "broker_indus_cargo",
    "broker_khyber_express",
    "broker_mehran_freight",
    "broker_pak_swift",
    "broker_tariq_freight",
}

DUMMY_DRIVER_IDS = {
    "drv_abdul_rehman", "drv_akhtar_rasool", "drv_arshad_nadeem", "drv_asif_mahmood",
    "drv_bilal_shah", "drv_farhan_memon", "drv_gul_khan", "drv_habib_ullah",
    "drv_imran_ali", "drv_kamran_bhatti", "drv_kashif_khan", "drv_mazhar_iqbal",
    "drv_nadir_khan", "drv_nawaz_baloch", "drv_qasim_sheikh", "drv_rashid_minhas",
    "drv_sajjad_haider", "drv_shahid_latif", "drv_sher_afghan", "drv_tanveer_hussain",
    "drv_tariq_mehmood", "drv_usman_warraich", "drv_zahid_paracha",
}

DUMMY_USER_IDS = {
    "user_hamza_javed", "user_kamran_ahmed", "user_sana_sheikh",
    "user_usman_farooq", "user_zainab_malik",
}

PROTECTED_IDS = {
    "AKTi4CpEQcWPZQyArld1NCfawGH2",  # Genuine Broker
    "FR5eDm1GZHaNcxzLi0hzHzvIDC62",  # Genuine Driver
    "IA1iNiqAKWMRcWtd7O18pKiuknq1",  # Genuine User (Kamrankhan67)
    "z3THIu5BHDcCiA9kMLupOcH6Koc2",  # Genuine User (Moiz)
    "MS76m52yR2UTVxaab298I1weGbv1",  # Superadmin
}

print("=" * 60)
print("DELETING CONFIRMED DUMMY DATA FROM FIRESTORE")
print("=" * 60)

deleted_counts = {
    "brokers": 0,
    "broker_subcol_docs": 0,
    "drivers": 0,
    "users": 0,
}

# 1. Delete Dummy Brokers & Subcollections
print("\n1. Deleting Dummy Brokers...")
for b_id in DUMMY_BROKER_IDS:
    if b_id in PROTECTED_IDS:
        print(f"  [ABORT] Protected ID encountered: {b_id}")
        continue

    doc_ref = db.collection("Broker").document(b_id)
    doc = doc_ref.get()
    if doc.exists:
        # Delete all subcollections first
        for subcol in doc_ref.collections():
            for s_doc in subcol.stream():
                s_doc.reference.delete()
                deleted_counts["broker_subcol_docs"] += 1
                print(f"    - Deleted subcol doc: Broker/{b_id}/{subcol.id}/{s_doc.id}")

        doc_ref.delete()
        deleted_counts["brokers"] += 1
        print(f"  - Deleted Broker doc: {b_id}")
    else:
        print(f"  - Broker doc {b_id} not found (already deleted)")

# 2. Delete Dummy Drivers
print("\n2. Deleting Dummy Drivers...")
for d_id in DUMMY_DRIVER_IDS:
    if d_id in PROTECTED_IDS:
        print(f"  [ABORT] Protected ID encountered: {d_id}")
        continue

    doc_ref = db.collection("Driver").document(d_id)
    doc = doc_ref.get()
    if doc.exists:
        doc_ref.delete()
        deleted_counts["drivers"] += 1
        print(f"  - Deleted Driver doc: {d_id}")
    else:
        print(f"  - Driver doc {d_id} not found (already deleted)")

# 3. Delete Dummy Users
print("\n3. Deleting Dummy Users...")
for u_id in DUMMY_USER_IDS:
    if u_id in PROTECTED_IDS:
        print(f"  [ABORT] Protected ID encountered: {u_id}")
        continue

    doc_ref = db.collection("User").document(u_id)
    doc = doc_ref.get()
    if doc.exists:
        doc_ref.delete()
        deleted_counts["users"] += 1
        print(f"  - Deleted User doc: {u_id}")
    else:
        print(f"  - User doc {u_id} not found (already deleted)")

print("\n" + "=" * 60)
print("DELETION EXECUTION SUMMARY:")
print(f"  Brokers deleted:            {deleted_counts['brokers']}")
print(f"  Broker subcol docs deleted: {deleted_counts['broker_subcol_docs']}")
print(f"  Drivers deleted:            {deleted_counts['drivers']}")
print(f"  Users deleted:              {deleted_counts['users']}")
print("=" * 60)
