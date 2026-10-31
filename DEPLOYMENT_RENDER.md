# TruckLink AI – FastAPI Backend Deployment Guide (Render Free Tier)

This guide provides the shortest, exact steps to deploy the **TruckLink AI Broker Recommendation Service** to [Render](https://render.com) using its **Free Web Service** tier (100% Free, zero credit card / billing required).

---

## 1. Prerequisites Prepared in This Repository

All configuration files have been prepared:
- `render.yaml`: Render Blueprint configuration for Infrastructure-as-Code.
- `requirements.txt`: Root and `ml/` Python dependencies pinned for cloud deployment.
- `Dockerfile`: Portable container configuration (optional alternative to native Python runtime).
- `.gitignore`: Hardened against leaking credentials, `.env` files, or service account keys.
- `ml/models/broker_recommender.pkl`: Pre-trained ML model artifact (~475 KB, packaged directly in repo).
- `ml/api/main.py`: Configured to dynamically bind to `0.0.0.0:$PORT` with `/health` and `/ready` endpoints and CORS enabled.
- `ml/api/firestore_repository.py`: Configured to read Firebase credentials from the `FIREBASE_CREDENTIALS_JSON` environment variable.

---

## 2. Option A: Fastest 1-Click Deployment via Render Blueprint

1. **Push your latest changes to GitHub:**
   ```bash
   git add requirements.txt render.yaml Dockerfile .gitignore ml/ TruckLinkAiOrignal/
   git commit -m "Configure FastAPI backend for Render Free Tier deployment"
   git push origin main
   ```

2. **Log into Render:**
   - Go to [dashboard.render.com](https://dashboard.render.com) (free sign-up via GitHub).

3. **Deploy the Blueprint:**
   - Click **New +** (top right) $\rightarrow$ **Blueprint**.
   - Select your repository: `trucklinkaiproject-alt/TruckLinkAiOrignal`.
   - Render automatically detects `render.yaml`.
   - Click **Apply**.

4. **Add Firebase Credentials (Securely):**
   - In Render Dashboard $\rightarrow$ Click on `trucklink-ai-recommendations` $\rightarrow$ **Environment**.
   - Under **Environment Variables**, locate `FIREBASE_CREDENTIALS_JSON`.
   - Click **Edit** and paste the entire JSON content of your Firebase service account key (`serviceAccountKey.json`).
   - Click **Save Changes**. Render will automatically redeploy with live Firestore access enabled.

---

## 3. Option B: Manual Web Service Setup (Alternative)

If you prefer configuring without Blueprints:
1. In Render Dashboard, click **New +** $\rightarrow$ **Web Service**.
2. Connect your GitHub repository: `trucklinkaiproject-alt/TruckLinkAiOrignal`.
3. Configure the following fields:
   - **Name:** `trucklink-ai-recommendations`
   - **Region:** Any free region (e.g., `Oregon (US West)` or `Frankfurt (EU)`)
   - **Branch:** `main`
   - **Root Directory:** leave blank (repository root)
   - **Runtime:** `Python 3`
   - **Build Command:** `pip install --upgrade pip && pip install -r requirements.txt`
   - **Start Command:** `python -m uvicorn ml.api.main:app --host 0.0.0.0 --port $PORT`
   - **Instance Type:** `Free`
4. Under **Advanced** $\rightarrow$ **Add Environment Variable**:
   - `PYTHON_VERSION`: `3.11.9`
   - `ENVIRONMENT`: `production`
   - `PYTHONPATH`: `.`
   - `MAX_ACCEPTABLE_DRIVER_DISTANCE_KM`: `150.0`
   - `TOP_K_RECOMMENDATIONS`: `3`
   - `FIREBASE_CREDENTIALS_JSON`: `<paste contents of serviceAccountKey.json>`
5. Click **Create Web Service**.

---

## 4. Verifying Your Live Deployment

Once Render finishes building (usually 2–3 minutes), your service will be assigned a permanent public HTTPS URL:
`https://trucklink-ai-recommendations.onrender.com` (or your chosen service name).

### 1. Health Probe Check
Open in your browser or run:
```bash
curl https://trucklink-ai-recommendations.onrender.com/health
```
Expected response:
```json
{
  "status": "healthy",
  "model_loaded": true,
  "model_version": "1.0.0",
  "firestore_connected": true,
  "canonical_vehicle_types": [
    "Truck",
    "Van",
    "Trailer",
    "Container",
    "PickUp Truck",
    "Shahzore",
    "Loader Rickshaw",
    "Other"
  ]
}
```

### 2. Readiness Probe Check
```bash
curl https://trucklink-ai-recommendations.onrender.com/ready
```
Expected response:
```json
{
  "status": "ready",
  "model_loaded": true,
  "model_version": "1.0.0",
  "firestore_connected": true
}
```

### 3. Interactive Swagger Documentation
Open in your browser:
`https://trucklink-ai-recommendations.onrender.com/docs`

---

## 5. Important Free-Tier Hosting Behaviors & App Handling

Render's free plan provides generous free compute with the following characteristics:
1. **Inactivity Sleep (Spin-Down):** If no requests arrive for **15 minutes**, Render spins down the container to conserve resources.
2. **Automatic Wake-Up (Cold Start):** When a new request arrives, Render automatically spins the container back up. The first request takes **30–45 seconds** to respond. Subsequent requests respond in **<100 ms**.
3. **Flutter Client Protection:** The Flutter application (`RecommendationApiService` & `BrokerRecommendationCubit`) has been built specifically for this:
   - **45-second timeout** allows the server to wake up without error.
   - **Informative UI indicator:** Shows *"Finding best brokers (connecting to AI engine)..."*.
   - **Retry button:** If a cold start times out, the user is offered a *"Retry AI"* button without creating duplicate transport orders.

---

## 6. Connecting Flutter to Your Render URL

The Flutter application is pre-configured to use `https://trucklink-ai-recommendations.onrender.com`.

If your Render service has a custom name (e.g., `https://my-trucklink-api.onrender.com`), you can point the app to it in any of three ways:

1. **Option 1 (Compile-time flag, no code changes needed):**
   ```bash
   flutter build apk --release --dart-define=REC_API_URL=https://your-service.onrender.com
   ```

2. **Option 2 (Code configuration):**
   Update `kDefaultProductionUrl` in:
   `TruckLinkAiOrignal/lib/Core/Services/recommendationApiService.dart`:
   ```dart
   static const String kDefaultProductionUrl = 'https://your-service.onrender.com';
   ```

3. **Option 3 (Runtime API configuration):**
   Call `RecommendationApiService.configureProductionUrl('https://your-service.onrender.com');` at app initialization.

