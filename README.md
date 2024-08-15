Zenn記事用のコード置き場。
ブランチを作ってコードを置く。
https://zenn.dev/ikedam

# パラメーターファイルの切り替えによる Terraform の環境分離のデモ

パラメーターファイルの切り替えによって dev, stg, prd の環境の切り替えを行う Terraform 実装のデモです。

* 環境ごとに使用する AWS アカウントが異なる。
* バックエンド用の S3 バケット・DynamoDB テーブルは各環境の AWS アカウント内に作成する。

という想定をしています。

## バックエンド用のS3バケットとDynamoDBテーブルの作成

* 各環境の AWS に S3 バケットと DynamoDB テーブルを作成してください。
* 動作を試すだけならば、 DynamoDB テーブルの作成はオプションです。
* S3 バケットや DynamoDB テーブルの設定方法や設定のベストプラクティスは Terraform のドキュメントを参照してください: https://developer.hashicorp.com/terraform/language/settings/backends/s3

## バックエンド/AWSアカウントの設定

各環境の `env/ENV/backend.tfbackend` および `env/ENV/terraform.tfvars` 内で `FIXME` となっている以下の項目について、使用する AWS アカウント、作成したバックエンド用の S3 バケット、DynamoDB テーブルを設定してください:

* `env/ENV/backend.tfbackend`
    * bucket
    * dynamodb_table
* `env/ENV/terraform.tfvars`
    * account_id

## ロックファイルの作成・更新

以下のコマンドで全環境の `.terraform.lock.hcl` を更新します:

``` console
make lock
```

## terraform init の実行

以下のコマンドで指定した環境について `terraform init` を実行します。
**AWS の認証が必要です。**

```console
make init ENV=dev
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
