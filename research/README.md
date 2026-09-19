# 🔬 Asan Kissan Research & Model Training Hub

[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/drive/1DUEpGQ3eMpk9TuHKlW_rXVZaormiWtOx)
[![PyTorch](https://img.shields.io/badge/PyTorch-2.x-EE4C2C?logo=pytorch)](https://pytorch.org)
[![ONNX Runtime](https://img.shields.io/badge/ONNX_Runtime-INT8_Quantized-005CED?logo=onnx)](https://onnxruntime.ai)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](../LICENSE)

This directory contains the complete research pipeline, model architecture, training scripts, evaluation benchmarks, and quantization workflows accompanying the paper:
> **"Robust Edge-AI for Explainable Maize Leaf Disease Diagnosis via Quantized CNN-Transformer Fusion"**  
> *Muhammad Muslim Raza, Department of Computer Science, COMSATS University Islamabad, Vehari Campus.*

---

## ⚡ 1-Click Interactive Google Colab Notebook

You can run the end-to-end multi-domain dataset ingestion, model training, Grad-CAM generation, and INT8 quantization directly in Google Colab with GPU acceleration:

👉 **[Open Training Notebook in Google Colab](https://colab.research.google.com/drive/1DUEpGQ3eMpk9TuHKlW_rXVZaormiWtOx)**

Alternatively, the self-contained offline Jupyter notebook is stored locally at:
[`research/notebooks/Asan_Kissan_Training_and_Quantization.ipynb`](./notebooks/Asan_Kissan_Training_and_Quantization.ipynb).

---

## 🏗️ Architecture Overview

The `HybridCornNet` architecture synergistically fuses:
1. **Local Inductive Bias**: `EfficientNet-B0` extracting $1280$-dimensional fine-grained spatial feature maps.
2. **Global Self-Attention Context**: `DeiT-Tiny` (`deit_tiny_patch16_224`) extracting a $192$-dimensional global class token.
3. **Concatenated Projection Bottleneck**: Channel concatenation ($1280 + 192 = 1472$) followed by `Linear(1472, 256) -> BatchNorm1d(256) -> GELU() -> Dropout(0.40) -> Linear(256, 4)`.
4. **Dual-Output Graph**: Real-time simultaneous computation of disease classification logits and 224x224 Grad-CAM activation heatmaps.

```
Input Image (3 x 224 x 224)
        │
   ┌────┴──────────────────────────┐
   ▼                               ▼
EfficientNet-B0 (Stage 7)     DeiT-Tiny (12 Transformer Blocks)
(1280 x 7 x 7) -> GAP           (192-d [CLS] Token)
   │ (1280-d)                      │ (192-d)
   └───────────────┬───────────────┘
                   ▼
         Channel Concatenation (1472-d)
                   │
         Linear(1472 -> 256) + BatchNorm + GELU + Dropout(0.40)
                   │
         Linear(256 -> 4 Classes)
                   │
      ┌────────────┴────────────┐
      ▼                         ▼
Output 0: Logits (1, 4)    Output 1: Grad-CAM Heatmap (1, 1, 224, 224)
```

---

## 📊 Experimental Results & Benchmarks

### 1. Per-Class Quantitative Performance (Hold-Out Test Set: 400 Samples)
| Disease Class | Precision | Recall | F1-Score | Support |
|---|:---:|:---:|:---:|:---:|
| **Northern Leaf Blight (NLB)** | 0.9709 | 1.0000 | 0.9852 | 100 |
| **Common Rust (CR)** | 0.9798 | 0.9700 | 0.9749 | 100 |
| **Gray Leaf Spot (GLS)** | 1.0000 | 1.0000 | 1.0000 | 100 |
| **Healthy Foliage** | 1.0000 | 0.9800 | 0.9899 | 100 |
| **Overall Macro Average** | **0.9877** | **0.9875** | **0.9875** | **400** |
| **Overall Accuracy** | \multicolumn{4}{c}{**98.75% (395 / 400 Correct Classifications)**} |

---

### 2. INT8 vs. FP32 Mobile CPU Hardware Benchmark
| Model Variant | Precision | Model Size (MB) | CPU Latency (ms) | Test Accuracy (%) |
|---|:---:|:---:|:---:|:---:|
| **Hybrid CNN-ViT Baseline** | FP32 | 37.96 MB | 60.94 ms | 98.50% (394/400) |
| **Quantized Hybrid (Ours)** | **INT8** | **21.84 MB** | **48.04 ms** | **98.75% (395/400)** |
| **Efficiency Gain / Delta** | — | **-42.48% Footprint** | **1.3x Speedup** | **+0.25% Regularization Gain** |

---

## 🚀 Local Reproduction Guide

### 1. Environment Setup
```bash
cd research
pip install -r requirements.txt
```

### 2. Multi-Domain Dataset Ingestion
Downloads and combines PlantVillage, Ndisan, and PlantDoc datasets into balanced 80/10/10 splits:
```bash
python data/dataset_builder.py
```

### 3. Model Training
Trains `HybridCornNet` across 10 epochs using AdamW, Cosine Annealing, and Label Smoothing:
```bash
python train.py --epochs 10 --batch_size 32 --lr 3e-4 --output_dir ./checkpoints
```

### 4. Model Evaluation & Benchmark Visualization
Computes test metrics and generates confusion matrices and ROC-AUC curves:
```bash
python evaluate.py --model_path ./checkpoints/best_hybrid_corn_model_clean.pth --test_dir ./combined_corn_dataset/test
```

### 5. ONNX Export & Dynamic INT8 Quantization
Converts PyTorch checkpoint into dual-output FP32 ONNX and applies dynamic post-training quantization to INT8:
```bash
python export_onnx.py --weights_path ./checkpoints/best_hybrid_corn_model_clean.pth --output_dir ./exported_models
```

The resulting `corn_model_with_cam_int8.onnx` can be directly dropped into the Flutter app assets at `assets/corn_model_with_cam_int8.onnx`.
