package server

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"github.com/example/example-golang-application/internal/config"
	"github.com/example/example-golang-application/internal/handlers"
)

// Server wraps an HTTP server with application-specific configuration
type Server struct {
	httpServer *http.Server
	config     *config.Config
}

// New creates a new Server instance
func New(cfg *config.Config) *Server {
	mux := http.NewServeMux()

	// Register handlers
	handlers.RegisterRoutes(mux)

	httpServer := &http.Server{
		Addr:         fmt.Sprintf("%s:%s", cfg.Host, cfg.Port),
		Handler:      mux,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	return &Server{
		httpServer: httpServer,
		config:     cfg,
	}
}

// Start starts the HTTP server
func (s *Server) Start() error {
	if err := s.httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		return err
	}
	return nil
}

// Shutdown gracefully shuts down the HTTP server
func (s *Server) Shutdown(ctx context.Context) error {
	return s.httpServer.Shutdown(ctx)
}
