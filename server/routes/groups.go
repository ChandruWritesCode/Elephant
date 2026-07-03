package routes

import (
	"github.com/commandlinecoding/elephant/server/controllers"
	"github.com/commandlinecoding/elephant/server/middlewares"
	"github.com/go-chi/chi/v5"
)

func GroupRoute(router chi.Router) {
	router.Use(middlewares.AuthGuard)

	router.Post("/", controllers.HandleCreateGroup) // POST /api/groups
	router.Get("/", controllers.HandleListMyGroups) // GET /api/groups

	router.Route("/{id}", func(sr chi.Router) {
		sr.Use(middlewares.GroupAuthGuard)

		sr.Get("/messages", controllers.HandleGetGroupMessages) // GET /api/groups/{id}/messages
		sr.Get("/members", controllers.HandleListGroupMembers)   // GET /api/groups/{id}/members

		sr.With(middlewares.GroupAdminGuard).Post("/members", controllers.HandleAddMember) // POST /api/groups/{id}/members
		sr.With(middlewares.GroupAdminGuard).Delete("/members/{userId}", controllers.HandleRemoveMember) // DELETE /api/groups/{id}/members/{userId}
	})
}
