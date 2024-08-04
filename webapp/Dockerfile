FROM golang:1.22.1-bookworm as build

COPY . /workspace
RUN cd /workspace && CGO_ENABLED=0 go build -o /webapp main.go

FROM gcr.io/distroless/static-debian12:nonroot

COPY --from=build /webapp /webapp
ENTRYPOINT [ "/webapp" ]
