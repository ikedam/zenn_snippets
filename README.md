Zenn記事用のコード置き場。
ブランチを作ってコードを置く。
https://zenn.dev/ikedam

# OpenTofu による環境分離のデモ

OpenTofu で dev, stg, prd の環境の切り替えを行うデモです。

* 環境ごとに使用する GCP プロジェクトが異なる。
* バックエンド用の GCS バケットは各環境の GCP プロジェクト内に作成する。

という想定をしています。

## バックエンド用のGCSバケットの作成

* 各環境の GCP プロジェクトに GCS バケットを作成してください。
    * 想定するリソース名は以下の通り:
        * GCS バケット: `(プロジェクト名)-tfstate-(環境名、dev/stg/prd)`
* GCS バケットの設定のベストプラクティスは OpenTofu のドキュメントを参照してください: https://opentofu.org/docs/language/settings/backends/gcs/

## バックエンド/GCPプロジェクトの設定

各環境の `env/ENV.tfvars` 内で `FIXME` となっている以下の項目について、使用する GCP プロジェクトを設定してください:

* `env/ENV.tfvars`
    * gcp_project

## ロックファイルの作成・更新

以下のコマンドで全環境の `.terraform.lock.hcl` を更新します:

``` console
make lock
```

## opentofu init の実行

以下のコマンドで指定した環境について `opentofu init` を実行します。
**GCP の認証が必要です。**

```console
make init ENV=dev
```

## インフラの構築

以下のコマンドで指定した環境について `opentofu plan` および `opentofu apply` を実行します。
**GCP の認証が必要です。**

```console
make plan ENV=dev
make apply ENV=dev
```

## インフラの削除

以下のコマンドで指定した環境について `opentofu destroy` を実行します。
**GCP の認証が必要です。**

```console
make destroy ENV=dev
```
