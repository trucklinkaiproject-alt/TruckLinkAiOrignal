import os
import sys

# Ensure ml directory is in sys.path during pytest runs
ML_DIR = os.path.dirname(__file__)
if ML_DIR not in sys.path:
    sys.path.insert(0, ML_DIR)

