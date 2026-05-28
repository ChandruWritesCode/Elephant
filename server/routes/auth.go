package routes

import (
	"github.com/commandlinecoding/elephant/server/controllers"
	"github.com/go-chi/chi/v5"
)

func AuthRoute(router chi.Router) {
	router.Get("/", controllers.HandleAuth) // resolves to /api/auth/
	// will be done in future!
}
