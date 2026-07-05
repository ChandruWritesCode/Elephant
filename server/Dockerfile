FROM golang:1.26-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o elephant-server .

FROM alpine:3.20

RUN apk --no-cache add ca-certificates tzdata

RUN addgroup -S appgroup && adduser -S appuser -G appgroup
WORKDIR /app

COPY --from=builder /app/elephant-server .

RUN chown -R appuser:appgroup /app
USER appuser

EXPOSE 3000

CMD ["./elephant-server"]