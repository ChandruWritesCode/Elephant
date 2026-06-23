package routes

import (
	"github.com/commandlinecoding/elephant/server/controllers"
	"github.com/commandlinecoding/elephant/server/middlewares"
	"github.com/go-chi/chi/v5"
)

func MessageRoute(router chi.Router) {
	router.Use(middlewares.AuthGuard)
	router.Post("/", controllers.HandleSendMessage) // Resolves to POST /api/messages
}