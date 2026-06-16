package main

import (
	"github.com/commandlinecoding/elephant/server/config"
	"github.com/commandlinecoding/elephant/server/middlewares"
	"github.com/commandlinecoding/elephant/server/routes"
)

func main() {
	// db init
	config.InitDatabase()
	defer config.DB.Close()

	// app init
	app := config.App

	// middlewares
	app.Use(middlewares.SimpleLogger)

	// routes mapping using sub-groups
	routes.ApiRoute(app.Group("/api"))

	// starting the server
	config.Run()
}
