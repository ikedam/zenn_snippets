Zenn記事用のコード置き場。
ブランチを作ってコードを置く。
https://zenn.dev/ikedam

# ワークスペースの切り替えによる Terraform の環境分離のデモ

ワークスペースの切り替えによって dev, stg, prd の環境の切り替えを行う Terraform 実装のデモです。

* 環境ごとに使用する AWS アカウントが異なる。
* ~~バックエンド用の S3 バケット・DynamoDB テーブルは各環境の AWS アカウント内に作成する。~~
    * これはワークスペースの仕様上不可能なので、共通のS3バケットを参照する想定。

という想定をしています。

## バックエンド用のS3バケットとDynamoDBテーブルの作成

* いずれかの環境の AWS アカウントに S3 バケット、および各環境の AWS アカウントに DynamoDB テーブルを作成してください。
* 動作を試すだけならば、 DynamoDB テーブルの作成はオプションです。
* S3 バケットや DynamoDB テーブルの設定方法や設定のベストプラクティスは Terraform のドキュメントを参照してください: https://developer.hashicorp.com/terraform/language/settings/backends/s3

## バックエンド/AWSアカウントの設定

[`main.tf`](./main.tf) 内で `FIXME` となっている以下の項目について、使用する AWS アカウント、作成したバックエンド用の S3 バケット、DynamoDB テーブルを設定してください:

* terraform.backend.s3.bucket
* terraform.backend.s3.dynamodb_table
* locals.env_configs.*.account_id

## ロックファイルの作成・更新

以下のコマンドで `.terraform.lock.hcl` を更新します:

``` console
make lock
```

## terraform init の実行

以下のコマンドで `terraform init` を実行します。
**AWS の認証が必要です。**

```console
make init
```

## インフラの構築

以下のコマンドで指定した環境について `terraform plan` および `terraform apply` を実行します。
**AWS の認証が必要です。**

```console
make plan ENV=dev
make apply ENV=dev
```

## インフラの削除

以下のコマンドで指定した環境について `terraform destroy` を実行します。
**AWS の認証が必要です。**

```console
make destroy ENV=dev
```
