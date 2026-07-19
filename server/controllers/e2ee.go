package controllers

import (
	"encoding/json"
	"net/http"

	"github.com/commandlinecoding/elephant/server/middlewares"
	"github.com/commandlinecoding/elephant/server/models"
	"github.com/commandlinecoding/elephant/server/services"
	"github.com/go-chi/chi/v5"
)

func HandleUploadE2EEKeys(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	uid, _ := r.Context().Value(middlewares.UserIDKey).(string)

	var req models.UploadKeysReq
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(models.JSONResponse{Success: false, Error: "Malformatted JSON configuration payload structure"})
		return
	}

	if req.DeviceID == "" {
		req.DeviceID = "main"
	}

	svc := services.NewE2EEService()
	if err := svc.UploadKeys(r.Context(), uid, req); err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		_ = json.NewEncoder(w).Encode(models.JSONResponse{Success: false, Error: err.Error()})
		return
	}

	_, lowKeys, _ := svc.CheckKeysExhaustion(r.Context(), uid, req.DeviceID)

	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(models.JSONResponse{
		Success: true,
		Data: map[string]interface{}{
			"message":         "Prekey cryptographical parameters saved successfully",
			"requires_refill": lowKeys,
		},
	})
}

func HandleGetPrekeyBundle(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	targetUID := chi.URLParam(r, "userId")
	deviceID := r.URL.Query().Get("device_id")

	if targetUID == "" {
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(models.JSONResponse{Success: false, Error: "Target Identity validation token reference required"})
		return
	}

	if deviceID == "" {
		deviceID = "main"
	}

	svc := services.NewE2EEService()
	bundle, err := svc.GetBundle(r.Context(), targetUID, deviceID)
	if err != nil {
		w.WriteHeader(http.StatusNotFound)
		_ = json.NewEncoder(w).Encode(models.JSONResponse{Success: false, Error: err.Error()})
		return
	}

	_ = json.NewEncoder(w).Encode(models.JSONResponse{Success: true, Data: bundle})
}
