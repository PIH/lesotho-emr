#!/bin/bash
set -euo pipefail

SITE=${1:-}
COMMAND=${2:-}
shift 2 2>/dev/null || true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker/compose.yaml"
SEED_COMPOSE_FILE="$SCRIPT_DIR/docker/compose.seed.yaml"
DEV_COMPOSE_FILE="$SCRIPT_DIR/docker/compose.dev.yaml"
ENV_FILE="$SCRIPT_DIR/docker/default.env"

usage() {
    echo "Usage: $0 <site> <command> [options]"
    echo ""
    echo "Sites:    botsabelo-demo"
    echo "Commands: start | stop | update | wait | build | logs | destroy"
    echo ""
    echo "  start    Start the stack"
    echo "  stop     Stop the running stack"
    echo "  update   Stop then restart the stack"
    echo "  wait     Block until OpenMRS finishes initializing (up to 60 minutes)"
    echo "  build    Build the distribution and Docker image from source"
    echo "  logs     Tail the container logs"
    echo "  destroy  Stop the stack and delete all volumes"
    echo ""
    echo "Options:"
    echo "  --build   Build the distribution from source before start/update"
    echo "  --fresh   Start from scratch instead of using a pre-seeded image"
    echo "  --dev     Expose debug ports and mount the locally-built distro over"
    echo "            whatever's in the image (combine with --build to build it first)"
    echo ""
    echo "Environment variable overrides:"
    echo "  TOMCAT_HTTP_PORT   Port OpenMRS is exposed on (default: 8080)"
    exit 1
}

BUILD=false
FRESH=false
DEV=false
for arg in "$@"; do
    case "$arg" in
        --build) BUILD=true ;;
        --fresh) FRESH=true ;;
        --dev) DEV=true ;;
        *) echo "Unknown option: '$arg'"; echo ""; usage ;;
    esac
done

case "$SITE" in
    botsabelo-demo)       PIH_CONFIG="lesotho,lesotho-botsabelo-demo" ;;
    *) echo "Unknown site: '$SITE'"; echo ""; usage ;;
esac

[ -z "$COMMAND" ] && usage

export PIH_CONFIG
export SERVICE_NAME="$SITE"
export SITE

BASE_COMPOSE="docker compose -f $COMPOSE_FILE --env-file $ENV_FILE"
SEED_COMPOSE="docker compose -f $SEED_COMPOSE_FILE --env-file $ENV_FILE"
if $DEV; then
    BASE_COMPOSE="$BASE_COMPOSE -f $DEV_COMPOSE_FILE"
    SEED_COMPOSE="$SEED_COMPOSE -f $DEV_COMPOSE_FILE"
fi

build_image() {
    cd "$SCRIPT_DIR" && mvn clean package -U
    if ! $FRESH && ! $DEV; then
        # compose.seed.yaml has no build context; build the image explicitly.
        # Skipped with --dev, since that mounts the build output directly
        # instead of requiring a rebuilt image.
        $BASE_COMPOSE build
    fi
}

start_stack() {
    if $FRESH; then
        $BASE_COMPOSE up -d
    else
        $SEED_COMPOSE up -d
    fi
}

case "$COMMAND" in
    start)
        if $BUILD; then build_image; fi
        start_stack
        ;;
    update)
        if $BUILD; then build_image; fi
        if $FRESH; then $BASE_COMPOSE down; else $SEED_COMPOSE down; fi
        start_stack
        ;;
    wait)
        OPENMRS_CONTAINER=$(docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" ps -q openmrs)
        echo "Waiting for OpenMRS to initialize (up to 60 minutes)..."
        docker logs -f "$OPENMRS_CONTAINER" 2>&1 &
        LOGS_PID=$!
        for i in $(seq 1 120); do
            if docker logs "$OPENMRS_CONTAINER" 2>&1 | grep -q "Distribution startup complete"; then
                kill $LOGS_PID 2>/dev/null || true
                break
            fi
            sleep 30
            if [ "$i" -eq 120 ]; then
                kill $LOGS_PID 2>/dev/null || true
                echo "Timed out waiting for OpenMRS to initialize after 60 minutes"
                exit 1
            fi
        done
        echo "Waiting for OpenMRS to be accessible..."
        for i in $(seq 1 20); do
            if curl -sf "http://localhost:${TOMCAT_HTTP_PORT:-8080}/openmrs" > /dev/null 2>&1; then
                echo "OpenMRS is ready."
                exit 0
            fi
            sleep 15
        done
        echo "Timed out waiting for OpenMRS to become accessible"
        exit 1
        ;;
    build)
        cd "$SCRIPT_DIR" && mvn clean package -U
        $BASE_COMPOSE build
        ;;
    stop)    $BASE_COMPOSE down --remove-orphans ;;
    logs)    $BASE_COMPOSE logs -f ;;
    destroy) $BASE_COMPOSE down -v --remove-orphans ;;
    *) echo "Unknown command: '$COMMAND'"; echo ""; usage ;;
esac
