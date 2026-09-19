# Asan Kissan: Robust Edge-AI for Explainable Maize Leaf Disease Diagnosis

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform: Flutter](https://img.shields.io/badge/Platform-Flutter-02569B?logo=flutter)](https://flutter.dev)
[![Model: ONNX Runtime](https://img.shields.io/badge/Inference-ONNX%20Runtime-005CED)](https://onnxruntime.ai)
[![Author ORCID](https://img.shields.io/badge/ORCID-0009--0001--4570--1500-A6CE39?logo=orcid)](https://orcid.org/0009-0001-4570-1500)

An edge-native, explainable deep learning framework for real-time maize foliar pathology diagnosis on resource-constrained mobile hardware. Powered by a quantized hybrid CNN-Transformer architecture (EfficientNet-B0 + DeiT-Tiny) with embedded on-device Grad-CAM heatmaps.

---

## Key Highlights

- **Hybrid Backbone:** Dual-stream fusion combining EfficientNet-B0 local inductive bias with DeiT-Tiny global self-attention context (1472-d fused bottleneck).
- **INT8 Dynamic Quantization:** Model storage compressed by **42.48%** (37.96 MB $\to$ 21.84 MB) with **48.04 ms** mobile CPU latency (1.3x speedup).
- **Embedded XAI:** Real-time on-device Grad-CAM lesion heatmaps computed in a single forward pass alongside classification logits.
- **100% Offline Mobile Client:** Flutter application integrating native C++ ONNX Runtime bindings, multi-region canopy cropping, and multi-lingual voice guidance.
- **Accuracy:** **98.75%** test classification accuracy evaluated across multi-domain field benchmarks (PlantVillage, Ndisan, PlantDoc).

---

## Hardware Benchmark (Edge Deployment)

- **Target Device:** Xiaomi Redmi Note 10 (Snapdragon 678, 4 GB RAM, Android 12)
- **Quantized Model Size:** 21.84 MB
- **Inference Latency:** 48.04 ms per frame
- **Network Overhead:** 0 KB (Zero cloud dependencies)

---

## Repository Structure

- `/model_pipeline`: PyTorch model definition, dynamic post-training quantization scripts, and ONNX graph export.
- `/mobile_app`: Production-ready Flutter codebase for the Asan Kissan offline mobile assistant.
- `/assets`: Visual heatmaps, architectural diagrams, and UI walk-throughs.

---

## Citation

If you find this work useful in your research, please cite our pre-print:

```bibtex
@article{raza2026robust,
  title={Robust Edge-AI for Explainable Maize Leaf Disease Diagnosis via Quantized CNN-Transformer Fusion},
  author={Raza, Muhammad Muslim},
  journal={arXiv preprint},
  year={2026}
}
