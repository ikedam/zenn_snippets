Zenn記事用のコード置き場。
ブランチを作ってコードを置く。
https://zenn.dev/ikedam

# gcloud_client_config の問題点の再現確認

gcloud_client_config を注意して使わないと困る点を確認するためのテンプレートです。
リソースは特に何も作成しません。
生成される terraform.tfstate にはセンシティブな情報が格納されるので、取り扱いに注意してください。


* 実行に適当な Google Cloud プロジェクトが必要なので設定してください (`gcloud config set project` で設定済みの場合はスキップ可能):

    * Linux / Mac

        ```
        export CLOUDSDK_CORE_PROJECT=your-project-id
        ```

    * Windows (Powershell想定)

        ```
        $ENV:CLOUDSDK_CORE_PROJECT="your-project-id"
        ```

* 初期化

    ```
    docker compose run --rm terraform init
    ```

* 実行

    ```
    docker compose run --rm terraform apply
    ```

* gcloud_client_config が作成するデータの内容の確認

    ```
    jq -r '.resources[]|select(.type=="google_client_config")|.instances[].attributes' terraform.tfstate
    ```

* 作成したデータの削除

    ```
    docker compose run --rm terraform destroy
    ```
