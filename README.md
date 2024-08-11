Zenn記事用のコード置き場。
ブランチを作ってコードを置く。
https://zenn.dev/ikedam

# DockerイメージをTerraformでデプロイする(GCP編)

## ウェブアプリケーションのローカルでの実行

1. イメージをビルド

    ```console
    docker build -t webapp ./webapp
    ```

2. 実行

    ```console
    docker run --rm -it -p 8080:8080 webapp
    ```

3. http://localhost:8080/ にアクセス

## デプロイ

デモなのでtfstateファイルがローカルに作成されます。
tfstateファイルにArtifact Registryにアクセスするためのサービスアカウントのプライベートキーが格納されるため、
実際の運用では適切なbackendを使用してファイルをリモートにおいてアクセス制限をかけてください。

* 環境変数で使用するGCPプロジェクトを指定

    * Linux / Mac の場合

        ```
        export CLOUDSDK_CORE_PROJECT=your_gcp_project
        ```

    * Windows の場合 (Powershell を想定)

        ```
        ${ENV:CLOUDSDK_CORE_PROJECT}="your_gcp_project"
        ```


* 初期化

    ```
    docker compose run --rm terraform init
    ```

* 構築

    ```
    docker compose run --rm terraform apply
    ```

* 削除

    ```
    docker compose run --rm terraform destroy
    ```

