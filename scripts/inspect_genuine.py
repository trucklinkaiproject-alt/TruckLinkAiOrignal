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

# Check genuine broker
broker_doc = db.collection("Broker").document("AKTi4CpEQcWPZQyArld1NCfawGH2").get()
print("GENUINE BROKER DOC:")
print(json.dumps(broker_doc.to_dict(), default=str, indent=2))

print("\nGENUINE BROKER DriverNetwork:")
for doc in db.collection("Broker").document("AKTi4CpEQcWPZQyArld1NCfawGH2").collection("DriverNetwork").stream():
    print(f"DriverNetwork doc {doc.id}:")
    print(json.dumps(doc.to_dict(), default=str, indent=2))

# Check genuine driver
driver_doc = db.collection("Driver").document("FR5eDm1GZHaNcxzLi0hzHzvIDC62").get()
print("\nGENUINE DRIVER DOC:")
print(json.dumps(driver_doc.to_dict(), default=str, indent=2))
