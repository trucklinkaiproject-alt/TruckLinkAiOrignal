import os
import firebase_admin
from firebase_admin import credentials, firestore

DOWNLOADS_KEY = r"C:\Users\mrkam\Downloads\trucklink-ai-orignal-firebase-adminsdk-fbsvc-92b5ef0e59.json"
sa_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS", DOWNLOADS_KEY)

cred = credentials.Certificate(sa_path)
if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)

db = firestore.client()

print("=" * 60)
print(f"FIRESTORE AUDIT (Project: {cred.project_id})")
print("=" * 60)

# Check all root collections
root_cols = [c.id for c in db.collections()]
print(f"Root Collections found: {root_cols}\n")

for col_name in root_cols:
    col_ref = db.collection(col_name)
    docs = list(col_ref.stream())
    print(f"Collection [{col_name}]: {len(docs)} documents")
    for doc in docs:
        data = doc.to_dict() or {}
        name = data.get("name") or data.get("companyName") or data.get("userName") or "N/A"
        email = data.get("email") or "N/A"
        phone = data.get("phone") or data.get("phoneNumber") or "N/A"
        role = data.get("role") or "N/A"
        created = data.get("createdAt") or data.get("created_at") or "N/A"
        status = data.get("status") or "N/A"
        print(f"  [{doc.id}] Name: {name} | Email: {email} | Phone: {phone} | Role: {role} | Status: {status} | Created: {created}")
        
        # Check subcollections if broker
        if col_name == "Broker":
            subcols = [sc.id for sc in doc.reference.collections()]
            if subcols:
                for sc_name in subcols:
                    sub_docs = list(doc.reference.collection(sc_name).stream())
                    print(f"      Subcollection [{sc_name}]: {len(sub_docs)} docs")
    print("-" * 60)
