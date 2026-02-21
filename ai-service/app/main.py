"""
FastAPI application for food detection using YOLOv8.

Usage:
    cd ai-service
    uvicorn app.main:app --reload --port 8000

Swagger UI available at: http://localhost:8000/docs
"""

import io
from pathlib import Path
from contextlib import asynccontextmanager

from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image
from ultralytics import YOLO


# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
BASE_DIR = Path(__file__).resolve().parent.parent
MODEL_PATH = BASE_DIR / "models" / "best.pt"
CLASS_NAMES = ["Chicken", "Egg", "Fish", "Rice", "Sauce", "Vegetables"]

# Global reference to the loaded model
model: YOLO | None = None


# ---------------------------------------------------------------------------
# Lifespan (startup / shutdown)
# ---------------------------------------------------------------------------
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Load the YOLOv8 model once at startup."""
    global model

    if MODEL_PATH.exists():
        print(f"✅ Loading model from {MODEL_PATH}")
        model = YOLO(str(MODEL_PATH))
    else:
        print(
            f"⚠️  Model not found at {MODEL_PATH}. "
            "Run 'python train.py' first to train the model.\n"
            "The /predict endpoint will return an error until a model is available."
        )
        model = None

    yield  # app is running

    # Cleanup (nothing needed for now)
    model = None


# ---------------------------------------------------------------------------
# App
# ---------------------------------------------------------------------------
app = FastAPI(
    title="LaukAI — Food Detection API",
    description=(
        "Detects food items in mixed‑rice dishes using YOLOv8. "
        "Upload an image to the /predict endpoint to get detections."
    ),
    version="1.0.0",
    lifespan=lifespan,
)

# CORS — allow all origins for development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------
@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "model_loaded": model is not None,
    }


@app.get("/classes")
async def get_classes():
    """Return the list of detectable food classes."""
    return {
        "classes": CLASS_NAMES,
        "count": len(CLASS_NAMES),
    }


@app.post("/predict")
async def predict(file: UploadFile = File(...), confidence: float = 0.25):
    """
    Run food detection on an uploaded image.

    - **file**: Image file (JPEG, PNG, etc.)
    - **confidence**: Minimum confidence threshold (0‑1, default 0.25)

    Returns a list of detected food items with bounding boxes and confidence.
    """
    if model is None:
        raise HTTPException(
            status_code=503,
            detail=(
                "Model not loaded. Train the model first by running: "
                "python train.py"
            ),
        )

    # Validate file type
    if file.content_type and not file.content_type.startswith("image/"):
        raise HTTPException(
            status_code=400,
            detail=f"File must be an image, got {file.content_type}",
        )

    try:
        # Read and open the image
        contents = await file.read()
        image = Image.open(io.BytesIO(contents)).convert("RGB")
    except Exception as exc:
        raise HTTPException(
            status_code=400,
            detail=f"Could not read the image: {exc}",
        )

    # Run inference
    results = model.predict(source=image, conf=confidence, verbose=False)

    # Parse detections
    detections = []
    for result in results:
        for box in result.boxes:
            x1, y1, x2, y2 = box.xyxy[0].tolist()
            detections.append(
                {
                    "class": CLASS_NAMES[int(box.cls[0])],
                    "confidence": round(float(box.conf[0]), 4),
                    "bbox": {
                        "x1": round(x1, 2),
                        "y1": round(y1, 2),
                        "x2": round(x2, 2),
                        "y2": round(y2, 2),
                    },
                }
            )

    return {
        "detections": detections,
        "count": len(detections),
        "image_size": {"width": image.width, "height": image.height},
    }
