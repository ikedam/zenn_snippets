Zenn記事用のコード置き場。
ブランチを作ってコードを置く。
https://zenn.dev/ikedam

# archive_file によるソースコードの変更検知のデモ

## ソースコードのアーカイブの作成

```
make terraform-init terraform-plan
```

## ソースコードのアーカイブの中身の確認

アーカイブの作成後に

```
zipinfo source.zip
```
