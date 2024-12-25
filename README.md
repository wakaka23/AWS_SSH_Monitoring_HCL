## システム構成図
<img width="1187" alt="image" src="https://github.com/user-attachments/assets/c7522729-6a4a-40ca-b60b-266f1f09b48c" />
<br><br>

## ディレクトリ構成
```
├─ environments
│  ├─ prd
│  ├─ stg
│  └─ dev
│     ├─ main.tf
│     ├─ local.tf
│     ├─ variable.tf
│     └─ (terraform.tfvars)
│
├─ files
│  └─ cloudwatch_agent.json(CloudWatch Agent設定用JSON)
│
└─ modules
      ├─ ec2(EC2関連のリソース）
      │  ├─ main.tf
      │  ├─ output.tf
      │  └─ variable.tf
      │
      ├─ initializer（tfstate用S3バケット作成）
      │  └─ main.tf
      │
      ├─ monitoring（CloudWatch Alarmやメトリクスフィルタなど監視関連のリソース）
      │  ├─ main.tf
      │  ├─ output.tf
      │  └─ variable.tf
      │
      └─ network（VPC、Subnet、VPNなどネットワーク全般のリソース）
         ├─ main.tf
         ├─ output.tf
         └─ variable.tf
```
