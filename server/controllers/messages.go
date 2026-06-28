package controllers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/commandlinecoding/elephant/server/middlewares"
	"github.com/commandlinecoding/elephant/server/models"
	"github.com/commandlinecoding/elephant/server/repository"
	"github.com/commandlinecoding/elephant/server/services"
)

type SendMessageReq struct {
	ReceiverID string `json:"receiver_id"`
	Content    string `json:"content"`
}

func HandleSendMessage(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	senderID, ok := r.Context().Value(middlewares.UserIDKey).(string)
	if !ok {
		w.WriteHeader(http.StatusUnauthorized)
		_ = json.NewEncoder(w).Encode(models.JSONResponse{Success: false, Error: "Unauthorized context"})
		return
	}

	var req SendMessageReq
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(models.JSONResponse{Success: false, Error: "Invalid json payload structure"})
		return
	}

	if req.ReceiverID == "" {
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(models.JSONResponse{Success: false, Error: "Receiver identity token required"})
		return
	}

	svc := services.NewMessageService()
	msg, err := svc.SendMessage(r.Context(), senderID, req.ReceiverID, req.Content)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(models.JSONResponse{Success: false, Error: err.Error()})
		return
	}

	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(models.JSONResponse{Success: true, Data: msg})
}

func HandleGetChatHistory(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	uid, _ := r.Context().Value(middlewares.UserIDKey).(string)
	targetUser := r.URL.Query().Get("with")
	beforeStr := r.URL.Query().Get("before")
	limitStr := r.URL.Query().Get("limit")

	if targetUser == "" {
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(models.JSONResponse{Success: false, Error: "Missing target 'with' user query constraint"})
		return
	}

	limit, _ := strconv.Atoi(limitStr)
	if limit <= 0 || limit > 100 {
		limit = 50 // Reference requirement ceiling limit mapping
	}

	before := time.Now()
	if beforeStr != "" {
		if t, err := time.Parse(time.RFC3339, beforeStr); err == nil {
			before = t
		}
	}

	repo := repository.NewMessageRepository()
	history, err := repo.GetChatHistory(r.Context(), uid, targetUser, before, limit)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		_ = json.NewEncoder(w).Encode(models.JSONResponse{Success: false, Error: "Failed to pull chat logs"})
		return
	}

	_ = json.NewEncoder(w).Encode(models.JSONResponse{Success: true, Data: history})
}

func HandleGetConversations(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	uid, ok := r.Context().Value(middlewares.UserIDKey).(string)
	if !ok {
		w.WriteHeader(http.StatusUnauthorized)
		_ = json.NewEncoder(w).Encode(models.JSONResponse{Success: false, Error: "Unauthorized context"})
		return
	}

	repo := repository.NewMessageRepository()
	list, err := repo.GetConversations(r.Context(), uid)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		_ = json.NewEncoder(w).Encode(models.JSONResponse{Success: false, Error: "Failed to compile inbox conversations"})
		return
	}

	_ = json.NewEncoder(w).Encode(models.JSONResponse{Success: true, Data: list})
}

type ReadReceiptReq struct {
	SenderID string `json:"sender_id"`
}

func HandleMarkRead(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	uid, _ := r.Context().Value(middlewares.UserIDKey).(string)

	var req ReadReceiptReq
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(models.JSONResponse{Success: false, Error: "Invalid payload layout"})
		return
	}

	if req.SenderID == "" {
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(models.JSONResponse{Success: false, Error: "Sender identification missing"})
		return
	}

	repo := repository.NewMessageRepository()
	if err := repo.MarkAsRead(r.Context(), uid, req.SenderID); err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		_ = json.NewEncoder(w).Encode(models.JSONResponse{Success: false, Error: "Failed to clear unread receipts"})
		return
	}

	_ = json.NewEncoder(w).Encode(models.JSONResponse{Success: true, Data: "Target messages marked read successfully"})
}
