import sys, json
from PIL import Image
from transformers import BlipProcessor, BlipForConditionalGeneration

processor = BlipProcessor.from_pretrained("Salesforce/blip-image-captioning-base", use_fast=True)
model = BlipForConditionalGeneration.from_pretrained("Salesforce/blip-image-captioning-base")


print("Child ready.")
sys.stdout.flush()

try:
    for line in sys.stdin:
        task = json.loads(line)
        id = task.get("id")

        img_url = task.get("path")
        raw_image = Image.open(img_url).convert('RGB')
        
        inputs = processor(raw_image, return_tensors="pt")
        out = model.generate(**inputs)
        result = processor.decode(out[0], skip_special_tokens=True)

        # Response based on task
        result = { "media_id": id, "caption": result }
        
        print(json.dumps(result))
        sys.stdout.flush()

except json.JSONDecodeError:
    print("Invalid JSON received")
    sys.stdout.flush()
