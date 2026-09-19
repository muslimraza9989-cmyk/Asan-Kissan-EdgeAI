"""
Model Evaluation & Benchmarking Script
======================================
Evaluates the trained PyTorch / ONNX model on the 400 hold-out multi-domain test set.
Generates:
  1. Per-Class Classification Report (Precision, Recall, F1-Score, Support)
  2. Multi-Domain Test Confusion Matrix
  3. Multi-Class ROC-AUC Curves
"""

import os
import glob
import argparse
import numpy as np
import torch
import torch.nn.functional as F
from PIL import Image
from sklearn.metrics import classification_report, confusion_matrix, roc_curve, auc
import matplotlib.pyplot as plt
import seaborn as sns

from models.hybrid_corn_net import HybridCornNet


CLASS_NAMES = ['Blight', 'Common_Rust', 'Gray_Leaf_Spot', 'Healthy']
DISPLAY_NAMES = ['Northern Leaf Blight', 'Common Rust', 'Gray Leaf Spot', 'Healthy']


def evaluate_pytorch_model(model_path: str, test_dir: str, output_dir: str = "./eval_results"):
    os.makedirs(output_dir, exist_ok=True)
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    print(f"[INFO] Evaluating PyTorch Model: {model_path} on {device}")

    # Load Model
    model = HybridCornNet(num_classes=4, pretrained=False).to(device)
    model.load_state_dict(torch.load(model_path, map_location=device))
    model.eval()

    mean = np.array([0.485, 0.456, 0.406], dtype=np.float32).reshape(3, 1, 1)
    std = np.array([0.229, 0.224, 0.225], dtype=np.float32).reshape(3, 1, 1)

    y_true, y_pred, y_probs = [], [], []

    for idx, cls in enumerate(CLASS_NAMES):
        folder = os.path.join(test_dir, cls)
        img_paths = glob.glob(os.path.join(folder, "*.*"))
        for img_p in img_paths:
            raw_img = Image.open(img_p).convert('RGB').resize((224, 224))
            img_arr = np.array(raw_img, dtype=np.float32).transpose(2, 0, 1) / 255.0
            norm_t = torch.tensor((img_arr - mean) / std, dtype=torch.float32).unsqueeze(0).to(device)

            with torch.no_grad():
                logits = model(norm_t)
                probs = F.softmax(logits, dim=1).cpu().numpy()[0]

            pred_cls = int(np.argmax(probs))
            y_true.append(idx)
            y_pred.append(pred_cls)
            y_probs.append(probs)

    y_true = np.array(y_true)
    y_pred = np.array(y_pred)
    y_probs = np.array(y_probs)

    # 1. Classification Report
    report = classification_report(y_true, y_pred, target_names=DISPLAY_NAMES, digits=4)
    print("\n" + "="*60)
    print("CLASSIFICATION REPORT:")
    print("="*60)
    print(report)
    with open(os.path.join(output_dir, "classification_report.txt"), "w") as f:
        f.write(report)

    # 2. Confusion Matrix Plot
    cm = confusion_matrix(y_true, y_pred)
    acc = (np.trace(cm) / cm.sum()) * 100

    plt.figure(figsize=(7.5, 6.5))
    sns.heatmap(cm, annot=True, fmt="d", cmap="Blues", cbar=True,
                xticklabels=DISPLAY_NAMES, yticklabels=DISPLAY_NAMES,
                annot_kws={"size": 13, "weight": "bold"})
    plt.title(f"Multi-Domain Test Confusion Matrix ({acc:.2f}%)", fontsize=13, fontweight='bold', pad=12)
    plt.ylabel("True Label", fontsize=11, fontweight='bold')
    plt.xlabel("Predicted Label", fontsize=11, fontweight='bold')
    plt.xticks(rotation=20, ha='right')
    plt.yticks(rotation=0)
    plt.tight_layout()
    cm_path = os.path.join(output_dir, "confusion_matrix.png")
    plt.savefig(cm_path, dpi=300, bbox_inches='tight')
    plt.close()
    print(f"[INFO] Saved Confusion Matrix to {cm_path}")

    # 3. ROC-AUC Curves
    plt.figure(figsize=(7.5, 6.5))
    colors = ['#0033cc', '#ff9900', '#009933', '#cc0000']
    for i, cls_name in enumerate(DISPLAY_NAMES):
        fpr, tpr, _ = roc_curve((y_true == i).astype(int), y_probs[:, i])
        roc_auc = auc(fpr, tpr)
        plt.plot(fpr, tpr, color=colors[i], lw=2, label=f'ROC {cls_name} (AUC = {roc_auc:.4f})')

    plt.plot([0, 1], [0, 1], color='k', lw=1.5, linestyle='--')
    plt.xlim([0.0, 1.0])
    plt.ylim([0.0, 1.05])
    plt.xlabel('False Positive Rate', fontsize=11, fontweight='bold')
    plt.ylabel('True Positive Rate', fontsize=11, fontweight='bold')
    plt.title('Multi-Domain ROC-AUC Curves', fontsize=13, fontweight='bold')
    plt.legend(loc="lower right", frameon=True)
    plt.grid(True, linestyle='--', alpha=0.6)
    plt.tight_layout()
    roc_path = os.path.join(output_dir, "roc_auc_curves.png")
    plt.savefig(roc_path, dpi=300, bbox_inches='tight')
    plt.close()
    print(f"[INFO] Saved ROC-AUC Curves to {roc_path}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Evaluate HybridCornNet on Hold-Out Test Set")
    parser.add_argument('--model_path', type=str, default='./checkpoints/best_hybrid_corn_model_clean.pth', help='Path to PyTorch model weights')
    parser.add_argument('--test_dir', type=str, default='./combined_corn_dataset/test', help='Path to test set directory')
    parser.add_argument('--output_dir', type=str, default='./eval_results', help='Path to output evaluation directory')
    
    args = parser.parse_args()
    evaluate_pytorch_model(args.model_path, args.test_dir, args.output_dir)
