package routes

import (
	"github.com/commandlinecoding/elephant/server/controllers"
	"github.com/go-chi/chi/v5"
)

func ApiRoute(router chi.Router) {
	router.Get("/health", controllers.HandleHealthCheck) // resolves to /api/health
	router.Get("/ws", controllers.HandleWSUpgrade)

	router.Route("/auth", AuthRoute)
	router.Route("/users", UserRoute)
	router.Route("/messages", MessageRoute)
}
