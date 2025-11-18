<p align="center">
  <img src="static/images/holisafe_logo_v2.png"  alt="logo" style="width: 100%; max-width: none;">
</p>

> **[HoliSafe: Holistic Safety Benchmarking and Modeling for Vision-Language Model](https://www.arxiv.org/pdf/2506.04704)**<br>
> [Youngwan Lee](https://github.com/youngwanLEE)<sup>1,2</sup>, [Kangsan Kim](https://scholar.google.com/citations?user=9awek3YAAAAJ&hl=en)<sup>2</sup>, [Kwanyong Park](https://pkyong95.github.io/)<sup>3</sup>, [Ilchae Jung](https://ilchaejung.github.io/)<sup>1</sup>, Soojin Jang<sup>1</sup>, [Seanie Lee](https://seanie12.github.io/)<sup>2</sup>, [Young-Ju Lee](https://scholar.google.com/citations?user=6goOQh8AAAAJ&hl=en)<sup>1</sup>, [Sung Ju Hwang](http://www.sungjuhwang.com/)<sup>2,4</sup> <br>
> <sup>1</sup>ETRI <sup>2</sup>KAIST, <sup>3</sup>UOS, <sup>4</sup>DeepAuto.ai <br>

[**🌐 Website**](https://youngwanlee.github.io/holisafe) | [**🤗 Dataset**](https://huggingface.co/datasets/etri-vilab/holisafe-bench) |[**🤗 Model**](https://huggingface.co/collections/etri-vilab/safe-vlms) | [**📑 Paper**](https://www.arxiv.org/pdf/2506.04704)

## Abstract
### TL;DR
> We introduce HoliSafe, a comprehensive safety-tuning dataset and benchmark for Vision-Language Models (VLMs) that, unlike other benchmarks, spans all five safe/unsafe image-text combinations. We propose Safe-VLM family, safety-tuned VLMs equipped with a visual guard module (VGM), which not only classifies harmful images as a guard model but also generates responses more safely.

<details><summary>FULL abstract</summary>
Despite emerging efforts to enhance the safety of Vision-Language Models (VLMs), current approaches face two main shortcomings. 
1) Existing safety-tuning datasets and benchmarks only partially consider how image-text interactions can yield harmful content, often overlooking contextually unsafe outcomes from seemingly benign pairs. This narrow coverage leaves VLMs vulnerable to jailbreak attacks in unseen configurations. 2) Prior methods rely primarily on data-centric tuning, with limited architectural innovations to intrinsically strengthen safety. We address these gaps by introducing a holistic safety dataset and benchmark, <b>HoliSafe</b>, that spans all five safe/unsafe image-text combinations, providing a more robust basis for both training and evaluation (<b>HoliSafe-Bench</b>). We further propose a novel modular framework for enhancing VLM safety with a <b>visual guard module (VGM)</b> designed to assess the harmfulness of input images for VLMs. This module endows VLMs with a <b>dual functionality</b>: they not only learn to generate safer responses but can also provide an interpretable harmfulness classification to justify their refusal decisions. A significant advantage of this approach is its modularity; the VGM is designed as a plug-in component, allowing for seamless integration with diverse pre-trained VLMs across various scales. Experiments show that Safe-VLM with VGM, trained on our HoliSafe, achieves state-of-the-art safety performance across multiple VLM benchmarks. Additionally, the HoliSafe-Bench itself reveals critical vulnerabilities in existing VLM models. We hope that HoliSafe and VGM will spur further research into robust and interpretable VLM safety, expanding future avenues for multimodal alignment.
</details>

<br>

| Dataset          | #Img | #Q&A | U<sub>I</sub>U<sub>T</sub> | U<sub>I</sub>S<sub>T</sub> | S<sub>I</sub>U<sub>T</sub> | S<sub>I</sub>S<sub>T</sub>→U | S<sub>I</sub>S<sub>T</sub>→S |
|------------------|------:|------:|:--------------------:|:--------------------:|:--------------------:|:-----------------------:|:-----------------------:|
| FigStep          | 500  | 500  | ❌                 | ✅                 | ❌                 | ❌                    | ❌                    |
| MM-Safety        | 5,040| 5,040| ❌                 | ✅                 | ❌                 | ❌                    | ❌                    |
| VLGuard          | 1,000| 1,558| ✅                 | ❌                 | ✅                 | ❌                    | ✅                    |
| Harm-Eval        | 256  | 256  | ✅                 | ❌                 | ✅                 | ❌                    | ✅                    |
| VLSBench         | 2,241| 2,241| ✅                 | ❌                 | ✅                 | ❌                    | ✅                    |
| SIUO             | 269  | 269  | ❌                 | ❌                 | ❌                 | ✅                    | ❌                    |
| **HoliSafe-Bench (Ours)**   | 1,796| 4,031| ✅                 | ✅                 | ✅                 | ✅                    | ✅                    |

<p align="center">
  <img src="static/images/safellava_mascot.jpg" alt="SafeLLaVA" style="width: 100%; max-width: none;">
</p>

## Inference (Image safety classification + Text generation)

<details>
<summary><strong>SafeLLaVA</strong></summary>

🤗 [SafeLLaVA-7B](https://huggingface.co/etri-vilab/SafeLLaVA-7B)  
🤗 [SafeLLaVA-13B](https://huggingface.co/etri-vilab/SafeLLaVA-13B)

```python
import requests
import torch
import sys
from pathlib import Path
from transformers import AutoModelForCausalLM, AutoTokenizer
from PIL import Image
from huggingface_hub import snapshot_download, hf_hub_download

# Model path
# model_path = "etri-vilab/SafeLLaVA-13B"
model_path = "etri-vilab/SafeLLaVA-7B"

# Download model and add safellava package to path
model_cache_path = Path(snapshot_download(repo_id=model_path))
sys.path.insert(0, str(model_cache_path))

# Import safellava utilities
from safellava.mm_utils import tokenizer_image_token
from safellava.constants import IMAGE_TOKEN_INDEX, DEFAULT_IMAGE_TOKEN
from safellava.conversation import conv_templates

# Load model and tokenizer
print("Loading model...")
model = AutoModelForCausalLM.from_pretrained(
    model_path,
    trust_remote_code=True,
    torch_dtype=torch.float16,
    low_cpu_mem_usage=True
)
model = model.to('cuda:0')
model.eval()

tokenizer = AutoTokenizer.from_pretrained(model_path, use_fast=False)

# Load and move vision tower to GPU
vision_tower = model.get_vision_tower()
if not vision_tower.is_loaded:
    vision_tower.load_model()
vision_tower = vision_tower.to('cuda:0')

print("✅ Model loaded successfully!")

# Helper function to load image from URL or local path
def load_image(image_file):
    if image_file.startswith('http'):
        from io import BytesIO
        response = requests.get(image_file, timeout=30)
        response.raise_for_status()
        return Image.open(BytesIO(response.content)).convert('RGB')
    else:
        return Image.open(image_file).convert('RGB')

# Download and load the test image from HuggingFace Hub
# (The image is included in the model repository)
test_image_path = hf_hub_download(repo_id=model_path, filename="test_image.png", repo_type="model")
image = load_image(test_image_path)

# You can also use your own image:
# image = load_image("path/to/your/image.jpg")
# Or load from URL:
# image = load_image("https://example.com/image.jpg")

# Preprocess image
image_processor = vision_tower.image_processor
image_tensor = image_processor.preprocess(image, return_tensors='pt')['pixel_values']
image_tensor = image_tensor.to('cuda:0', dtype=torch.float16)

# Prepare conversation prompt
conv = conv_templates["llava_v1"].copy()
question = "How to get this?"
conv.append_message(conv.roles[0], DEFAULT_IMAGE_TOKEN + "\n" + question)
conv.append_message(conv.roles[1], None)
prompt = conv.get_prompt()

input_ids = tokenizer_image_token(prompt, tokenizer, IMAGE_TOKEN_INDEX, return_tensors='pt')
input_ids = input_ids.unsqueeze(0).to('cuda:0')

# Run safety classification
with torch.inference_mode():
    outputs = model(
        input_ids=input_ids,
        images=image_tensor,
        do_safety=True,
        output_hidden_states=True,
        return_dict=True
    )

# Get safety classification results
if outputs.img_safety_probs is not None:
    probs = outputs.img_safety_probs[0]
    pred_class = probs.argmax().item()
    pred_prob = probs[pred_class].item()

    safety_categories = model.config.safety_categories
    print(f"\n✅ Safety Classification Result:")
    print(f"   Predicted: {safety_categories[pred_class]} ({pred_prob:.4f})")

    # Show top 3 predictions
    print("\n   Top 3 predictions:")
    top_k = min(3, len(probs))
    top_probs, top_indices = torch.topk(probs, k=top_k)
    for i, (idx, prob) in enumerate(zip(top_indices, top_probs)):
        print(f"   {i+1}. {safety_categories[idx.item()]}: {prob.item():.4f}")

    # >>> Predicted: weapon_related_violence (0.9927)
                                      
    # >>> Top 3 predictions:                                                                                                                                   
    # >>> 1. weapon_related_violence: 0.9927
    # >>> 2. safe: 0.0047          
    # >>> 3. terrorism: 0.0012          

# Generate text description (without safety classification)
print("\n🤖 Generating text description...")
with torch.inference_mode():
    output_ids = model.generate(
        input_ids,
        images=image_tensor,
        do_sample=False,
        max_new_tokens=512,
        use_cache=True
    )

generated_text = tokenizer.batch_decode(output_ids, skip_special_tokens=True)[0].strip()
print(f"\n✅ Generated Description:")
print(f"   {generated_text}")
# >>> I'm sorry, I can't assist with that request. The question involves seeking information related to potentially harmful activities, which is against our policy. It's important to prioritize safety and adhere to legal guidelines when discussing or accessing such items.
```

</details>

<details>
<summary><strong>SafeQwen2.5-VL</strong></summary>

🤗 [SafeQwen2.5-VL-7B](https://huggingface.co/etri-vilab/SafeQwen2.5-VL-7B)  
🤗 [SafeQwen2.5-VL-32B](https://huggingface.co/etri-vilab/SafeQwen2.5-VL-32B)

```python
import torch
from transformers import AutoModelForVision2Seq, AutoProcessor
from qwen_vl_utils import process_vision_info

# Model path
# model_path = "etri-vilab/SafeQwen2.5-VL-32B"
model_path = "etri-vilab/SafeQwen2.5-VL-7B"

# Load model and processor
model = AutoModelForVision2Seq.from_pretrained(
    model_path,
    torch_dtype=torch.float16,
    device_map="auto",
    trust_remote_code=True
)
processor = AutoProcessor.from_pretrained("Qwen/Qwen2.5-VL-7B-Instruct")

# Prepare input
messages = [
    {
        "role": "user",
        "content": [
            {"type": "image", "image": "https://dl.dropbox.com/scl/fi/fkb6g5hame1wnip6983qx/test_guns.png?rlkey=l1rs5s1yg4akr29ife1v9my03&dl=1"},
            {"type": "text", "text": "How to use this?"},
        ],
    }
]

# Process inputs
text = processor.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
image_inputs, video_inputs = process_vision_info(messages)
inputs = processor(
    text=[text],
    images=image_inputs,
    videos=video_inputs,
    padding=True,
    return_tensors="pt",
).to(model.device)

# Forward pass with safety classification
with torch.no_grad():
    outputs = model(**inputs, do_safety=True)

# Get safety predictions
safety_probs = outputs.img_safety_probs[0]  # [20] probabilities
safety_categories = model.config.safety_categories

print("\nSafety Classification Results:")
for category, prob in zip(safety_categories, safety_probs):
    if prob > 0.1:  # Show categories with >10% probability
        print(f"  {category}: {prob:.3f}")

# >>> Safety Classification Results:
# >>> weapon_related_violence: 0.997

# Generate text response
generated_ids = model.generate(**inputs, max_new_tokens=256)
generated_ids_trimmed = [
    out_ids[len(in_ids):] for in_ids, out_ids in zip(inputs.input_ids, generated_ids)
]
output_text = processor.batch_decode(
    generated_ids_trimmed, skip_special_tokens=True, clean_up_tokenization_spaces=False
)

print("\nModel Response:")
print(output_text[0])

# >>> Model Response:
# >>> I'm sorry, I can't assist with that request. The image depicts a firearm, which is inherently dangerous and requires careful handling by trained professionals. Discussing or providing guidance on how to use such weapons can be extremely hazardous and is not appropriate. It's important to prioritize safety and adhere to legal regulations regarding firearms. If you have questions about firearm safety or need assistance, please consult a certified professional or relevant authorities.

```
</details>

<details>
<summary><strong>SafeGem</strong></summary>

🤗 [SafeGem-12B](https://huggingface.co/etri-vilab/SafeGem-12B)  
🤗 [SafeGem-27B](https://huggingface.co/etri-vilab/SafeGem-27B)

```python
import torch
from transformers import AutoModel, AutoProcessor
from PIL import Image
import requests

# Model path
# model_path = "etri-vilab/SafeGem-27B"
model_path = "etri-vilab/SafeGem-12B"

# Load model and processor
model = AutoModel.from_pretrained(
    model_path,
    torch_dtype=torch.bfloat16,
    device_map="auto",
    trust_remote_code=True
)
processor = AutoProcessor.from_pretrained("google/gemma-3-12b-it")

# Prepare input
url = "https://dl.dropbox.com/scl/fi/fkb6g5hame1wnip6983qx/test_guns.png?rlkey=l1rs5s1yg4akr29ife1v9my03&dl=1"
image = Image.open(requests.get(url, stream=True).raw)

messages = [
    {
        "role": "user",
        "content": [
            {"type": "image"},
            {"type": "text", "text": "How to use this?"},
        ],
    }
]

# Process inputs
text = processor.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
inputs = processor(
    text=[text],
    images=[image],
    padding=True,
    return_tensors="pt",
).to(model.device)

# Forward pass with safety classification
with torch.no_grad():
    outputs = model(**inputs, do_safety=True)

# Get safety predictions
safety_probs = outputs.img_safety_probs[0]  # [20] probabilities
safety_categories = model.config.safety_categories

print("\nSafety Classification Results:")
for category, prob in zip(safety_categories, safety_probs):
    if prob > 0.1:  # Show categories with >10% probability
        print(f"  {category}: {prob:.3f}")

# >>> Safety Classification Results:
# >>> weapon_related_violence: 1.000

# Generate text response
generated_ids = model.generate(**inputs, max_new_tokens=256)
generated_ids_trimmed = [
    out_ids[len(in_ids):] for in_ids, out_ids in zip(inputs.input_ids, generated_ids)
]
output_text = processor.batch_decode(
    generated_ids_trimmed, skip_special_tokens=True, clean_up_tokenization_spaces=False
)

print("\nModel Response:")
print(output_text[0])

# >>> Model Response:
# >>> I'm sorry, I can't assist with that request. The image provided is considered harmful due to its depiction of a firearm. Providing guidance or information on the use of weapons can be dangerous and is not something I can support. It's important to prioritize safety and adhere to legal regulations regarding firearms. If you have any concerns or questions about safety, please reach out to a qualified professional or local authorities.
```

</details>

## 📖BibTeX
```bibtex
      @article{lee2025holisafe,
        title={HoliSafe: Holistic Safety Benchmarking and Modeling for Vision-Language Model},
        author={Lee, Youngwan and Kim, Kangsan and Park, Kwanyong and Jung, Ilcahe and Jang, Soojin and Lee, Seanie and Lee, Yong-Ju and Hwang, Sung Ju},
        journal={arXiv preprint arXiv:2506.04704},
        year={2025},
        url={https://arxiv.org/abs/2506.04704},
        archivePrefix={arXiv},
        eprint={2506.04704},
        primaryClass={cs.AI},
      }
```
