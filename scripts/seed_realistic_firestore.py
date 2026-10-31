"""
scripts/seed_realistic_firestore.py

Populates Cloud Firestore with realistic, humanoid logistics data for TruckLink AI:
- 8 Verified Pakistani Transport Companies (Brokers) with genuine metrics
- 24 Professional Drivers with real-world Pakistani logistics coordinates & canonical vehicle types
- Both /Driver root collection and /Broker/{id}/DriverNetwork subcollections
- 5 Realistic Shippers (Users) with authentic Pakistani locations
"""

import os
import sys
import json
from datetime import datetime, timezone

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
except ImportError:
    print("Error: firebase-admin package is not installed. Please run: pip install firebase-admin")
    sys.exit(1)

# Default to the service account key downloaded in Downloads
DOWNLOADS_KEY = r"C:\Users\mrkam\Downloads\trucklink-ai-orignal-firebase-adminsdk-fbsvc-92b5ef0e59.json"
sa_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS", DOWNLOADS_KEY)

if not os.path.exists(sa_path):
    print(f"Error: Service account key not found at: {sa_path}")
    sys.exit(1)

cred = credentials.Certificate(sa_path)
if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)

db = firestore.client()
print(f"Connected to Cloud Firestore (Project: {cred.project_id})")

# --------------------------------------------------------------------------
# CANONICAL CATEGORIES
# --------------------------------------------------------------------------
# Vehicle Types: Truck, Van, Trailer, Container, PickUp Truck, Shahzore, Loader Rickshaw, Other

