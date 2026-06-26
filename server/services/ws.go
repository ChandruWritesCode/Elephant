package services

import (
	"context"
	"encoding/json"
	"log"
	"sync"
	"time"

	"github.com/commandlinecoding/elephant/server/models"
	"github.com/commandlinecoding/elephant/server/repository"
	"github.com/gorilla/websocket"
)

type WSClient struct {
	UserID string
	Conn   *websocket.Conn
	Send   chan []byte
}

type WSHub struct {
	clients    map[string]*WSClient
	Register   chan *WSClient
	Unregister chan *WSClient
	mu         sync.RWMutex
}

var Hub = &WSHub{
	clients:    make(map[string]*WSClient),
	Register:   make(chan *WSClient),
	Unregister: make(chan *WSClient),
}

func (h *WSHub) Run() {
	for {
		select {
		case client := <-h.Register:
			h.mu.Lock()
			h.clients[client.UserID] = client
			h.mu.Unlock()

		case client := <-h.Unregister:
			h.mu.Lock()
			if _, exists := h.clients[client.UserID]; exists {
				delete(h.clients, client.UserID)
				close(client.Send)
			}
			h.mu.Unlock()
		}
	}
}

func (c *WSClient) ReadPump() {
	defer func() {
		Hub.Unregister <- c
		c.Conn.Close()
	}()

	c.Conn.SetReadLimit(4096)
	_ = c.Conn.SetReadDeadline(time.Now().Add(60 * time.Second))
	c.Conn.SetPongHandler(func(string) error {
		_ = c.Conn.SetReadDeadline(time.Now().Add(60 * time.Second))
		return nil
	})

	msgRepo := repository.NewMessageRepository()

	for {
		_, bytes, err := c.Conn.ReadMessage()
		if err != nil {
			break
		}

		var incoming models.WSMessage
		if err := json.Unmarshal(bytes, &incoming); err != nil {
			continue
		}

		if incoming.Type == "chat" {
			incoming.SenderID = c.UserID
			incoming.Timestamp = time.Now()

			go func(msg models.WSMessage) {
				_, err := msgRepo.CreateMessage(context.Background(), msg.SenderID, msg.ReceiverID, msg.Content)
				if err != nil {
					log.Printf("Async DB write failure: %v", err)
					return
				}
			}(incoming)

			outboundBytes, _ := json.Marshal(incoming)
			Hub.mu.RLock()
			targetClient, online := Hub.clients[incoming.ReceiverID]
			Hub.mu.RUnlock()

			// Hub.mu.RLock()
			// targetClient, online = Hub.clients[incoming.ReceiverID]
			// Hub.mu.RUnlock()

			if online {
				select {
				case targetClient.Send <- outboundBytes:
				default:
					Hub.Unregister <- targetClient
					targetClient.Conn.Close()
				}
			}
		}
	}
}

func (c *WSClient) WritePump() {
	ticker := time.NewTicker(54 * time.Second)
	defer func() {
		ticker.Stop()
		c.Conn.Close()
	}()

	for {
		select {
		case message, ok := <-c.Send:
			_ = c.Conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if !ok {
				_ = c.Conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			w, err := c.Conn.NextWriter(websocket.TextMessage)
			if err != nil {
				return
			}
			_, _ = w.Write(message)

			if err := w.Close(); err != nil {
				return
			}

		case <-ticker.C:
			_ = c.Conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if err := c.Conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}
