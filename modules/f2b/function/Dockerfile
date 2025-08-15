FROM golang:1.23.8-bookworm AS build

WORKDIR /workspace
COPY . .
RUN go build -o /f2b ./main.go

# FROM gcr.io/distroless/base-debian12:nonroot
FROM gcr.io/distroless/base-debian12:debug-nonroot

ENV FUNCTION_TARGET=firestoreToBigQuery
COPY --from=build /f2b /f2b

EXPOSE 8080
ENTRYPOINT ["/f2b"]
