"""
Model Training Script
=====================
Trains HybridCornNet across 10 epochs using:
  - AdamW Optimizer (lr=3e-4, weight_decay=1e-2)
  - Cosine Annealing Learning Rate Scheduler
  - Label-Smoothed Cross-Entropy Loss (alpha=0.1)
  - Multi-Domain Data Augmentation
"""

import os
import time
import argparse
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader
from torchvision import datasets, transforms
from torch.optim.lr_scheduler import CosineAnnealingLR

from models.hybrid_corn_net import HybridCornNet


def get_data_loaders(data_dir: str, batch_size: int = 32, num_workers: int = 4):
    train_transform = transforms.Compose([
        transforms.RandomResizedCrop(224, scale=(0.5, 1.0)),
        transforms.RandomHorizontalFlip(),
        transforms.RandomVerticalFlip(),
        transforms.RandomRotation(30),
        transforms.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.2),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
        transforms.RandomErasing(p=0.2)
    ])

    val_transform = transforms.Compose([
        transforms.Resize((224, 224)),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
    ])

    train_dataset = datasets.ImageFolder(os.path.join(data_dir, 'train'), transform=train_transform)
    val_dataset = datasets.ImageFolder(os.path.join(data_dir, 'val'), transform=val_transform)

    train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True, num_workers=num_workers, pin_memory=True)
    val_loader = DataLoader(val_dataset, batch_size=batch_size, shuffle=False, num_workers=num_workers, pin_memory=True)

    return train_loader, val_loader, train_dataset.classes


def train_model(args):
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    print(f"[INFO] Using Device: {device}")

    train_loader, val_loader, class_names = get_data_loaders(args.data_dir, args.batch_size)
    print(f"[INFO] Classes Detected: {class_names}")

    model = HybridCornNet(num_classes=len(class_names), pretrained=True, dropout_rate=0.40).to(device)

    criterion = nn.CrossEntropyLoss(label_smoothing=0.10)
    optimizer = optim.AdamW(model.parameters(), lr=args.lr, weight_decay=args.weight_decay)
    scheduler = CosineAnnealingLR(optimizer, T_max=args.epochs, eta_min=1e-6)

    best_acc = 0.0
    os.makedirs(args.output_dir, exist_ok=True)
    best_weights_path = os.path.join(args.output_dir, "best_hybrid_corn_model_clean.pth")

    print("\n" + "="*60)
    print(f"STARTING TRAINING ({args.epochs} EPOCHS)")
    print("="*60)

    for epoch in range(1, args.epochs + 1):
        start_t = time.time()
        
        # Training Phase
        model.train()
        train_loss, train_correct, train_total = 0.0, 0, 0
        for images, labels in train_loader:
            images, labels = images.to(device), labels.to(device)
            optimizer.zero_grad()
            outputs = model(images)
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()

            train_loss += loss.item() * images.size(0)
            _, preds = torch.max(outputs, 1)
            train_correct += (preds == labels).sum().item()
            train_total += labels.size(0)

        scheduler.step()
        epoch_train_loss = train_loss / train_total
        epoch_train_acc = (train_correct / train_total) * 100

        # Validation Phase
        model.eval()
        val_loss, val_correct, val_total = 0.0, 0, 0
        with torch.no_grad():
            for images, labels in val_loader:
                images, labels = images.to(device), labels.to(device)
                outputs = model(images)
                loss = criterion(outputs, labels)
                val_loss += loss.item() * images.size(0)
                _, preds = torch.max(outputs, 1)
                val_correct += (preds == labels).sum().item()
                val_total += labels.size(0)

        epoch_val_loss = val_loss / val_total
        epoch_val_acc = (val_correct / val_total) * 100
        epoch_time = time.time() - start_t

        print(f"Epoch [{epoch:02d}/{args.epochs:02d}] ({epoch_time:.1f}s) | "
              f"Train Loss: {epoch_train_loss:.4f} Acc: {epoch_train_acc:.2f}% | "
              f"Val Loss: {epoch_val_loss:.4f} Acc: {epoch_val_acc:.2f}%")

        if epoch_val_acc > best_acc:
            best_acc = epoch_val_acc
            torch.save(model.state_dict(), best_weights_path)
            print(f"  --> Saved Best Checkpoint (Val Acc: {best_acc:.2f}%) to {best_weights_path}")

    print("\n" + "="*60)
    print(f"TRAINING COMPLETE. Best Validation Accuracy: {best_acc:.2f}%")
    print(f"Saved Checkpoint: {best_weights_path}")
    print("="*60)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Train HybridCornNet on Multi-Domain Corn Foliar Dataset")
    parser.add_argument('--data_dir', type=str, default='./combined_corn_dataset', help='Path to combined dataset directory')
    parser.add_argument('--epochs', type=int, default=10, help='Number of epochs (default: 10)')
    parser.add_argument('--batch_size', type=int, default=32, help='Batch size (default: 32)')
    parser.add_argument('--lr', type=float, default=3e-4, help='Learning rate (default: 3e-4)')
    parser.add_argument('--weight_decay', type=float, default=1e-2, help='Weight decay (default: 1e-2)')
    parser.add_argument('--output_dir', type=str, default='./checkpoints', help='Output directory for checkpoints')
    
    args = parser.parse_args()
    train_model(args)
