Zenn記事用のコード置き場。
ブランチを作ってコードを置く。
https://zenn.dev/ikedam

# パラメーターファイルの切り替えによる Terraform の環境分離のデモ

パラメーターファイルの切り替えによって dev, stg, prd の環境の切り替えを行う Terraform 実装のデモです。

* 環境ごとに使用する GCP プロジェクトが異なる。
* バックエンド用の GCS バケットは各環境の GCP プロジェクト内に作成する。

という想定をしています。

## バックエンド用のGCSバケットの作成

* 各環境の GCP プロジェクトに GCS バケットを作成してください。
* 動作を試すだけならば、 DynamoDB テーブルの作成はオプションです。
* GCS バケットの設定のベストプラクティスは Terraform のドキュメントを参照してください: https://developer.hashicorp.com/terraform/language/settings/backends/gcs

## バックエンド/GCPプロジェクトの設定

各環境の `env/ENV/backend.tfbackend` および `env/ENV/terraform.tfvars` 内で `FIXME` となっている以下の項目について、使用する GCP プロジェクト、作成したバックエンド用の GCS バケットを設定してください:

* `env/ENV/backend.tfbackend`
    * bucket
* `env/ENV/terraform.tfvars`
    * gcp_project

## ロックファイルの作成・更新

以下のコマンドで全環境の `.terraform.lock.hcl` を更新します:

``` console
make lock
```

## terraform init の実行

以下のコマンドで指定した環境について `terraform init` を実行します。
**GCP の認証が必要です。**

```console
make init ENV=dev
```

## インフラの構築

以下のコマンドで指定した環境について `terraform plan` および `terraform apply` を実行します。
**GCP の認証が必要です。**

```console
make plan ENV=dev
make apply ENV=dev
```

## インフラの削除

以下のコマンドで指定した環境について `terraform destroy` を実行します。
**GCP の認証が必要です。**

```console
make destroy ENV=dev
```
