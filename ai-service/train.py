"""
Training script for the YOLOv8 food detection model.

Usage:
    cd ai-service
    python train.py

This will train a YOLOv8n model on the dataset in assets/Mix rice.v4i.yolov8/
and save the best weights to models/best.pt.
"""

import os
from pathlib import Path
from ultralytics import YOLO


def train():
    # Paths
    base_dir = Path(__file__).resolve().parent
    dataset_dir = base_dir / "assets" / "Mix rice.v4i.yolov8"
    data_yaml = dataset_dir / "data.yaml"
    output_dir = base_dir / "models"

    # Ensure output directory exists
    output_dir.mkdir(parents=True, exist_ok=True)

    if not data_yaml.exists():
        raise FileNotFoundError(
            f"Dataset config not found at {data_yaml}. "
            "Make sure the dataset is in assets/Mix rice.v4i.yolov8/"
        )

    print(f"📦 Dataset config : {data_yaml}")
    print(f"📂 Output directory: {output_dir}")
    print("🚀 Starting training...\n")

    # Load a pre-trained YOLOv8 nano model as the starting point
    model = YOLO("yolov8n.pt")

    # Train on the food dataset
    results = model.train(
        data=str(data_yaml),
        epochs=50,
        imgsz=640,
        batch=16,
        name="lauk-ai",
        project=str(output_dir),
        exist_ok=True,
        patience=10,
        verbose=True,
    )

    # Copy best weights to models/best.pt for easy access
    best_weights = output_dir / "lauk-ai" / "weights" / "best.pt"
    final_path = output_dir / "best.pt"

    if best_weights.exists():
        import shutil
        shutil.copy2(best_weights, final_path)
        print(f"\n✅ Training complete! Best weights saved to: {final_path}")
    else:
        print("\n⚠️  Training completed but best.pt not found at expected path.")
        print(f"   Check {output_dir / 'lauk-ai'} for results.")

    return results


if __name__ == "__main__":
    train()
