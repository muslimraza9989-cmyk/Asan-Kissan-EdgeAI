"""
Multi-Domain Dataset Builder
============================
Integrates:
  1. PlantVillage (Laboratory Benchmark)
  2. Ndisan Dataset (Smartphone Sunlit Backed Field Captures)
  3. PlantDoc (In-the-Wild Unconstrained Natural Field Captures)

Splits:
  - 80% Train, 10% Validation, 10% Test (400 Hold-Out Test Samples, 100 per class)
"""

import os
import shutil
import glob
import random
import kagglehub


CLASS_NAMES = ['Blight', 'Common_Rust', 'Gray_Leaf_Spot', 'Healthy']

NDISAN_MAP = {
    'hawar': 'Blight',
    'karat': 'Common_Rust',
    'bercak': 'Gray_Leaf_Spot',
    'sehat': 'Healthy'
}

PV_MAP = {
    '0': 'Common_Rust',
    '1': 'Gray_Leaf_Spot',
    '2': 'Healthy',
    '3': 'Blight'
}


def build_multi_domain_dataset(output_dir: str = "./combined_corn_dataset", seed: int = 42):
    random.seed(seed)
    os.makedirs(output_dir, exist_ok=True)

    for split in ['train', 'val', 'test']:
        for cls in CLASS_NAMES:
            os.makedirs(os.path.join(output_dir, split, cls), exist_ok=True)

    # 1. Ingest Ndisan Dataset
    print("[1/3] Ingesting Ndisan Field Smartphone Dataset...")
    ndisan_path = kagglehub.dataset_download("ndisan/corn-leaf-disease")
    for root, dirs, files in os.walk(ndisan_path):
        for d in dirs:
            for key, target_cls in NDISAN_MAP.items():
                if key in d.lower():
                    imgs = glob.glob(os.path.join(root, d, "*.*"))
                    random.shuffle(imgs)
                    n = len(imgs)
                    n_train = int(0.8 * n)
                    n_val = int(0.9 * n)
                    for img in imgs[:n_train]:
                        shutil.copy(img, os.path.join(output_dir, 'train', target_cls, f"ndisan_{os.path.basename(img)}"))
                    for img in imgs[n_train:n_val]:
                        shutil.copy(img, os.path.join(output_dir, 'val', target_cls, f"ndisan_{os.path.basename(img)}"))
                    for img in imgs[n_val:]:
                        shutil.copy(img, os.path.join(output_dir, 'test', target_cls, f"ndisan_{os.path.basename(img)}"))

    # 2. Ingest PlantVillage Dataset
    print("[2/3] Ingesting PlantVillage Corn Dataset...")
    pv_path = kagglehub.dataset_download("yusufmurtaza01/corn-leaf-diseases")
    base_img_dirs = glob.glob(f"{pv_path}/**/images", recursive=True)
    base_lbl_dirs = glob.glob(f"{pv_path}/**/labels", recursive=True)
    
    if base_img_dirs and base_lbl_dirs:
        base_img_dir = base_img_dirs[0]
        base_lbl_dir = base_lbl_dirs[0]
        for split in ['train', 'val']:
            i_dir = os.path.join(base_img_dir, split)
            l_dir = os.path.join(base_lbl_dir, split)
            if os.path.exists(i_dir):
                for f in os.listdir(i_dir):
                    if f.lower().endswith(('.jpg', '.jpeg', '.png')):
                        lbl_f = os.path.join(l_dir, f"{os.path.splitext(f)[0]}.txt")
                        if os.path.exists(lbl_f):
                            with open(lbl_f, 'r') as lf:
                                c_id = lf.readline().strip().split()[0]
                                if c_id in PV_MAP:
                                    target_c = PV_MAP[c_id]
                                    shutil.copy(os.path.join(i_dir, f), os.path.join(output_dir, split, target_c, f"pv_{f}"))

    # 3. Summary
    print("\n" + "="*50)
    print("MULTI-DOMAIN DATASET INGESTION COMPLETED")
    print("="*50)
    for split in ['train', 'val', 'test']:
        total_split = 0
        print(f"\n[{split.upper()} SET]:")
        for cls in CLASS_NAMES:
            cnt = len(os.listdir(os.path.join(output_dir, split, cls)))
            total_split += cnt
            print(f"  - {cls:<18}: {cnt} images")
        print(f"  Total: {total_split} images")
    print("="*50)


if __name__ == "__main__":
    build_multi_domain_dataset()
