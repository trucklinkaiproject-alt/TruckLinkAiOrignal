"""
ml/api/firestore_repository.py

Repository for fetching live production records from Cloud Firestore.
Strictly adheres to:
- No CSV or synthetic data is ever written to production Firestore.
- Read-only operations for broker recommendations.
- Fallback to safe local testing provider when running offline.
"""

import os
import json
import base64
import logging
from typing import List, Dict, Any, Optional

logger = logging.getLogger("trucklink.firestore")

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
    FIREBASE_AVAILABLE = True
except ImportError:
    FIREBASE_AVAILABLE = False


class FirestoreRepository:
    def __init__(self, service_account_path: Optional[str] = None):
        self.db = None
        self._initialized = False

        if not FIREBASE_AVAILABLE:
            logger.warning("firebase_admin package not installed. Operating in offline/mock mode.")
            return

        try:
            if not firebase_admin._apps:
                # 1. Check for raw JSON string in environment variable (Render / Cloud PaaS standard)
                raw_json = os.getenv("FIREBASE_CREDENTIALS_JSON")
                # 2. Check for Base64 encoded JSON string
                b64_json = os.getenv("FIREBASE_CREDENTIALS_BASE64")
                # 3. Check for service account file path
                sa_path = service_account_path or os.getenv("GOOGLE_APPLICATION_CREDENTIALS")

                if raw_json and raw_json.strip():
                    try:
                        cert_dict = json.loads(raw_json)
                        cred = credentials.Certificate(cert_dict)
                        firebase_admin.initialize_app(cred)
                        logger.info("Firebase Admin SDK initialized using FIREBASE_CREDENTIALS_JSON env var.")
                    except Exception as e:
                        logger.error(f"Failed to parse FIREBASE_CREDENTIALS_JSON: {e}")

                elif b64_json and b64_json.strip():
                    try:
                        decoded_str = base64.b64decode(b64_json).decode("utf-8")
                        cert_dict = json.loads(decoded_str)
                        cred = credentials.Certificate(cert_dict)
                        firebase_admin.initialize_app(cred)
                        logger.info("Firebase Admin SDK initialized using FIREBASE_CREDENTIALS_BASE64 env var.")
                    except Exception as e:
                        logger.error(f"Failed to parse FIREBASE_CREDENTIALS_BASE64: {e}")

                elif sa_path and os.path.exists(sa_path):
                    cred = credentials.Certificate(sa_path)
                    firebase_admin.initialize_app(cred)
                    logger.info(f"Firebase Admin SDK initialized with service account at: {sa_path}")

                else:
                    # Attempt application default credentials (GCP / local emulator)
                    try:
                        firebase_admin.initialize_app()
                        logger.info("Firebase Admin SDK initialized with Application Default Credentials.")
                    except Exception as adc_err:
                        logger.warning(
                            f"Application Default Credentials not available ({adc_err}). "
                            "Running repository in local development mode."
                        )

            if firebase_admin._apps:
                self.db = firestore.client()
                self._initialized = True
        except Exception as e:
            logger.warning(
                f"Could not initialize live Firebase Admin SDK ({e}). "
                "The repository will operate in local development mode."
            )
            self._initialized = False

    @property
    def is_connected(self) -> bool:
        return self._initialized and self.db is not None

    def fetch_active_brokers(self) -> List[Dict[str, Any]]:
        """Fetches active, non-blocked broker documents from /Broker collection."""
        if not self.is_connected:
            logger.info("Live Firestore not connected. Returning empty broker list.")
            return []

        try:
            brokers_ref = self.db.collection("Broker")
            docs = brokers_ref.stream()

            brokers = []
            for doc in docs:
                data = doc.to_dict() or {}
                data["id"] = doc.id
                status = str(data.get("status", "active")).lower()
                if status not in ("blocked", "suspended"):
                    brokers.append(data)
            return brokers
        except Exception as e:
            logger.error(f"Error fetching brokers from Firestore: {e}")
            return []

    def fetch_broker_drivers(self, broker_id: str) -> List[Dict[str, Any]]:
        """
        Fetches all registered drivers for a broker from:
        1. /Broker/{broker_id}/DriverNetwork subcollection
        2. /Driver collection where broker_id == broker_id OR brokerId == broker_id
        """
        if not self.is_connected or not broker_id:
            return []

        drivers = []
        seen_driver_ids = set()

        try:
            # 1. DriverNetwork subcollection
            subcol = self.db.collection("Broker").document(broker_id).collection("DriverNetwork").stream()
            for doc in subcol:
                d = doc.to_dict() or {}
                d_id = doc.id
                d["id"] = d_id
                seen_driver_ids.add(d_id)
                drivers.append(d)

            # 2. Driver root collection where broker_id == broker_id or brokerId == broker_id
            for query_field in ("broker_id", "brokerId"):
                try:
                    root_drivers = self.db.collection("Driver").where(query_field, "==", broker_id).stream()
                    for doc in root_drivers:
                        if doc.id not in seen_driver_ids:
                            d = doc.to_dict() or {}
                            d["id"] = doc.id
                            seen_driver_ids.add(doc.id)
                            drivers.append(d)
                except Exception as q_err:
                    logger.debug(f"Query Driver on {query_field} notice: {q_err}")

            return drivers
        except Exception as e:
            logger.error(f"Error fetching drivers for broker {broker_id}: {e}")
            return []
