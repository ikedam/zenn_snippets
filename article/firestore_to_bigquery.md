Firestore に BigQuery を併用して強力なクエリー機能を実現する

# 概要

* Google Cloud の [Firestore](https://cloud.google.com/products/firestore?hl=ja) のデータを [BigQuery](https://cloud.google.com/bigquery?hl=ja) に同期することで、従量課金の特性を維持しつつ、強力なクエリー機能も実現しようという話題。
* Firestore から BigQuery へのデータ同期には [Cloud Pub/Sub の BigQuery サブスクリプションの機能](https://cloud.google.com/pubsub/docs/bigquery?hl=ja) を使用します。
* BigQuery の変更データキャプチャの費用やチューニング方法などに課題あり。

# 予備知識: Google Cloud Firestore

## Google Cloud Firestore とリレーショナルデータベースの用語の対応

Firestore とリレーショナルデータベース (RDB) の用語は以下のように対応付けることができます:

| Firestore    | RDB          |
|:-------------|:-------------|
| コレクション | テーブル     |
| ドキュメント | レコード     |
| フィールド   | カラム       |
| インデックス | インデックス |
| クエリー     | クエリー     |

## Google Cloud Firestore の推しポイント

[Firestore](https://cloud.google.com/products/firestore?hl=ja) はサーバーレスのドキュメントデータベースで、以下の機能を提供します:

* ドキュメントデータベースなので、アプリケーションで使用しているデータ構造体をそのまま保存できる。
    * OR マッピング的な機能が Firestore のライブラリー自体に提供されているイメージ。
    * 例えば Go 言語の場合、構造体 (struct) を直接 Firestore から取り出したり、 Firestore に保存したりできます。
        * [cloud.google.com/go/firestore#Reading](https://pkg.go.dev/cloud.google.com/go/firestore#hdr-Reading)
        * [cloud.google.com/go/firestore#func (*DocumentRef) Create](https://pkg.go.dev/cloud.google.com/go/firestore#DocumentRef.Create)
* サーバーレスなので、時間課金での費用が発生しません。実行した処理の回数に応じて費用が発生します。
    * 極端な話、システムを構築しても誰もアクセスしなければ費用が発生しません。
    * 特に以下の場合にはかなり費用を抑えることができます:
        * 小規模なシステム。例えば社内だけ、チーム内だけなどで利用するシステムでアクセス頻度が低い場合、他の時間課金のサービスよりも費用が安く済みます。
        * 常時アクセスがあるシステムではない場合。まばらにアクセスがある場合や、日中だけアクセスがあるなど。
* トランザクション機能を提供している。複雑な処理要件にも対応できます。
    * [トランザクションとバッチ書き込み  |  Firestore in Native mode  |  Google Cloud](https://cloud.google.com/firestore/native/docs/manage-data/transactions?hl=ja)

## Google Cloud Firestore の課題: 柔軟なクエリー実行ができない

Firestore では条件を指定してドキュメントを検索するクエリーを実行できますが、以下の制限があります:

* 複数のフィールドを条件やソート条件に指定する場合、検索条件に対応したインデックスを先に定義しておく必要がある。
    * [インデックスの管理  |  Firestore in Native mode  |  Google Cloud](https://cloud.google.com/firestore/native/docs/query-data/indexing?hl=ja)
    * あるコレクションを様々な条件で検索したい場合、検索条件ごとにインデックスを作成しておく必要がある。
    * 一般的な RDB ではインデックスを作っていないカラムであっても、性能が落ちるだけで条件に指定してクエリーを実行できるが、Firestore の場合はインデックスを作っていないフィールド(の組み合わせ)でクエリーを実行するとエラーになる。
* OR 条件や in 演算子で指定できる条件は 30 個まで。
    * [データのクエリとフィルタ  |  Firestore in Native mode  |  Google Cloud#OR クエリの上限](https://cloud.google.com/firestore/native/docs/query-data/queries?hl=ja#limits_on_or_queries)
* 条件に指定したフィールドが存在しないドキュメントは検索対象にならない。
    * [データのクエリとフィルタ  |  Firestore in Native mode  |  Google Cloud#OR クエリの上限#orderBy とフィールドの存在](https://cloud.google.com/firestore/native/docs/query-data/queries?hl=ja#orderby_and_existence)
    * ドキュメントに検索条件になる新しいフィールドを追加したときに、過去のドキュメントを検索できない。
* Join に相当する操作ができない。
    * 別のコレクションに対するクエリーを並列実行してアプリケーションで結果を結合する、前のクエリーの結果から次のクエリーを構築してクエリーを直列実行するなどの対応が必要。
* GROUP BY に相当する集計クエリーがない。
    * 効率よくあるフィールドの値域を取得することが難しい。

課題、できない、といった否定的な表現をしてはいるものの、実際にはいずれも Firestore の欠点というよりは特性であって、また、柔軟なクエリー実行ができないというよりは実行するクエリーについて事前に計画立てておかないといけないという製品特性と考えるのが適切です。

一方で、Firestore の強みを活かしつつ、柔軟に(無計画にとも言える)クエリーも実行できるといいのになあ、と思うことがあります。

# BigQuery を用いたクエリー実行

[BigQuery](https://cloud.google.com/bigquery?hl=ja) は大容量データのデータ分析を行うための製品で、以下の特徴を持ちます:

* RDB と同様のテーブル構造でのデータ格納
* SQL による柔軟なクエリー機能
* インデックスが不要
    * というよりも、インデックスという機能がない。
* 処理データ量に応じた課金 (従量課金)
    * クエリーで処理したバイト数に応じた費用が課金されます。
    * 正確には「オンデマンド料金」「容量料金(以前は定額課金と言っていたと思う)」の2つの料金コースがあり、デフォルトのオンデマンド料金想定での記述です。
* 変更データキャプチャによるリアルタイムでのデータ更新が可能。
    * [変更データ キャプチャを使用してテーブル更新をストリーミングする  |  BigQuery  |  Google Cloud](https://cloud.google.com/bigquery/docs/change-data-capture?hl=ja)
    * どこまでリアルタイム性を確保するかはドキュメントに記載の通り `max_staleness` オプションで調整する。性能・費用にかかわるチューニングパラメーターになる様子。


Firestore と比較すると、以下のような差異があります:

* Firestore のほうが高速
    * BigQuery が低速と言うよりも、速度を重視した製品ではないという表現が妥当。
    * 処理内容にもよるが Firestore が数十ミリ秒単位の応答時間を期待できるサービス(要出典)なのに対して、 BigQuery では秒単位の応答時間がかかることも想定しないといけない。
* Firestore は処理対象にしたドキュメント単位での課金。BigQuery はクエリーのたびにすべてのレコードが処理対象になる。

これらを整理し、以下のような形で Firestore と BigQuery を併用するアーキテクチャーを考えます:

* アプリケーションのメインデータベースとしては Firestore を使用する。
    * BigQuery をメインデータベースに使うのは性能・費用の点から適切でない。
    * 特にここで言う性能は、ユーザー体験の観点での性能。
* 複雑なクエリーについては BigQuery を使用する。


# Firestore から BigQuery へのデータ同期方法

Firestore のデータを BigQuery に反映する (BigQuery からクエリーする) 方法はいくつか考えられます。

1. インポート: Firestore のエクスポートデータを BigQuery にロードする
    * [Firestore エクスポートからのデータの読み込み  |  BigQuery  |  Google Cloud](https://cloud.google.com/bigquery/docs/loading-data-cloud-firestore?hl=ja)

2. Firebase: Firebase extension の [Stream Firestore to BigQuery](https://extensions.dev/extensions/firebase/firestore-bigquery-export) を使用して Firestore の変更を BigQuery に同期する。

3. CDC: [Firestore の更新イベント](https://cloud.google.com/eventarc/docs/run/route-trigger-cloud-firestore?hl=ja) で Cloud Run functions を起動し、[変更データキャプチャ(CDC)](https://cloud.google.com/bigquery/docs/change-data-capture?hl=ja) で BigQuery に差分更新を行う。

4. Pub/Sub: [Firestore の更新イベント](https://cloud.google.com/eventarc/docs/run/route-trigger-cloud-firestore?hl=ja) で Cloud Run functions を起動し、Cloud Pub/Sub の [BigQuery サブスクリプション](https://cloud.google.com/pubsub/docs/bigquery?hl=ja) で BigQuery に差分更新を行う。


各方法の比較:

|                |インポート|Firebase|CDC|Pub/Sub|
|:---------------|:--------:|:------:|:-:|:-----:|
|データの即時反映|          |X       |X  |X      |
|Firebase 不要   |X         |        |X  |X      |
|実装コスト      |中        |小      |大 |中     |

今回は以下の理由から、 4 の Cloud Pub/Sub の BigQuery サブスクリプションの方法を採用しました。

* 1 のインポート方式はアプリケーションからのクエリーの利用のために定期的にエクスポート・インポートを行う仕組みの開発が必要で、どうせ開発作業があるならばデータが即時反映される他の方法を取ったほうが有利であること。
    * 他の方式に比べて仕組み自体がシンプルに収まるので、頻繁に行わない手作業での分析用途などであればインポート方式は検討に値すると思います。
* 今回開発しているアプリケーションでは Firebase を使用していないこと、また、IaC での構成管理が難しいことから、2 の Firebase extension 方式は採用しない。
    * ただし、たぶん内部的には 3 の変更データキャプチャの実装を Firebase の開発チームがしっかり行ったものなので、高い品質を期待できる。
    * [firebase-bigquery-export](https://github.com/firebase/extensions/tree/master/firestore-bigquery-export) のコードを自分でデプロイすれば Firebase に依存せずに利用できると思う。
* 変更データキャプチャの実装が難易度が高いと判明したため、 3 変更データキャプチャ は採用しなかった。
    * [BigQuery Storage Write API](https://cloud.google.com/bigquery/docs/write-api?hl=ja) を使用するのだが、書き込みデータを Protocol Buffer にエンコードする必要があり、実装はかなり煩雑になる。
    * また、今回開発しているアプリケーションに Go 言語を採用してるのだが、Go 言語で提供されている変更データキャプチャのライブラリーが BigQuery テーブルのスキーマから Protocol Buffer の定義を自動生成すると `CHANGE_TYPE` を設定できず、UPSERT / DELETE の切り替えを行えなかった。
        * cloud.google.com/go/bigquery v1.69.0 での話。
        * 様々なコレクション・テーブルに適用できる汎用的な仕組みにしたかったため、スキーマ定義をハードコーディングする設計は避けたかった。
    * さらに、エラーハンドリングやリトライについての設計も必要なので実装コストが非常に高く付くと判断した。
    * 別の開発言語であればもう少し実装は容易かも。

# BigQuery サブスクリプションを使用した Firestore から BigQuery への同期

実装コード (あまり整理していない)

https://github.com/ikedam/zenn_snippets/tree/firestore_to_bigquery

以下の仕組みで Firestore の更新イベントを BigQuery に同期します:

1. Firestore からの更新イベントを Eventarc で取得する。
    * [Eventarc でサポートされている Google イベントタイプ  |  Google Cloud#Cloud Firestore](https://cloud.google.com/eventarc/docs/event-types?hl=ja#cloud-firestore)
        * `google.cloud.firestore.document.v1.written` イベントを受け取る。
    * [Cloud Firestore イベントを Cloud Run に転送する  |  Eventarc  |  Google Cloud](https://cloud.google.com/eventarc/docs/run/route-trigger-cloud-firestore?hl=ja)

2. Eventarc から Cloud Run functions を起動する。
    * なお、内部的には Eventarc → Pub/Sub トピック → Pub/Sub サブスクリプション → Cloud Run functions というパスが構成される。
    * Pub/Sub の トピック / Subscription は自動で作成されるため、 Terraform などでリトライなどのパラメーター調整ができないのが難点。

3. Cloud Run functions で Protocol Buffer フォーマットで届くメッセージをパース、BigQuery に書き込みたいフィールドを抽出して JSON データとして構成し、 Pub/Sub トピック に送信する。
    * [Firestore トリガー  |  Cloud Run functions Documentation  |  Google Cloud](https://cloud.google.com/functions/docs/calling/cloud-firestore?hl=ja)
    * 無関係なフィールドの変更の場合はイベントを無視する。
    * イベント内容に従って UPSERT / DELETE を決定する。

4. [BigQuery サブスクリプション](https://cloud.google.com/pubsub/docs/bigquery?hl=ja) を設定した Pub/Sub トピックで BigQuery テーブルの更新を行う。

5. 更新対象の BigQuery テーブル。
    * 変更データキャプチャでの更新用にプライマリーキーを設定する必要がある。
        * [変更データ キャプチャを使用してテーブル更新をストリーミングする  |  BigQuery  |  Google Cloud#前提条件](https://cloud.google.com/bigquery/docs/change-data-capture?hl=ja#prerequisites)

FIXME: アーキテクチャー図を貼る。


# 残っている課題

* Pub/Sub トピックに transform という機能があるようなので、実は Cloud Run functions を不要にできるのではないか。(未検証)
    * ただし Eventarc からのイベントが Protocol Buffer 形式で届くので、それを transform で処理できるのかが不明。
* BigQuery サブスクリプションでエラーが発生した場合に何が起きるのかが不明。処理の成否の確認方法や、モニタリングの方法が分からない。
* BigQuery サブスクリプションに送る JSON データに BigQuery テーブルの全カラムが含まれていない場合、含まれていなかったカラムが NULL で上書きされてしまう。(あまりちゃんと検証していない)
* BigQuery サブスクリプション作成後に BigQuery テーブルを再作成すると、 BigQuery サブスクリプションから BigQuery テーブルへの接続が再構成されない様子。 (あまりちゃんと検証していない)
    * スキーマ変更などで BigQuery テーブルが再作成される場合、 BigQuery サブスクリプションを再構成するように Terraform を構成する必要がありそう。
* 何らかの理由で Firestore と BigQuery の同期がズレた場合の再同期の方法が未確認。
    * 変更データキャプチャーを優子にしていると DML ステートメントが使えなくなるとのことなので、インポートと同等の仕組みで最新のスナップショットを上書きする事ができない。
        * [変更データ キャプチャを使用してテーブル更新をストリーミングする  |  BigQuery  |  Google Cloud#制限事項](https://cloud.google.com/bigquery/docs/change-data-capture?hl=ja#limitations)
* BigQuery で変更データキャプチャを行ったときの費用影響が結局よく分からない。そのため、 `max_staleness` をどうチューニングするのが良いかが不明。
    * [変更データ キャプチャを使用してテーブル更新をストリーミングする  |  BigQuery  |  Google Cloud](https://cloud.google.com/bigquery/docs/change-data-capture?hl=ja)
    * `max_staleness` のチューニングが性能・費用に影響するらしい。
    * `max_staleness` で設定した周期でまとめてストリーミングバッファの反映処理が行われるようになるのだが、この反映処理では、 **全パーティションのスキャンが行われる** というように読めるのだがいまいちはっきり分からない。
    * 特に `max_staleness` を設定しない場合、都度クエリー実行のたびにストリーミングバッファの反映処理が実行される。その分、応答時間が伸び、また、前述の全パーティションのスキャンが行われるため、費用がかさむ。
    * この反映処理が、ストリーミングバッファが空の場合でも発生するのかどうかがよく分からない。
        * そもそも「空」という概念があるのかも不明。
        * 空の場合は処理がスキップされるのであれば、更新頻度によっては費用影響は十分小さく見積もれる。


# 補足

* 本稿で言及している費用は、Firestore、 BigQuery のいずれについてもコンピュート費用のことを示しており、別途、ストレージ費用がかかります。
    * ストレージ費用は保存容量と保存期間で費用がかかるため、時間課金での費用になります。
* システムの規模がある程度大きくなる場合は、従量課金の Firestore よりも時間課金の他のサービスのほうが安くつきます。以下の記事が参考になります:
    * [Spanner は本当に高い？思ったよりも低い Firestore との損益分岐点](https://zenn.dev/apstndb/articles/spanner-cost-comparison-firestore)
    * [Firestore → Cloud SpannerでDBコスト93%削減！無停止でやり切った 1 年間の全記録](https://zenn.dev/kauche/articles/1e733da3748ee1)
