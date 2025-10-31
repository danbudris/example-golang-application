package handlers

import (
	"fmt"
	"net/http"
)

// RegisterRoutes registers all HTTP routes with the given mux
func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/", handleRoot)
	mux.HandleFunc("/health", handleHealth)
}

// handleRoot handles requests to the root path
func handleRoot(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, `{"message":"Welcome to Example Golang Application","status":"ok"}`)
}

// handleHealth handles health check requests
func handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, `{"status":"healthy"}`)
}
