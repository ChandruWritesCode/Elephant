FROM golang:alpine3.23 AS builder

WORKDIR /app

COPY server/go.mod server/go.sum ./
RUN go mod download

COPY server/ .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o elephant-server .

FROM alpine:latest
RUN apk --no-cache add ca-certificates tzdata
WORKDIR /root/
COPY --from=builder /app/elephant-server .

COPY .env.example .env

EXPOSE 3000

CMD ["./elephant-server"]