Zenn記事用のコード置き場。
ブランチを作ってコードを置く。
https://zenn.dev/ikedam

# Firestore から BigQuery へのデータ同期デモ

Firestore のドキュメントを自動的に BigQuery に同期するインフラの構築のデモです。

## 注意事項

Cloud Functions のイメージの作成、プッシュを OpenTofu で行います。

* 実行環境に dockerd (Docker Desktop など) がインストールされている必要があります。
* このためにイメージプッシュを行うためのサービスアカウントを作成し、ステートファイルにサービスアカウントの JSON キーが記録されるので注意してください。
* 実行環境の dockerd にイメージがない場合、(すでに Container Registry にイメージが登録済みでも) イメージのビルドが行われます。これにより、 OpenTofu の差分に docker_image が出現しますが、実際にはクラウド環境上のイメージは更新しない、という動作が起きます。
* この部分の詳細は [Terraformでコンテナイメージのビルドからデプロイまでを行う(GCP編)](https://zenn.dev/ikedam/articles/a353646a5c625e) を参照してください。

## インフラの構築方法

1. `terraform.tfvars` ファイルを作成し、以下のように設定を行ってください:

    ```hcl
    project = "your-gcp-project"
    region  = "asia-northeast1"
    # 構築するリソースのプリフィックス
    # basename = "f2b"
    ```

2. [Google Cloud SDK](https://cloud.google.com/sdk?hl=ja) をインストールし、認証を行ってください:

    ```
    gcloud auth application-default login
    ```

3. `make init` を実行し、 OpenTofu の初期化を行います:

    ```
    make init
    ```

4. `make apply` を行い、インフラを構築します:

    ```
    make apply
    ```

    * 権限の反映タイミングなどの都合で何度かエラーになって実行し直さないとダメかも。

## 動作確認

[Firestore のコンソール](https://console.cloud.google.com/firestore) から、 `Testdata` というコレクションに新しいデータを登録してください。
Firesotre のコンソールのパスは、デフォルト設定の場合は https://console.cloud.google.com/firestore/databases/f2bdemo です。

* `ID` フィールドに string 型で自動発番された Document ID と同じ値を設定します。
* `Name` フィールドに string 型で適当な文字列を入れます。 (`テスト太郎` など)
* `Ruby` フィールドに string 型で適当な文字列を入れます。 (`てすとたろう` など)
* `Age` フィールドに number 型で適当な数値を入れます。 (`20` など)
* `CreatedAt` フィールドに timestamp 型で適当な時刻を設定します。 (デフォルト値の現在時刻で良いでしょう)
* その他のフィールドは設定しても無視されます。

[BigQuery のコンソール](https://console.cloud.google.com/bigquery) から、 `testdata` テーブルのデータを確認します。
デフォルト設定の場合はデータセット `f2bdemo` です。

プレビューでは追加されたデータがすぐには表示されないため、クエリーを実行してください:

```
SELECT * FROM `f2bdemo.testdata` LIMIT 10;
```

## インフラの削除

```
make destroy
```
