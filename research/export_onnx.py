"""
ONNX Export & Dynamic INT8 Quantization Script
==============================================
Exports HybridCornNet to:
  1. Full Precision FP32 ONNX with Embedded Grad-CAM Output (corn_model_with_cam_fp32.onnx)
  2. Dynamic Post-Training INT8 Quantized ONNX (corn_model_with_cam_int8.onnx)
"""

import os
import argparse
import torch
import onnx
from onnxruntime.quantization import quantize_dynamic, QuantType

from models.hybrid_corn_net import HybridCornNet, ExportableHybridCornNetWithCAM


def export_and_quantize(weights_path: str, output_dir: str = "./exported_models"):
    os.makedirs(output_dir, exist_ok=True)
    device = torch.device('cpu')

    print(f"[1/3] Loading PyTorch Checkpoint from {weights_path}...")
    base_model = HybridCornNet(num_classes=4, pretrained=False).to(device)
    base_model.load_state_dict(torch.load(weights_path, map_location=device))
    base_model.eval()

    # Wrap model with dual-output CAM exporter
    exportable_model = ExportableHybridCornNetWithCAM(base_model).to(device)
    exportable_model.eval()

    fp32_onnx_path = os.path.join(output_dir, "corn_model_with_cam_fp32.onnx")
    int8_onnx_path = os.path.join(output_dir, "corn_model_with_cam_int8.onnx")

    dummy_input = torch.randn(1, 3, 224, 224, dtype=torch.float32)

    print(f"[2/3] Exporting to Dual-Output FP32 ONNX -> {fp32_onnx_path}...")
    torch.onnx.export(
        exportable_model,
        dummy_input,
        fp32_onnx_path,
        export_params=True,
        opset_version=17,
        do_constant_folding=True,
        input_names=['input'],
        output_names=['logits', 'grad_cam_map'],
        dynamic_axes={
            'input': {0: 'batch_size'},
            'logits': {0: 'batch_size'},
            'grad_cam_map': {0: 'batch_size'}
        }
    )

    # Validate ONNX model
    onnx_model = onnx.load(fp32_onnx_path)
    onnx.checker.check_model(onnx_model)
    fp32_size = os.path.getsize(fp32_onnx_path) / (1024 * 1024)
    print(f"  --> FP32 ONNX Validated Successfully (Size: {fp32_size:.2f} MB)")

    print(f"[3/3] Performing Dynamic Post-Training INT8 Quantization -> {int8_onnx_path}...")
    quantize_dynamic(
        model_input=fp32_onnx_path,
        model_output=int8_onnx_path,
        weight_type=QuantType.QInt8,
        op_types_to_quantize=['MatMul', 'Gemm', 'Conv']
    )

    int8_size = os.path.getsize(int8_onnx_path) / (1024 * 1024)
    compression_ratio = (1.0 - (int8_size / fp32_size)) * 100.0

    print("\n" + "="*60)
    print("EXPORT & QUANTIZATION SUMMARY:")
    print("="*60)
    print(f"  - FP32 ONNX Model Size : {fp32_size:.2f} MB")
    print(f"  - INT8 ONNX Model Size : {int8_size:.2f} MB")
    print(f"  - Footprint Reduction  : -{compression_ratio:.2f}%")
    print(f"  - Destination Path     : {int8_onnx_path}")
    print("="*60)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Export HybridCornNet to Dual-Output ONNX and Quantize to INT8")
    parser.add_argument('--weights_path', type=str, default='./checkpoints/best_hybrid_corn_model_clean.pth', help='Path to PyTorch weights')
    parser.add_argument('--output_dir', type=str, default='./exported_models', help='Destination directory for ONNX models')

    args = parser.parse_args()
    export_and_quantize(args.weights_path, args.output_dir)