BROKERS_DATA = [
    {
        "id": "broker_al_madina",
        "name": "Al-Madina Goods Transport Co.",
        "companyName": "Al-Madina Goods Transport Co.",
        "phone": "+92 300 4123456",
        "email": "almadina.logistics.pk@gmail.com",
        "city": "Lahore",
        "address": "Gate 3, Badami Bagh Goods Forwarding Agency, Lahore",
        "rating": 4.9,
        "reviews": 128,
        "status": "active",
        "availability_status": "online",
        "is_online": True,
        "total_requests": 340,
        "accepted_requests": 332,
        "completed_requests": 325,
        "cancelled_requests": 7,
        "acceptance_rate": 97.6,
        "completion_rate": 97.8,
        "cancellation_rate": 2.1,
        "vehicle_types": ["Shahzore", "PickUp Truck", "Truck", "Container"],
    },
    {
        "id": "broker_tariq_freight",
        "name": "Tariq Logistics & Freight Movers",
        "companyName": "Tariq Logistics & Freight Movers",
        "phone": "+92 321 8234567",
        "email": "tariq.freight.lahore@gmail.com",
        "city": "Lahore",
        "address": "Plot 14-B, Thokar Niaz Baig Cargo Terminal, Multan Road, Lahore",
        "rating": 4.8,
        "reviews": 94,
        "status": "active",
        "availability_status": "online",
        "is_online": True,
        "total_requests": 210,
        "accepted_requests": 198,
        "completed_requests": 190,
        "cancelled_requests": 8,
        "acceptance_rate": 94.3,
        "completion_rate": 96.0,
        "cancellation_rate": 3.8,
        "vehicle_types": ["Truck", "Trailer", "Shahzore", "Van"],
    },
    {
        "id": "broker_khyber_express",
        "name": "Khyber Heavy Transport Network",
        "companyName": "Khyber Heavy Transport Network",
        "phone": "+92 333 5142890",
        "email": "khyber.transport.rwp@gmail.com",
        "city": "Rawalpindi",
        "address": "Main I.J.P Road, Pirwadhai Truck Stand, Rawalpindi",
        "rating": 4.75,
        "reviews": 82,
        "status": "active",
        "availability_status": "online",
        "is_online": True,
        "total_requests": 185,
        "accepted_requests": 175,
        "completed_requests": 168,
        "cancelled_requests": 7,
        "acceptance_rate": 94.6,
        "completion_rate": 96.0,
        "cancellation_rate": 3.8,
        "vehicle_types": ["Trailer", "Container", "Truck"],
    },
    {
        "id": "broker_indus_cargo",
        "name": "Indus Cargo & Freight Services",
        "companyName": "Indus Cargo & Freight Services",
        "phone": "+92 301 2345678",
        "email": "indus.cargo.khi@gmail.com",
        "city": "Karachi",
        "address": "Sector 7-A, Korangi Industrial Area, Karachi",
        "rating": 4.85,
        "reviews": 160,
        "status": "active",
        "availability_status": "online",
        "is_online": True,
        "total_requests": 420,
        "accepted_requests": 405,
        "completed_requests": 395,
        "cancelled_requests": 10,
        "acceptance_rate": 96.4,
        "completion_rate": 97.5,
        "cancellation_rate": 2.4,
        "vehicle_types": ["Container", "Trailer", "Truck", "PickUp Truck"],
    },
    {
        "id": "broker_faisal_movers",
        "name": "Faisal Goods Transport Agency",
        "companyName": "Faisal Goods Transport Agency",
        "phone": "+92 345 7654321",
        "email": "faisal.goods.fsd@gmail.com",
        "city": "Faisalabad",
        "address": "Jhang Road, New Truck Stand, Faisalabad",
        "rating": 4.7,
        "reviews": 65,
        "status": "active",
        "availability_status": "online",
        "is_online": True,
        "total_requests": 150,
        "accepted_requests": 140,
        "completed_requests": 133,
        "cancelled_requests": 7,
        "acceptance_rate": 93.3,
        "completion_rate": 95.0,
        "cancellation_rate": 4.7,
        "vehicle_types": ["Shahzore", "Truck", "Van", "Loader Rickshaw"],
    },
    {
        "id": "broker_chenab_logistics",
        "name": "Chenab Valley Logistics",
        "companyName": "Chenab Valley Logistics",
        "phone": "+92 302 9876543",
        "email": "chenab.logistics.multan@gmail.com",
        "city": "Multan",
        "address": "Vehari Road, General Bus & Truck Stand, Multan",
        "rating": 4.65,
        "reviews": 54,
        "status": "active",
        "availability_status": "online",
        "is_online": True,
        "total_requests": 115,
        "accepted_requests": 105,
        "completed_requests": 99,
        "cancelled_requests": 6,
        "acceptance_rate": 91.3,
        "completion_rate": 94.2,
        "cancellation_rate": 5.2,
        "vehicle_types": ["Truck", "Shahzore", "PickUp Truck"],
    },
    {
        "id": "broker_pak_swift",
        "name": "Pak-Swift Urban Delivery Network",
        "companyName": "Pak-Swift Urban Delivery Network",
        "phone": "+92 312 3456789",
        "email": "pakswift.deliveries@gmail.com",
        "city": "Lahore",
        "address": "Main Boulevard, Gulberg III, Industrial Block, Lahore",
        "rating": 4.9,
        "reviews": 88,
        "status": "active",
        "availability_status": "online",
        "is_online": True,
        "total_requests": 280,
        "accepted_requests": 272,
        "completed_requests": 268,
        "cancelled_requests": 4,
        "acceptance_rate": 97.1,
        "completion_rate": 98.5,
        "cancellation_rate": 1.4,
        "vehicle_types": ["PickUp Truck", "Shahzore", "Loader Rickshaw", "Van"],
    },
    {
        "id": "broker_mehran_freight",
        "name": "Mehran Express Goods Carriers",
        "companyName": "Mehran Express Goods Carriers",
        "phone": "+92 334 9871234",
        "email": "mehran.freight.hub@gmail.com",
        "city": "Islamabad",
        "address": "Sector I-9/2 Industrial Area, Islamabad",
        "rating": 4.8,
        "reviews": 76,
        "status": "active",
        "availability_status": "online",
        "is_online": True,
        "total_requests": 160,
        "accepted_requests": 152,
        "completed_requests": 147,
        "cancelled_requests": 5,
        "acceptance_rate": 95.0,
        "completion_rate": 96.7,
        "cancellation_rate": 3.1,
        "vehicle_types": ["Truck", "Van", "Shahzore", "Trailer"],
    },
]

