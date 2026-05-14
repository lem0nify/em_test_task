FROM golang:1.26-alpine AS builder
WORKDIR /app
COPY . .
RUN go mod download
RUN go install github.com/swaggo/swag/cmd/swag@latest
RUN swag init
RUN go build -o ./service .

FROM alpine:3.23
WORKDIR /app
COPY --from=builder /app/service .
COPY --from=builder /app/migrations ./migrations
COPY --from=builder /app/docs ./docs
EXPOSE 8080
CMD ["./service"]