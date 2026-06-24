package routes

import (
	"github.com/commandlinecoding/elephant/server/controllers"
	"github.com/commandlinecoding/elephant/server/middlewares"
	"github.com/go-chi/chi/v5"
)

func UserRoute(router chi.Router) {
	searchLimiter := middlewares.NewRateLimiter(2.0, 10.0)

	router.Use(middlewares.AuthGuard)

	router.Get("/me", controllers.HandleGetMe)         // Resolves to /api/users/me
	router.Get("/{id}", controllers.HandleGetUserByID) // Resolves to /api/users/:id

	router.With(searchLimiter.Limit).Get("/search", controllers.HandleUserSearch) // Resolves to /api/users/search
}
