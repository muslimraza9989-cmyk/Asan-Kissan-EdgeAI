"""
HybridCornNet Architecture
==========================
Robust Edge-AI for Explainable Maize Leaf Disease Diagnosis via Quantized CNN-Transformer Fusion.

Combines:
  1. Local Inductive Bias: EfficientNet-B0 (1280-dim feature map)
  2. Global Context: DeiT-Tiny (192-dim token representation)
  3. Concatenated Bottleneck: 1472 -> 256 -> num_classes
  4. Embedded Dual-Output Grad-CAM Export Head
"""

import torch
import torch.nn as nn
import torch.nn.functional as F
import timm


class HybridCornNet(nn.Module):
    def __init__(self, num_classes: int = 4, pretrained: bool = True, dropout_rate: float = 0.40):
        super(HybridCornNet, self).__init__()
        
        # 1. Local Convolutional Stream (EfficientNet-B0)
        self.cnn = timm.create_model(
            'efficientnet_b0',
            pretrained=pretrained,
            features_only=True
        )
        self.cnn_pool = nn.AdaptiveAvgPool2d(1)
        self.cnn_dim = 1280  # Stage 7 output channels

        # 2. Global Self-Attention Stream (DeiT-Tiny)
        self.vit = timm.create_model(
            'deit_tiny_patch16_224',
            pretrained=pretrained,
            num_classes=0  # Returns class token (192-d)
        )
        self.vit_dim = 192

        # 3. Concatenated Feature Bottleneck Head (1472 -> 256 -> num_classes)
        self.fused_dim = self.cnn_dim + self.vit_dim  # 1472
        self.fusion_head = nn.Sequential(
            nn.Linear(self.fused_dim, 256),
            nn.BatchNorm1d(256),
            nn.GELU(),
            nn.Dropout(p=dropout_rate),
            nn.Linear(256, num_classes)
        )

    def extract_features(self, x: torch.Tensor):
        # Local CNN Feature Maps (Stage 7)
        cnn_stages = self.cnn(x)
        feat_maps = cnn_stages[-1]  # Shape: (B, 1280, 7, 7)
        feat_cnn = self.cnn_pool(feat_maps).flatten(1)  # Shape: (B, 1280)

        # Global ViT Class Token
        feat_vit = self.vit(x)  # Shape: (B, 192)

        # Channel Concatenation (B, 1472)
        fused = torch.cat((feat_cnn, feat_vit), dim=1)
        return feat_maps, fused

    def forward(self, x: torch.Tensor):
        _, fused = self.extract_features(x)
        logits = self.fusion_head(fused)
        return logits


class ExportableHybridCornNetWithCAM(nn.Module):
    """
    Dual-Output ONNX Export Wrapper:
      - Output 0: Logits (1, num_classes)
      - Output 1: Spatial Grad-CAM Activation Heatmap (1, 1, 224, 224)
    """
    def __init__(self, base_model: HybridCornNet):
        super(ExportableHybridCornNetWithCAM, self).__init__()
        self.model = base_model
        self.model.eval()

    def forward(self, x: torch.Tensor):
        # 1. Forward feature extraction
        feat_maps, fused = self.model.extract_features(x)  # (1, 1280, 7, 7), (1, 1472)
        logits = self.model.fusion_head(fused)             # (1, num_classes)

        # 2. Derive combined CAM weights for top predicted class
        pred_idx = torch.argmax(logits, dim=1)  # (1,)
        
        # Linear layer weights
        w_fc1_cnn = self.model.fusion_head[0].weight[:, :1280]  # (256, 1280)
        w_fc2 = self.model.fusion_head[-1].weight                # (num_classes, 256)
        w_combined = torch.matmul(w_fc2, w_fc1_cnn)              # (num_classes, 1280)
        
        # Target weight for predicted class
        target_w = w_combined[pred_idx].unsqueeze(-1).unsqueeze(-1)  # (1, 1280, 1, 1)

        # 3. Compute spatial Class Activation Map
        cam = torch.sum(target_w * feat_maps, dim=1, keepdim=True)  # (1, 1, 7, 7)
        cam = F.relu(cam)

        # 4. Bilinear upsampling to 224x224 input resolution
        cam_up = F.interpolate(cam, size=(224, 224), mode='bilinear', align_corners=False)  # (1, 1, 224, 224)

        # Min-max normalization
        min_v = torch.amin(cam_up, dim=(2, 3), keepdim=True)
        max_v = torch.amax(cam_up, dim=(2, 3), keepdim=True)
        cam_norm = (cam_up - min_v) / (max_v - min_v + 1e-8)

        return logits, cam_norm
