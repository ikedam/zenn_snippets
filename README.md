Zenn記事用のコード置き場。
ブランチを作ってコードを置く。
https://zenn.dev/ikedam

# OpenTofu による環境分離のデモ

OpenTofu で dev, stg, prd の環境の切り替えを行うデモです。

* 環境ごとに使用する AWS アカウントが異なる。
* バックエンド用の S3 バケット・DynamoDB テーブルは各環境の AWS アカウント内に作成する。

という想定をしています。

## バックエンド用のS3バケットとDynamoDBテーブルの作成

* 各環境の AWS に S3 バケットと DynamoDB テーブルを作成してください。
    * 想定するリソース名は以下の通り:
        * S3 バケット: `(アカウント ID)-tfstate-(環境名、dev/stg/prd)`
        * DynamoDB テーブル: `tfstate-lock`
    * 上記以外のリソース名にする場合は [`main.tf`](./main.tf) を適当に変更してください。
* 動作を試すだけならば、 DynamoDB テーブルの作成はオプションです。
    * DynamoDB テーブルを使わない場合は [`main.tf`](./main.tf) の `dynamodb_table =` の部分をコメントアウトしてください。
* S3 バケットや DynamoDB テーブルの設定方法や設定のベストプラクティスは Terraform のドキュメントを参照してください: https://opentofu.org/docs/language/settings/backends/s3/

## バックエンド/AWSアカウントの設定

各環境の `env/ENV.tfvars` 内で `FIXME` となっている以下の項目について、使用する AWS アカウントを設定してください:

* `env/ENV.tf`
    * account_id

## ロックファイルの作成・更新

以下のコマンドで全環境の `.terraform.lock.hcl` を更新します:

``` console
make lock
```

## opentofu init の実行

以下のコマンドで指定した環境について `opentofu init` を実行します。
**AWS の認証が必要です。**

```console
make init ENV=dev
```

## インフラの構築

以下のコマンドで指定した環境について `opentofu plan` および `opentofu apply` を実行します。
**AWS の認証が必要です。**

```console
make plan ENV=dev
make apply ENV=dev
```

## インフラの削除

以下のコマンドで指定した環境について `opentofu destroy` を実行します。
**AWS の認証が必要です。**

```console
make destroy ENV=dev
```
