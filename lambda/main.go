package main

import (
	"context"
	"net/http"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

type LambdaResponse struct {
	StatusCode        int                 `json:"statusCode"`
	Body              string              `json:"body"`
	Headers           map[string]string   `json:"headers,omitempty"`
	MultiValueHeaders map[string][]string `json:"multiValueHeaders,omitempty"`
	IsBase64Encoded   bool                `json:"isBase64Encoded,omitempty"`
}

func HandleRequest(ctx context.Context, event events.APIGatewayProxyRequest) (*LambdaResponse, error) {
	return &LambdaResponse{
		StatusCode: http.StatusOK,
		Body:       "Hello, World!",
	}, nil
}

func main() {
	lambda.Start(HandleRequest)
}
