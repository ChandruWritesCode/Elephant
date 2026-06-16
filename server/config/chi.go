package config

import (
	"fmt"
	"net/http"

	"github.com/commandlinecoding/elephant/server/env"

	"github.com/go-chi/chi/v5"
)

type Engine struct {
	*chi.Mux
}

// global exported router instance
var App = &Engine{chi.NewRouter()}

// path-prefix, sub-routes
func (w *Engine) Group(prefix string) chi.Router {
	subRouter := chi.NewRouter()
	w.Mount(prefix, subRouter)
	return subRouter
}

// Runs the native Go HTTP server
func Run() {
	fmt.Printf("Chi Engine running on %s:%s\n", env.HOST, env.PORT)
	err := http.ListenAndServe(env.HOST+":"+env.PORT, App)
	if err != nil {
		fmt.Printf("Server failed to start: %v\n", err)
	}
}