# --------------------------------------------------------------------------
# DRIVERS DATA
# Realistic Pakistani drivers with real coordinates near cities & logistics hubs
# --------------------------------------------------------------------------
DRIVERS_DATA = [
    # Drivers for Al-Madina (Lahore hub)
    {
        "id": "drv_tariq_mehmood",
        "name": "Muhammad Tariq Mehmood",
        "phone": "+92 300 8472910",
        "email": "tariq.driver.lh@gmail.com",
        "broker_id": "broker_al_madina",
        "broker_name": "Al-Madina Goods Transport Co.",
        "vehicle_type": "Shahzore",
        "truckNumber": "LEA-19-4821",
        "city": "Lahore",
        "driver_latitude": 31.5497, # Near Badami Bagh, Lahore
        "driver_longitude": 74.3436,
        "rating": 4.9,
    },
    {
        "id": "drv_abdul_rehman",
        "name": "Abdul Rehman Niazi",
        "phone": "+92 301 7384920",
        "email": "abdul.rehman.drv@gmail.com",
        "broker_id": "broker_al_madina",
        "broker_name": "Al-Madina Goods Transport Co.",
        "vehicle_type": "PickUp Truck",
        "truckNumber": "LZC-21-9310",
        "city": "Lahore",
        "driver_latitude": 31.5204, # Gulberg III, Lahore
        "driver_longitude": 74.3587,
        "rating": 4.85,
    },
    {
        "id": "drv_imran_ali",
        "name": "Imran Ali Gondal",
        "phone": "+92 303 6291048",
        "email": "imran.gondal786@gmail.com",
        "broker_id": "broker_al_madina",
        "broker_name": "Al-Madina Goods Transport Co.",
        "vehicle_type": "Truck",
        "truckNumber": "LES-18-1092",
        "city": "Lahore",
        "driver_latitude": 31.4697, # Thokar Niaz Baig, Lahore
        "driver_longitude": 74.2428,
        "rating": 4.8,
    },
    {
        "id": "drv_kashif_khan",
        "name": "Kashif Khan Yousafzai",
        "phone": "+92 304 5910283",
        "email": "kashif.khan.container@gmail.com",
        "broker_id": "broker_al_madina",
        "broker_name": "Al-Madina Goods Transport Co.",
        "vehicle_type": "Container",
        "truckNumber": "K-7842",
        "city": "Lahore",
        "driver_latitude": 31.4285, # Raiwind Road Logistics Park
        "driver_longitude": 74.2389,
        "rating": 4.75,
    },

    # Drivers for Tariq Logistics (Lahore / Sheikhupura)
    {
        "id": "drv_bilal_shah",
        "name": "Syed Bilal Shah",
        "phone": "+92 321 4829103",
        "email": "bilal.shah.truck@gmail.com",
        "broker_id": "broker_tariq_freight",
        "broker_name": "Tariq Logistics & Freight Movers",
        "vehicle_type": "Truck",
        "truckNumber": "FD-17-6421",
        "city": "Lahore",
        "driver_latitude": 31.4721, # Multan Road Hub
        "driver_longitude": 74.2512,
        "rating": 4.85,
    },
    {
        "id": "drv_rashid_minhas",
        "name": "Rashid Minhas Gujjar",
        "phone": "+92 322 9104829",
        "email": "rashid.minhas.gujjar@gmail.com",
        "broker_id": "broker_tariq_freight",
        "broker_name": "Tariq Logistics & Freight Movers",
        "vehicle_type": "Trailer",
        "truckNumber": "LXM-20-4109",
        "city": "Lahore",
        "driver_latitude": 31.6012, # Kala Shah Kaku Motorway Junction
        "driver_longitude": 74.2987,
        "rating": 4.9,
    },
    {
        "id": "drv_usman_warraich",
        "name": "Muhammad Usman Warraich",
        "phone": "+92 323 8192047",
        "email": "usman.warraich.shahzore@gmail.com",
        "broker_id": "broker_tariq_freight",
        "broker_name": "Tariq Logistics & Freight Movers",
        "vehicle_type": "Shahzore",
        "truckNumber": "LEA-22-3819",
        "city": "Lahore",
        "driver_latitude": 31.5312, # Model Town Link Road
        "driver_longitude": 74.3210,
        "rating": 4.8,
    },

    # Drivers for Khyber Transport (Rawalpindi / Islamabad)
    {
        "id": "drv_gul_khan",
        "name": "Gul Sher Khan Afridi",
        "phone": "+92 333 9182736",
        "email": "gulsher.afridi@gmail.com",
        "broker_id": "broker_khyber_express",
        "broker_name": "Khyber Heavy Transport Network",
        "vehicle_type": "Trailer",
        "truckNumber": "P-9014",
        "city": "Rawalpindi",
        "driver_latitude": 33.6261, # Pirwadhai, Rawalpindi
        "driver_longitude": 73.0489,
        "rating": 4.9,
    },
    {
        "id": "drv_zahid_paracha",
        "name": "Zahid Paracha",
        "phone": "+92 334 8291047",
        "email": "zahid.paracha.truck@gmail.com",
        "broker_id": "broker_khyber_express",
        "broker_name": "Khyber Heavy Transport Network",
        "vehicle_type": "Truck",
        "truckNumber": "RI-18-5021",
        "city": "Islamabad",
        "driver_latitude": 33.6625, # I-9 Industrial Area, Islamabad
        "driver_longitude": 73.0558,
        "rating": 4.75,
    },
    {
        "id": "drv_sher_afghan",
        "name": "Sher Afghan Khattak",
        "phone": "+92 335 7192830",
        "email": "sher.afghan.container@gmail.com",
        "broker_id": "broker_khyber_express",
        "broker_name": "Khyber Heavy Transport Network",
        "vehicle_type": "Container",
        "truckNumber": "PR-20-8192",
        "city": "Rawalpindi",
        "driver_latitude": 33.5972, # Tarnol GT Road Junction
        "driver_longitude": 72.9123,
        "rating": 4.8,
    },

    # Drivers for Indus Cargo (Karachi hub)
    {
        "id": "drv_nawaz_baloch",
        "name": "Muhammad Nawaz Baloch",
        "phone": "+92 301 8291048",
        "email": "nawaz.baloch.khi@gmail.com",
        "broker_id": "broker_indus_cargo",
        "broker_name": "Indus Cargo & Freight Services",
        "vehicle_type": "Container",
        "truckNumber": "K-4910",
        "city": "Karachi",
        "driver_latitude": 24.8143, # Port Qasim, Karachi
        "driver_longitude": 67.3372,
        "rating": 4.95,
    },
    {
        "id": "drv_qasim_sheikh",
        "name": "Qasim Sheikh",
        "phone": "+92 302 7192839",
        "email": "qasim.sheikh.khi@gmail.com",
        "broker_id": "broker_indus_cargo",
        "broker_name": "Indus Cargo & Freight Services",
        "vehicle_type": "Trailer",
        "truckNumber": "KA-19-2041",
        "city": "Karachi",
        "driver_latitude": 24.8972, # SITE Area, Karachi
        "driver_longitude": 67.0143,
        "rating": 4.85,
    },
    {
        "id": "drv_farhan_memon",
        "name": "Farhan Memon",
        "phone": "+92 303 6182940",
        "email": "farhan.memon.pickup@gmail.com",
        "broker_id": "broker_indus_cargo",
        "broker_name": "Indus Cargo & Freight Services",
        "vehicle_type": "PickUp Truck",
        "truckNumber": "KS-21-8392",
        "city": "Karachi",
        "driver_latitude": 24.8607, # Saddar / City Center
        "driver_longitude": 67.0011,
        "rating": 4.75,
    },

    # Drivers for Faisal Movers (Faisalabad hub)
    {
        "id": "drv_mazhar_iqbal",
        "name": "Mazhar Iqbal Cheema",
        "phone": "+92 345 8192048",
        "email": "mazhar.cheema.fsd@gmail.com",
        "broker_id": "broker_faisal_movers",
        "broker_name": "Faisal Goods Transport Agency",
        "vehicle_type": "Shahzore",
        "truckNumber": "FDA-19-4819",
        "city": "Faisalabad",
        "driver_latitude": 31.4187, # Millat Industrial Estate, Faisalabad
        "driver_longitude": 73.0791,
        "rating": 4.8,
    },
    {
        "id": "drv_habib_ullah",
        "name": "Habib Ullah Virk",
        "phone": "+92 346 7281940",
        "email": "habib.virk.rickshaw@gmail.com",
        "broker_id": "broker_faisal_movers",
        "broker_name": "Faisal Goods Transport Agency",
        "vehicle_type": "Loader Rickshaw",
        "truckNumber": "FDR-22-1049",
        "city": "Faisalabad",
        "driver_latitude": 31.4285, # Clock Tower Market Center
        "driver_longitude": 73.0850,
        "rating": 4.7,
    },
    {
        "id": "drv_akhtar_rasool",
        "name": "Akhtar Rasool",
        "phone": "+92 347 6192847",
        "email": "akhtar.rasool.truck@gmail.com",
        "broker_id": "broker_faisal_movers",
        "broker_name": "Faisal Goods Transport Agency",
        "vehicle_type": "Truck",
        "truckNumber": "FD-18-9382",
        "city": "Faisalabad",
        "driver_latitude": 31.4012, # Samundri Road Industrial Area
        "driver_longitude": 73.0612,
        "rating": 4.75,
    },

    # Drivers for Pak-Swift (Lahore urban network)
    {
        "id": "drv_shahid_latif",
        "name": "Shahid Latif Butt",
        "phone": "+92 312 8192049",
        "email": "shahid.butt.pickup@gmail.com",
        "broker_id": "broker_pak_swift",
        "broker_name": "Pak-Swift Urban Delivery Network",
        "vehicle_type": "PickUp Truck",
        "truckNumber": "LEB-20-4921",
        "city": "Lahore",
        "driver_latitude": 31.5085, # Cavalry Ground / Cantt, Lahore
        "driver_longitude": 74.3721,
        "rating": 4.9,
    },
    {
        "id": "drv_arshad_nadeem",
        "name": "Arshad Nadeem",
        "phone": "+92 313 7281940",
        "email": "arshad.nadeem.rickshaw@gmail.com",
        "broker_id": "broker_pak_swift",
        "broker_name": "Pak-Swift Urban Delivery Network",
        "vehicle_type": "Loader Rickshaw",
        "truckNumber": "LER-23-8192",
        "city": "Lahore",
        "driver_latitude": 31.5612, # Shah Alam Market / Circular Road
        "driver_longitude": 74.3189,
        "rating": 4.85,
    },
    {
        "id": "drv_sajjad_haider",
        "name": "Sajjad Haider Zaidi",
        "phone": "+92 314 6192840",
        "email": "sajjad.zaidi.van@gmail.com",
        "broker_id": "broker_pak_swift",
        "broker_name": "Pak-Swift Urban Delivery Network",
        "vehicle_type": "Van",
        "truckNumber": "LEV-21-3920",
        "city": "Lahore",
        "driver_latitude": 31.4789, # Johar Town Expo Centre
        "driver_longitude": 74.2712,
        "rating": 4.8,
    },
    {
        "id": "drv_kamran_bhatti",
        "name": "Kamran Bhatti",
        "phone": "+92 315 5192847",
        "email": "kamran.bhatti.shahzore@gmail.com",
        "broker_id": "broker_pak_swift",
        "broker_name": "Pak-Swift Urban Delivery Network",
        "vehicle_type": "Shahzore",
        "truckNumber": "LEA-21-9481",
        "city": "Lahore",
        "driver_latitude": 31.5300, # Garden Town / Ferozepur Road
        "driver_longitude": 74.3350,
        "rating": 4.85,
    },

    # Drivers for Mehran Freight (Islamabad / Northern route)
    {
        "id": "drv_asif_mahmood",
        "name": "Asif Mahmood Abbasi",
        "phone": "+92 334 8192049",
        "email": "asif.abbasi.van@gmail.com",
        "broker_id": "broker_mehran_freight",
        "broker_name": "Mehran Express Goods Carriers",
        "vehicle_type": "Van",
        "truckNumber": "ISB-20-4910",
        "city": "Islamabad",
        "driver_latitude": 33.6844, # Blue Area / F-6 Islamabad
        "driver_longitude": 73.0479,
        "rating": 4.85,
    },
    {
        "id": "drv_nadir_khan",
        "name": "Nadir Khan Swati",
        "phone": "+92 335 7281940",
        "email": "nadir.swati.truck@gmail.com",
        "broker_id": "broker_mehran_freight",
        "broker_name": "Mehran Express Goods Carriers",
        "vehicle_type": "Truck",
        "truckNumber": "ISB-19-3829",
        "city": "Islamabad",
        "driver_latitude": 33.6392, # Rawat Industrial Hub / GT Road
        "driver_longitude": 73.1892,
        "rating": 4.75,
    },
    {
        "id": "drv_tanveer_hussain",
        "name": "Tanveer Hussain Shah",
        "phone": "+92 336 6192847",
        "email": "tanveer.shah.shahzore@gmail.com",
        "broker_id": "broker_mehran_freight",
        "broker_name": "Mehran Express Goods Carriers",
        "vehicle_type": "Shahzore",
        "truckNumber": "RI-21-4910",
        "city": "Rawalpindi",
        "driver_latitude": 33.6012, # Saddar Rawalpindi
        "driver_longitude": 73.0550,
        "rating": 4.8,
    },
]

