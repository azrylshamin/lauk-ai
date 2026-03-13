# LaukAI

> AI-powered billing system for Malaysian mixed-rice (_nasi campur_) restaurants.

LaukAI uses computer vision to automatically detect food items on a plate, map them to a restaurant's menu, and generate an itemised bill — replacing manual counting and pricing.

## Architecture

```
┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
│  Mobile App      │─────▶│  Backend API     │─────▶│  AI Service      │
│  (Flutter)       │◀─────│  (Express/Node)  │◀─────│  (FastAPI/YOLO)  │
└─────────────────┘      └────────┬────────┘      └─────────────────┘
                                  │
                          ┌───────▼───────┐
                          │  PostgreSQL    │
                          └───────────────┘
```

| Service | Description | Port |
|---------|-------------|------|
| **ai-service** | YOLOv8 food detection microservice | `8000` |
| **backend** | REST API — auth, menus, billing, restaurant management | `3000` |
| **frontend/mobile** | Flutter app for staff and customers | — |
| **frontend/web** | React web app (development / testing) | `5173` |

## Features

- **AI Food Detection** — Snap a photo; YOLOv8 identifies Chicken, Egg, Fish, Rice, Sauce, and Vegetables
- **Automated Billing** — Detected items are mapped to menu prices and an itemised bill is generated
- **Dashboard & Stats** — Daily revenue, bill count, average order value, and detection accuracy
- **Transaction History** — Browse, view, and void past transactions
- **Menu Management** — Add, edit, toggle, and delete menu items with YOLO class mapping
- **Restaurant Profile** — Manage name, address, business hours, and profile image
- **Multi-Tenancy** — Each restaurant sees only its own data; owner and staff roles
- **Authentication** — JWT-based auth with Passport.js (Local + JWT strategies)
- **Tax Support** — Configurable SST and service charge rates per restaurant

## Getting Started

### Prerequisites

| Requirement | Version |
|-------------|---------|
| Node.js | ≥ 18 |
| PostgreSQL | ≥ 14 |
| Python | ≥ 3.9 |
| Flutter SDK | ≥ 3.x |

### 1. Environment

Copy the example env file and fill in your credentials:

```bash
cp .env.example .env
```

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | PostgreSQL connection string |
| `JWT_SECRET` | Secret for signing JWT tokens |
| `CLOUDINARY_CLOUD_NAME` | Cloudinary cloud name |
| `CLOUDINARY_API_KEY` | Cloudinary API key |
| `CLOUDINARY_API_SECRET` | Cloudinary API secret |

### 2. Database

```bash
psql -U postgres -c "CREATE DATABASE laukai;"
psql -U postgres -d laukai -f backend/db/init.sql
psql -U postgres -d laukai -f backend/db/seed.sql   # optional demo data
```

### 3. AI Service

```bash
cd ai-service
pip install -r requirements.txt
python train.py                          # one-time model training
python -m uvicorn app.main:app --reload --port 8000
```

### 4. Backend

```bash
cd backend
npm install
npm run dev
```

### 5. Mobile App

```bash
cd frontend/mobile
flutter pub get
flutter run
```

> See each service's own README for detailed setup and API documentation.

## Project Structure

```
lauk-ai/
├── ai-service/          # FastAPI + YOLOv8 food detection
│   ├── app/
│   ├── train.py
│   └── README.md
├── backend/             # Express REST API
│   ├── db/              # Schema & seed SQL
│   ├── middleware/       # Auth, Passport, file uploads
│   ├── routes/          # Route handlers
│   ├── server.js
│   └── README.md
├── frontend/
│   ├── mobile/          # Flutter app (primary client)
│   │   ├── lib/
│   │   └── README.md
│   └── web/             # React web app (dev/test)
├── .env.example
├── .gitignore
└── README.md            ← you are here
```

## Seed Data

The `seed.sql` file creates a demo restaurant called **Warung Test** pre-loaded with:

- Restaurant profile (KL address, business hours, SST @ 6%)
- 1 owner + 2 staff accounts (password: `Pa$$w0rd`)
- 6 menu items (one per YOLO class)
- 20 transactions spanning 7 days
