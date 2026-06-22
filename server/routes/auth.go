package routes

import (
	"github.com/commandlinecoding/elephant/server/controllers"
	"github.com/go-chi/chi/v5"
)

func AuthRoute(router chi.Router) {
	router.Post("/register", controllers.HandleRegister)
}