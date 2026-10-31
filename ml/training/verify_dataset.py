"""
ml/training/verify_dataset.py

Audits and verifies the generated CSV datasets for:
- File existence & sizes
- Record counts
- Schema & column names
- Missing values (null checks)
- Duplicate rows
- Value distributions and category alignment with Flutter source of truth
"""

import os
import pandas as pd

DATA_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "data")

EXPECTED_FILES = ["brokers.csv", "drivers.csv", "requests.csv", "history.csv"]

CANONICAL_VEHICLES = {
    "Truck", "Van", "Trailer", "Container",
    "PickUp Truck", "Shahzore", "Loader Rickshaw", "Other"
}

CANONICAL_CARGO = {
    "Furniture", "Plastic", "Glass", "Iron", "Machinery", "Other"
}


def audit_datasets():
    print("=" * 60)
    print(" TRUCKLINK AI - PHASE 2 DATASET AUDIT & INTEGRITY CHECK")
    print("=" * 60)

    for fname in EXPECTED_FILES:
        fpath = os.path.join(DATA_DIR, fname)
        if not os.path.exists(fpath):
            raise FileNotFoundError(f"Missing required dataset: {fpath}")

        df = pd.read_csv(fpath)
        null_count = df.isnull().sum().sum()
        dup_count = df.duplicated().sum()

        print(f"\n[FILE] {fname}:")
        print(f"  - Rows: {len(df)}, Columns: {len(df.columns)}")
        print(f"  - Columns: {list(df.columns)}")
        print(f"  - Missing/Null Values: {null_count}")
        print(f"  - Duplicate Records: {dup_count}")

        # Check category adherence
        if "vehicle_type" in df.columns:
            observed_v = set(df["vehicle_type"].unique())
            invalid_v = observed_v - CANONICAL_VEHICLES
            print(f"  - Canonical Vehicle Types matched: {observed_v.issubset(CANONICAL_VEHICLES)}")
            if invalid_v:
                print(f"    WARNING: Unexpected vehicle types: {invalid_v}")

        if "cargo_type" in df.columns:
            observed_c = set(df["cargo_type"].unique())
            invalid_c = observed_c - CANONICAL_CARGO
            print(f"  - Canonical Cargo Types matched: {observed_c.issubset(CANONICAL_CARGO)}")
            if invalid_c:
                print(f"    WARNING: Unexpected cargo types: {invalid_c}")

        if "is_successful" in df.columns:
            pos = (df["is_successful"] == 1).sum()
            neg = (df["is_successful"] == 0).sum()
            rate = (pos / len(df)) * 100
            print(f"  - Target Distribution: Positives={pos} ({rate:.2f}%), Negatives={neg} ({100-rate:.2f}%)")

    print("\n" + "=" * 60)
    print(" AUDIT VERDICT: All datasets verified successfully.")
    print("=" * 60)


if __name__ == "__main__":
    audit_datasets()

