package routes

import (
	"github.com/commandlinecoding/elephant/server/controllers"
	"github.com/go-chi/chi/v5"
)

func UserRoute(router chi.Router) {
	router.Get("/", controllers.HandleUsers) // resolves to /api/users
}
