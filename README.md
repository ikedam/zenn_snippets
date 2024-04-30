Zenn記事用のコード置き場。
ブランチを作ってコードを置く。
https://zenn.dev/ikedam

# DockerイメージをTerraformでデプロイする(AWS編)

## Lambdaイメージのローカルでの実行

参考: https://docs.aws.amazon.com/ja_jp/lambda/latest/dg/go-image.html

1. イメージをビルド

    ```console
    docker build -t lambda ./lambda
    ```

2. 実行

    ```console
    docker run --rm -it -p 9000:8080 --entrypoint /usr/local/bin/aws-lambda-rie lambda /lambda
    ```

3. 呼び出し

    ```console
    curl "http://localhost:9000/2015-03-31/functions/function/invocations" -d '{}'
    ```

## デプロイ

デモなのでtfstateファイルがローカルに作成されます。
tfstateファイルにECRにアクセスするためのトークンが格納されるため、
実際の運用では適切なbackendを使用してファイルをリモートにおいてアクセス制限をかけてください。

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

