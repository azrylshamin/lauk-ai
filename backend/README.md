# Backend — Express REST API

Node.js REST API that powers the LaukAI platform. Handles authentication, restaurant management, menu items, billing, employee management, and proxies image predictions to the AI service.

## Tech Stack

| Layer | Technology |
|-------|------------|
| Runtime | Node.js |
| Framework | Express 5 |
| Database | PostgreSQL (`pg`) |
| Auth | Passport.js (Local + JWT strategies), bcrypt |
| File uploads | Multer → Cloudinary |
| AI proxy | Forwards images to the FastAPI ai-service |

## Quick Start

### Prerequisites

- **Node.js** ≥ 18
- **PostgreSQL** running locally (default port 5432)
- A `.env` file in the **project root** (see `.env.example`)

### Setup

```bash
# Install dependencies
npm install

# Create the database
psql -U postgres -c "CREATE DATABASE laukai;"

# Run schema migration
psql -U postgres -d laukai -f db/init.sql

# (Optional) Seed demo data
psql -U postgres -d laukai -f db/seed.sql

# Start the dev server (auto-restart on file changes)
npm run dev
```

The server starts at **http://localhost:3000**.

## Environment Variables

Configured in `.env` at the project root:

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgres://postgres:password@localhost:5432/laukai` |
| `JWT_SECRET` | Secret for signing JWT tokens | `change-me-to-a-random-secret` |
| `CLOUDINARY_CLOUD_NAME` | Cloudinary cloud name | `your-cloud-name` |
| `CLOUDINARY_API_KEY` | Cloudinary API key | `your-api-key` |
| `CLOUDINARY_API_SECRET` | Cloudinary API secret | `your-api-secret` |
| `AI_SERVICE_URL` | URL of the AI service | `http://localhost:8000` (default) |
| `PORT` | Server port | `3000` (default) |

## API Routes

### Public

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/health` | Health check |
| `POST` | `/api/auth/register` | Register a new owner + restaurant |
| `POST` | `/api/auth/login` | Login, returns JWT |
| `POST` | `/api/customer/predict` | Public prediction for customer-facing scan |

### Protected (JWT required)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/predict` | Predict food items from an uploaded image |
| `GET` | `/api/menu-items` | List menu items for the restaurant |
| `POST` | `/api/menu-items` | Create a menu item |
| `PATCH` | `/api/menu-items/:id` | Update a menu item |
| `DELETE` | `/api/menu-items/:id` | Delete a menu item |
| `GET` | `/api/bills` | List bills (with query filters) |
| `GET` | `/api/bills/stats` | Dashboard statistics |
| `GET` | `/api/bills/:id` | Get a single bill with items |
| `POST` | `/api/bills` | Create a bill with items |
| `DELETE` | `/api/bills/:id` | Void (delete) a bill |
| `GET` | `/api/restaurant` | Get restaurant profile |
| `PATCH` | `/api/restaurant` | Update restaurant profile (owner) |
| `POST` | `/api/restaurant/image` | Upload restaurant image (owner) |
| `DELETE` | `/api/restaurant/image` | Remove restaurant image (owner) |
| `GET` | `/api/employees` | List employees |
| `POST` | `/api/employees` | Invite a staff member (owner) |
| `DELETE` | `/api/employees/:id` | Remove a staff member (owner) |

## Project Structure

```
backend/
├── db/
│   ├── db.js                # PostgreSQL connection pool
│   ├── init.sql             # Schema migration
│   └── seed.sql             # Demo seed data (Warung Test)
├── helpers/
│   └── lookupMenuItems.js   # Maps YOLO detections → menu items
├── middleware/
│   ├── auth.js              # JWT authenticate & requireOwner guards
│   ├── passport.js          # Passport Local + JWT strategies
│   └── upload.js            # Multer + Cloudinary upload config
├── routes/
│   ├── auth.js              # Register / login
│   ├── bills.js             # CRUD + stats
│   ├── customer.js          # Public customer-facing predict
│   ├── employees.js         # Employee management
│   ├── health.js            # Health check
│   ├── menuItems.js         # Menu CRUD
│   ├── predict.js           # AI prediction proxy
│   └── restaurant.js        # Restaurant profile
├── server.js                # Express app entry point
└── package.json
```

## Database

The schema is defined in `db/init.sql` and covers five tables:

| Table | Purpose |
|-------|---------|
| `restaurants` | Restaurant profiles (name, address, hours, tax settings) |
| `users` | Owner and staff accounts, scoped to a restaurant |
| `menu_items` | Per-restaurant menu, mapped to YOLO detection classes |
| `bills` | Transaction records with subtotal, SST, service charge |
| `bill_items` | Itemized line-items for each bill |

### Seed Data

Run `db/seed.sql` to populate a demo restaurant ("Warung Test") with an owner, staff accounts, menu items, and 20 historical transactions spanning 7 days.
