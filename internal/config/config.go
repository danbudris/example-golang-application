package config

import (
	"os"
	"time"
)

const (
	defaultPort            = "8080"
	defaultHost            = "0.0.0.0"
	defaultShutdownTimeout = 30 * time.Second
)

// Config holds all configuration for the application
type Config struct {
	Host            string
	Port            string
	ShutdownTimeout time.Duration
}

// Load creates a new Config from environment variables with defaults
func Load() *Config {
	port := os.Getenv("PORT")
	if port == "" {
		port = defaultPort
	}

	host := os.Getenv("HOST")
	if host == "" {
		host = defaultHost
	}

	shutdownTimeout := defaultShutdownTimeout
	if timeoutStr := os.Getenv("SHUTDOWN_TIMEOUT"); timeoutStr != "" {
		if timeout, err := time.ParseDuration(timeoutStr); err == nil {
			shutdownTimeout = timeout
		}
	}

	return &Config{
		Host:            host,
		Port:            port,
		ShutdownTimeout: shutdownTimeout,
	}
}
