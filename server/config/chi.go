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
	fmt.Printf("Chi Engine running on %s:%s",env.HOST,env.PORT)
	err := http.ListenAndServe(env.HOST + ":" + env.PORT, App)
	if err != nil {
		fmt.Printf("Server failed to start: %v\n", err)
	}
		
	
}












// type App struct {
// 	router http.Handler
// }


// func init() {
// 	// have to config;
// }

// func (a *App) Run(ctx context.Context) error {
// 	server := &http.Server{
// 		Addr: ":3000",
// 		Handler: a.router,
// 	}

// 	err := server.ListenAndServe()
// 	if err != nil {
// 		return  fmt.Errorf("failed to start server: %w", err)
// 	}

// 	return  nil
// }