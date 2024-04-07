FROM golang:1.22.1-bookworm as build

COPY . /workspace
RUN cd /workspace && go build -o /lambda main.go

FROM public.ecr.aws/lambda/provided:al2023

COPY --from=build /lambda /lambda
ENTRYPOINT [ "./main" ]