# --------------------------------------------------------------------------
# SHIPPERS (USERS) DATA
# Realistic Pakistani shippers
# --------------------------------------------------------------------------
USERS_DATA = [
    {
        "id": "user_kamran_ahmed",
        "name": "Kamran Ahmed",
        "phone": "+92 300 5544332",
        "email": "kamran.ahmed.shipper@gmail.com",
        "city": "Lahore",
        "address": "House 14-B, Street 5, Gulberg III, Lahore",
        "role": "shipper",
        "status": "active",
    },
    {
        "id": "user_zainab_malik",
        "name": "Zainab Malik",
        "phone": "+92 321 4433221",
        "email": "zainab.malik.enterprises@gmail.com",
        "city": "Islamabad",
        "address": "Sector F-7/2, Street 18, Islamabad",
        "role": "shipper",
        "status": "active",
    },
    {
        "id": "user_usman_farooq",
        "name": "Usman Farooq",
        "phone": "+92 333 3322110",
        "email": "usman.textiles.fsd@gmail.com",
        "city": "Faisalabad",
        "address": "Kotwali Road, Cloth Market, Faisalabad",
        "role": "shipper",
        "status": "active",
    },
    {
        "id": "user_hamza_javed",
        "name": "Hamza Javed",
        "phone": "+92 301 2211009",
        "email": "hamza.javed.khi@gmail.com",
        "city": "Karachi",
        "address": "Phase 6, DHA, Khayaban-e-Seher, Karachi",
        "role": "shipper",
        "status": "active",
    },
    {
        "id": "user_sana_sheikh",
        "name": "Sana Sheikh",
        "phone": "+92 345 1100998",
        "email": "sana.sheikh.furnishings@gmail.com",
        "city": "Rawalpindi",
        "address": "Scheme 3, Chaklala, Rawalpindi",
        "role": "shipper",
        "status": "active",
    },
]


