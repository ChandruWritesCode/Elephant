package routes

import (
	"github.com/commandlinecoding/elephant/server/controllers"
	"github.com/commandlinecoding/elephant/server/middlewares"
	"github.com/go-chi/chi/v5"
)

func E2EERoute(router chi.Router) {
	router.Use(middlewares.AuthGuard)

	router.Post("/keys", controllers.HandleUploadE2EEKeys)
	router.Get("/bundle/{userId}", controllers.HandleGetPrekeyBundle)

	router.Post("/verify", controllers.HandleSetVerification)
	router.Get("/verify/{userId}", controllers.HandleGetVerificationStatus)

	router.Post("/reset", controllers.HandleResetKeys)
}
