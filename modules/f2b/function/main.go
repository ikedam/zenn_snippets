package main

import (
	"context"
	"encoding/json"
	"log/slog"
	"os"

	"github.com/GoogleCloudPlatform/functions-framework-go/funcframework"
	"github.com/GoogleCloudPlatform/functions-framework-go/functions"
	"github.com/damsys/baseport/functions/f2b/exporter"
)

func main() {
	ctx := context.Background()

	slog.SetDefault(slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		ReplaceAttr: func(groups []string, a slog.Attr) slog.Attr {
			// https://cloud.google.com/logging/docs/reference/v2/rest/v2/LogEntry#logseverity
			if a.Key == slog.LevelKey {
				return slog.Attr{
					Key:   "severity",
					Value: a.Value,
				}
			}
			return a
		},
		Level: slog.LevelDebug,
	})))

	exportConfigStr := os.Getenv("EXPORT_CONFIG")
	if exportConfigStr == "" {
		exportConfigStr = "{}"
	}
	exportConfig := exporter.ExportConfig{}
	if err := json.Unmarshal([]byte(exportConfigStr), &exportConfig); err != nil {
		slog.ErrorContext(ctx, "failed to unmarshal export config", slog.String("error", err.Error()))
		panic(err)
	}
	exporter, err := exporter.New(ctx, &exportConfig)
	if err != nil {
		slog.ErrorContext(ctx, "failed to create exporter", slog.String("error", err.Error()))
		panic(err)
	}
	functions.CloudEvent("firestoreToBigQuery", exporter.ExportHandler)

	// Use PORT environment variable, or default to 8080.
	port := "8080"
	if envPort := os.Getenv("PORT"); envPort != "" {
		port = envPort
	}

	// By default, listen on all interfaces. If testing locally, run with
	// LOCAL_ONLY=true to avoid triggering firewall warnings and
	// exposing the server outside of your own machine.
	hostname := ""
	if localOnly := os.Getenv("LOCAL_ONLY"); localOnly == "true" {
		hostname = "127.0.0.1"
	}
	if err := funcframework.StartHostPort(hostname, port); err != nil {
		slog.ErrorContext(ctx, "failed to start host port", slog.String("error", err.Error()))
		panic(err)
	}
}