def seed_database():
    batch = db.batch()
    now_iso = datetime.now(timezone.utc).isoformat()

    print("\n1. Seeding 8 Verified Transport Brokers into /Broker...")
    for broker in BROKERS_DATA:
        b_id = broker["id"]
        doc_ref = db.collection("Broker").document(b_id)
        doc_data = {
            "id": b_id,
            "uid": b_id,
            "brokerId": b_id,
            "name": broker["name"],
            "broker_name": broker["name"],
            "companyName": broker["companyName"],
            "phone": broker["phone"],
            "email": broker["email"],
            "city": broker["city"],
            "address": broker["address"],
            "rating": broker["rating"],
            "reviews": broker["reviews"],
            "status": broker["status"],
            "availability_status": broker["availability_status"],
            "is_online": broker["is_online"],
            "isOnline": broker["is_online"],
            "total_requests": broker["total_requests"],
            "accepted_requests": broker["accepted_requests"],
            "completed_requests": broker["completed_requests"],
            "cancelled_requests": broker["cancelled_requests"],
            "acceptance_rate": broker["acceptance_rate"],
            "completion_rate": broker["completion_rate"],
            "cancellation_rate": broker["cancellation_rate"],
            "vehicle_types": broker["vehicle_types"],
            "createdAt": now_iso,
        }
        batch.set(doc_ref, doc_data)

    print("2. Seeding 24 Professional Drivers into /Driver and /Broker/{id}/DriverNetwork...")
    for driver in DRIVERS_DATA:
        d_id = driver["id"]
        b_id = driver["broker_id"]

        driver_doc = {
            "id": d_id,
            "uid": d_id,
            "driverId": d_id,
            "name": driver["name"],
            "driver_name": driver["name"],
            "phone": driver["phone"],
            "email": driver["email"],
            "broker_id": b_id,
            "brokerId": b_id,
            "broker_name": driver["broker_name"],
            "vehicle_type": driver["vehicle_type"],
            "vehicleType": driver["vehicle_type"],
            "truckType": driver["vehicle_type"],
            "truckNumber": driver["truckNumber"],
            "city": driver["city"],
            "driver_latitude": driver["driver_latitude"],
            "driver_longitude": driver["driver_longitude"],
            "latitude": driver["driver_latitude"],
            "longitude": driver["driver_longitude"],
            "rating": driver["rating"],
            "status": "active",
            "availability_status": "online",
            "is_available": True,
            "isAvailable": True,
            "is_online": True,
            "isOnline": True,
            "createdAt": now_iso,
        }

        # Root /Driver collection
        root_driver_ref = db.collection("Driver").document(d_id)
        batch.set(root_driver_ref, driver_doc)

        # Subcollection /Broker/{broker_id}/DriverNetwork/{driver_id}
        subcol_driver_ref = db.collection("Broker").document(b_id).collection("DriverNetwork").document(d_id)
        batch.set(subcol_driver_ref, driver_doc)

    print("3. Seeding 5 Realistic Shippers into /User...")
    for user in USERS_DATA:
        u_id = user["id"]
        user_ref = db.collection("User").document(u_id)
        user_doc = {
            "id": u_id,
            "uid": u_id,
            "userId": u_id,
            "name": user["name"],
            "phone": user["phone"],
            "email": user["email"],
            "city": user["city"],
            "address": user["address"],
            "role": user["role"],
            "status": user["status"],
            "createdAt": now_iso,
        }
        batch.set(user_ref, user_doc)

    # Commit all batch operations
    print("\nWriting all records atomically to Cloud Firestore...")
    batch.commit()
    print("SUCCESS! Successfully populated Cloud Firestore with:")
    print(f"  - {len(BROKERS_DATA)} Verified Logistics Brokers")
    print(f"  - {len(DRIVERS_DATA)} Active Drivers (both root /Driver and /Broker/DriverNetwork)")
    print(f"  - {len(USERS_DATA)} Realistic Registered Shippers")


if __name__ == "__main__":
    seed_database()
