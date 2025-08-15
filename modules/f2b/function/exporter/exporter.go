package exporter

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"slices"

	"cloud.google.com/go/pubsub"
	"github.com/cloudevents/sdk-go/v2/event"
	"github.com/googleapis/google-cloudevents-go/cloud/firestoredata"
	"google.golang.org/protobuf/proto"
)

type Exporter struct {
	config       *ExportConfig
	pubsubClient *pubsub.Client
}

type ExportConfig struct {
	Rules map[string]*ExportRule `json:"rules"`
}

type ExportRule struct {
	Table  string   `json:"table"`
	Fields []string `json:"fields"`
	Topic  string   `json:"topic"`
}

func New(ctx context.Context, config *ExportConfig) (*Exporter, error) {
	pubsubClient, err := pubsub.NewClient(ctx, getProjectID(pubsub.DetectProjectID))
	if err != nil {
		return nil, fmt.Errorf("failed to create pubsub client: %w", err)
	}

	return &Exporter{
		config:       config,
		pubsubClient: pubsubClient,
	}, nil
}

func (e *Exporter) Close() error {
	if e.pubsubClient != nil {
		err := e.pubsubClient.Close()
		if err != nil {
			slog.Error("failed to close pubsub client", slog.String("error", err.Error()))
		}
	}
	return nil
}

// ExportHandler は Firestore からの変更イベントを受け取って BigQuery に Upsert する
func (e *Exporter) ExportHandler(ctx context.Context, event event.Event) error {
	var data firestoredata.DocumentEventData

	// If you omit `DiscardUnknown`, protojson.Unmarshal returns an error
	// when encountering a new or unknown field.
	options := proto.UnmarshalOptions{
		DiscardUnknown: true,
	}

	err := options.Unmarshal(event.Data(), &data)
	if err != nil {
		slog.ErrorContext(ctx, "failed to unmarshal event data", slog.String("error", err.Error()))
		return nil
	}

	err = e.exportToBigQuery(ctx, &data)
	if err != nil {
		slog.ErrorContext(ctx, "failed to export to bigquery", slog.String("error", err.Error()))
	}
	return nil
}

func hasIntersect(a, b []string) bool {
	for _, v := range a {
		if slices.Contains(b, v) {
			return true
		}
	}
	return false
}

func (e *Exporter) exportToBigQuery(ctx context.Context, data *firestoredata.DocumentEventData) error {
	eventType := DetectEventType(data)

	var document *firestoredata.Document
	if eventType == EventTypeDelete {
		document = data.GetOldValue()
	} else {
		document = data.GetValue()
	}

	name, err := ParseDocumentName(document.GetName())
	if err != nil {
		return err
	}

	kind := name.CollectionName

	if e.config.Rules == nil {
		slog.WarnContext(ctx, "no rules found")
		return nil
	}
	rule := e.config.Rules[kind]
	if rule == nil {
		// Nothing to do
		slog.WarnContext(ctx, "no rule found", slog.String("kind", kind))
		return nil
	}
	// 更新時には同期対象が更新されたフィールドのみを送信する
	if data.GetUpdateMask() != nil && len(rule.Fields) > 0 {
		if !hasIntersect(rule.Fields, data.GetUpdateMask().GetFieldPaths()) {
			return nil
		}
	}

	// 同期用ドキュメントの構築
	var row map[string]any
	if len(rule.Fields) > 0 {
		row = make(map[string]any, len(rule.Fields)+1)
		for _, field := range rule.Fields {
			value := document.Fields[field]
			if value == nil {
				continue
			}
			row[field] = ExtractDocumentFieldValue(value)
		}
	} else {
		// 全フィールドを対象にする
		row = make(map[string]any, len(document.Fields)+1)
		for field, value := range document.Fields {
			row[field] = ExtractDocumentFieldValue(value)
		}
	}
	// 更新条件の設定
	if eventType == EventTypeDelete {
		row["_CHANGE_TYPE"] = "DELETE"
	} else {
		row["_CHANGE_TYPE"] = "UPSERT"
	}
	body, err := json.Marshal(row)
	if err != nil {
		return fmt.Errorf("failed to marshal row: %w", err)
	}

	// データの送信
	topic := e.pubsubClient.Topic(rule.Topic)
	_, err = topic.Publish(ctx, &pubsub.Message{
		Data: body,
	}).Get(ctx)
	if err != nil {
		return fmt.Errorf("failed to publish message: %w", err)
	}

	return nil
}
