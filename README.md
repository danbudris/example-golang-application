# Example Golang Application

A production-ready Golang HTTP web server application with Docker and Kubernetes support.

## Features

- **Modern Go Structure**: Uses Go modules and Go 1.21+
- **Cross-Compilation**: Build for multiple OS/ARCH combinations
- **Docker Support**: Multi-stage Dockerfile for optimized container images
- **Kubernetes Ready**: Includes Pod and Deployment manifests with health checks
- **Graceful Shutdown**: Proper signal handling for clean shutdowns
- **Health Endpoints**: Built-in `/health` endpoint for monitoring
- **In-Container Debugging**: Full support for debugging with Delve and VS Code

## Prerequisites

- Go 1.21 or later ([Download](https://golang.org/dl/))
- Make (usually pre-installed on macOS/Linux)
- Docker (for container builds)
- kubectl (for Kubernetes deployment, optional)

## Project Structure

```
.
├── cmd/
│   └── server/
│       └── main.go      # Application entry point
├── internal/
│   ├── config/          # Configuration management
│   │   └── config.go
│   ├── handlers/        # HTTP request handlers
│   │   └── handlers.go
│   └── server/          # HTTP server setup and lifecycle
│       └── server.go
├── go.mod               # Go module definition
├── Makefile             # Build automation
├── Dockerfile           # Container image definition
├── Dockerfile.debug     # Debug container with Delve
├── .dockerignore        # Docker ignore patterns
├── .gitignore           # Git ignore patterns
├── k8s/                 # Kubernetes manifests
│   ├── pod.yaml.template
│   └── deployment.yaml.template
└── README.md            # This file
```

This follows the idiomatic Go project layout:
- `cmd/` - Contains the main applications for this project (each subdirectory is a command/entry point)
- `internal/` - Private application code that cannot be imported by other projects

## Building the Project

### Quick Start

Build the binary for your current platform:

```bash
make build
```

Run the application locally:

```bash
make run
```

The server will start on `http://localhost:8080` by default. You can change the port by setting the `PORT` environment variable:

```bash
PORT=9090 make run
```

### Cross-Compilation

Build binaries for all supported platforms (Linux, macOS, Windows, multiple architectures):

```bash
make build-all
```

This will create binaries in the `bin/` directory for:
- `linux/amd64`
- `linux/arm64`
- `darwin/amd64`
- `darwin/arm64`
- `windows/amd64`
- `windows/arm64`

### Testing

Run tests:

```bash
make test
```

Run tests with coverage:

```bash
make test-coverage
```

## Docker

### Building Docker Image

Build the Docker image:

```bash
make docker-build
```

This will create an image tagged as `example-golang-application:dev` (or your git tag if available) and `example-golang-application:latest`.

### Running Docker Container

Run the container locally:

```bash
make docker-run
```

The server will be accessible at `http://localhost:8080`.

### Custom Docker Image

You can also build with custom tags:

```bash
docker build -t my-registry/example-golang-application:v1.0.0 .
docker run -p 8080:8080 my-registry/example-golang-application:v1.0.0
```

## Debugging with Delve

The project includes support for in-container debugging using [Delve](https://github.com/go-delve/delve) and VS Code.

### Prerequisites

- VS Code with the [Go extension](https://marketplace.visualstudio.com/items?itemName=golang.Go) installed
- Docker installed and running

### Building Debug Image

Build the debug Docker image (includes Delve debugger):

```bash
make docker-build-debug
```

This creates a separate debug image with:
- Debug symbols included (no stripping)
- Delve debugger installed and configured
- Port 2345 exposed for debugger connections

### Running in Debug Mode

Start the container in debug mode:

```bash
make docker-run-debug
```

Or use the shorter alias:

```bash
make docker-debug
```

This will:
- Start the container with the debug image
- Expose port 8080 for the HTTP server
- Expose port 2345 for the Delve debugger
- Set necessary security options for debugging

The container will start with Delve running in headless mode, waiting for a debugger to attach.

### Attaching VS Code Debugger

1. **Start the debug container** (see above)

2. **Open VS Code** in this project directory

3. **Set breakpoints** in your code (click in the gutter next to line numbers)

4. **Start debugging**:
   - Press `F5` or go to Run → Start Debugging
   - Select **"Attach to Docker Container (Delve)"** from the configuration dropdown
   - VS Code will connect to the Delve debugger running in the container

5. **Debug your application**:
   - Set breakpoints by clicking in the gutter
   - Step through code with F10 (step over), F11 (step into), Shift+F11 (step out)
   - Inspect variables in the Variables panel
   - View the call stack in the Call Stack panel

### Debug Configuration

The project includes a VS Code launch configuration at `.vscode/launch.json`:

- **Attach to Docker Container (Delve)**: Connects to Delve running in the container
- **Launch Local (for comparison)**: Debugs the application locally (not in container)

The remote debug configuration:
- Connects to `localhost:2345` (Delve's default port)
- Maps remote paths from `/app` to your local workspace
- Includes verbose logging for troubleshooting

### Debugging Workflow

1. Make code changes
2. Rebuild the debug image: `make docker-build-debug`
3. Restart the debug container: `make docker-run-debug`
4. Re-attach the debugger in VS Code

### Troubleshooting Debugging

**Debugger won't connect:**
- Ensure the container is running: `docker ps`
- Check that port 2345 is exposed: `docker port <container-id>`
- Verify Delve is listening: Check container logs

**Breakpoints not hit:**
- Ensure you're using the debug build (with debug symbols)
- Check that the code path is actually executed
- Verify source paths match between container and local

**Permission errors:**
- The debug container runs with `--cap-add=SYS_PTRACE` which may require Docker to run without root restrictions on some systems
- On Linux, you may need to run Docker with appropriate permissions

### Debug vs Production Builds

- **Debug build** (`Dockerfile.debug`): Includes debug symbols, larger image, includes Delve
- **Production build** (`Dockerfile`): Stripped symbols, optimized, minimal image

Always use the production build for deployed environments.

## Kubernetes Deployment

### Generate Manifests

Generate Kubernetes manifests from templates:

```bash
make k8s-manifests
```

This creates:
- `k8s/pod.yaml` - Single Pod definition
- `k8s/deployment.yaml` - Deployment with Service definition

### Deploy to Kubernetes

#### Using Pod (Single Instance)

```bash
kubectl apply -f k8s/pod.yaml
```

Check the pod status:

```bash
kubectl get pods
kubectl logs -f example-golang-application
```

#### Using Deployment (Recommended)

```bash
kubectl apply -f k8s/deployment.yaml
```

Check deployment status:

```bash
kubectl get deployments
kubectl get pods
kubectl get services
```

Access the service:

```bash
# Port forward to local machine
kubectl port-forward service/example-golang-application 8080:80

# Or get service IP
kubectl get svc example-golang-application
```

### Customizing Deployment

Edit the templates in `k8s/` directory and regenerate:

```bash
# Modify k8s/deployment.yaml.template
make k8s-manifests
kubectl apply -f k8s/deployment.yaml
```

## Makefile Commands

Run `make help` to see all available commands:

```bash
make help
```

Common commands:

- `make build` - Build binary for current platform
- `make build-all` - Build for all supported platforms
- `make clean` - Remove build artifacts
- `make test` - Run tests
- `make run` - Run application locally
- `make docker-build` - Build Docker image
- `make docker-run` - Build and run Docker container
- `make docker-build-debug` - Build Docker debug image with Delve
- `make docker-run-debug` - Run Docker container in debug mode
- `make docker-debug` - Alias for docker-run-debug
- `make docker-push` - Push Docker image to registry (configure registry in Makefile)
- `make k8s-manifests` - Generate Kubernetes manifests
- `make all` - Build everything: binaries, Docker image, and K8s manifests

## Configuration

The application uses environment variables for configuration:

- `PORT` - Server port (default: `8080`)

## API Endpoints

- `GET /` - Root endpoint, returns welcome message
- `GET /health` - Health check endpoint for monitoring

Example:

```bash
# Root endpoint
curl http://localhost:8080/

# Health check
curl http://localhost:8080/health
```

## Development

### Local Development

1. Clone the repository
2. Run `go mod download` to fetch dependencies
3. Run `make run` to start the server
4. Make changes and the server will need to be restarted

### Adding Dependencies

```bash
go get <package>
go mod tidy
```

## Production Considerations

- The Docker image uses a multi-stage build for minimal size
- The container runs as a non-root user for security
- Health checks are configured in Kubernetes manifests
- Resource limits are set in the deployment
- Graceful shutdown is implemented for zero-downtime deployments

## Troubleshooting

### Build Issues

If cross-compilation fails, ensure you have the correct Go version:

```bash
go version  # Should be 1.21 or later
```

### Docker Issues

If Docker build fails, check:

```bash
docker info
docker version
```

### Kubernetes Issues

Check pod logs:

```bash
kubectl logs <pod-name>
```

Describe pod for events:

```bash
kubectl describe pod <pod-name>
```

## License

[Specify your license here]

## Contributing

[Add contribution guidelines if applicable]