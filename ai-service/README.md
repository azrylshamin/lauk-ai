# AI Service — Food Detection API

FastAPI microservice that detects food items in mixed-rice dish images using YOLOv8.

**Detectable classes:** Chicken, Egg, Fish, Rice, Sauce, Vegetables

## Quick Start

```bash
# Install dependencies
pip install -r requirements.txt

# Train the model (one-time, requires dataset in assets/)
python train.py

# Start the server
python -m uvicorn app.main:app --reload --port 8000
```

Swagger UI: [http://localhost:8000/docs](http://localhost:8000/docs)

## API Endpoints

### `GET /health`

Health check and model status.

**Response:**

```json
{
  "status": "healthy",
  "model_loaded": true
}
```

---

### `GET /classes`

Returns all detectable food classes.

**Response:**

```json
{
  "classes": ["Chicken", "Egg", "Fish", "Rice", "Sauce", "Vegetables"],
  "count": 6
}
```

---

### `POST /predict`

Upload an image to detect food items.

**Parameters:**

| Name | Type | In | Default | Description |
|------|------|----|---------|-------------|
| `file` | file | form-data | *(required)* | Image file (JPEG, PNG, etc.) |
| `confidence` | float | query | `0.25` | Minimum confidence threshold (0–1) |

**Example request (cURL):**

```bash
curl -X POST "http://localhost:8000/predict?confidence=0.3" \
  -F "file=@photo.jpg"
```

**Response:**

```json
{
  "detections": [
    {
      "class": "Rice",
      "confidence": 0.9512,
      "bbox": { "x1": 120.5, "y1": 80.3, "x2": 450.2, "y2": 390.1 }
    },
    {
      "class": "Chicken",
      "confidence": 0.8734,
      "bbox": { "x1": 200.0, "y1": 150.0, "x2": 350.0, "y2": 300.0 }
    }
  ],
  "count": 2,
  "image_size": { "width": 640, "height": 640 }
}
```

**Error responses:**

| Status | Reason |
|--------|--------|
| `400` | Invalid file type or unreadable image |
| `503` | Model not loaded — run `python train.py` first |

## Project Structure

```
ai-service/
├── app/
│   ├── __init__.py
│   └── main.py          # FastAPI application
├── assets/
│   └── Mix rice.v4i.yolov8/  # YOLOv8 dataset (gitignored)
├── models/              # Trained weights (gitignored)
│   └── best.pt
├── train.py             # Model training script
├── requirements.txt
└── README.md
```

## Training

The training script fine-tunes **YOLOv8n** (nano) on the dataset:

```bash
python train.py
```

- **Epochs:** 50 (with early stopping, patience=10)
- **Image size:** 640×640
- **Output:** `models/best.pt`

To retrain with new data, add labeled images to the dataset folder and re-run the script.
