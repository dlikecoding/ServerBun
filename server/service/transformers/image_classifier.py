import argparse
import json
from transformers import pipeline
from PIL import Image

def load_classifier(model_path: str):
    return pipeline(
        "image-classification",
        model=model_path,
        feature_extractor=model_path,
        use_fast=True
    )

def classify_images(image_objects, model_path):
    classifier = load_classifier(model_path)

    for idx, obj in enumerate(image_objects):
        image_id = obj.get("id", f"Image {idx + 1}")
        path = obj.get("path")
        if not path:
            print(f"[{image_id}] Skipped: No path provided.")
            continue

        try:
            img = Image.open(path)
        except Exception as e:
            print(f"[{image_id}] Failed to open image '{path}': {e}")
            continue

        predictions = classifier(img)

        print(f"[{image_id}] Path: {path}")
        for result in predictions:
            if result["score"] >= 0.5:
                print(f"  Label: {result['label']}, Score: {round(result['score'], 4)}")
        print("-" * 50)

def main():
    parser = argparse.ArgumentParser(
        description="Run image classification on a list of image objects with 'id' and 'path'."
    )
    parser.add_argument(
        "--images",
        type=str,
        required=True,
        help="JSON string representing an array of image objects, e.g. '[{\"id\": \"img1\", \"path\": \"./abc.webp\"}]'"
    )
    parser.add_argument(
        "--model",
        type=str,
        required=True,
        help="Path to the model."
    )
   
    args = parser.parse_args()

    try:
        image_objects = json.loads(args.images)
        if not isinstance(image_objects, list):
            raise ValueError("The --images parameter must be a JSON array of objects.")
    except Exception as e:
        print(f"Error parsing --images: {e}")
        return

    classify_images(image_objects, args.model)

if __name__ == "__main__":
    main()
