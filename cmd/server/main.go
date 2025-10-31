package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/example/example-golang-application/internal/config"
	"github.com/example/example-golang-application/internal/server"
)

func main() {
	// Load configuration
	cfg := config.Load()

	// Create and start server
	srv := server.New(cfg)

	// Start server in a goroutine
	go func() {
		log.Printf("Server starting on %s:%s", cfg.Host, cfg.Port)
		if err := srv.Start(); err != nil {
			log.Fatalf("Server failed to start: %v", err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Server shutting down...")

	// Graceful shutdown with timeout
	ctx, cancel := context.WithTimeout(context.Background(), cfg.ShutdownTimeout)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}

	log.Println("Server exited")
}
