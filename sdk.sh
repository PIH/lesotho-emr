#!/bin/bash
set -euo pipefail

SITE=${1:-}
COMMAND=${2:-}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# JVM memory settings
export MAVEN_OPTS="-Xms512m -Xmx2g"

# Server settings
SERVER_PORT="${SERVER_PORT:-8080}"
DEBUG_PORT="${DEBUG_PORT:-1044}"

# DB connection settings — used when DB_CONTAINER is set
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-3308}"
DB_USER="${DB_USER:-root}"
DB_PASSWORD="${DB_PASSWORD:-root}"

usage() {
    echo "Usage: $0 <site> <command>"
    echo ""
    echo "Sites:    botsabelo-demo"
    echo "Commands: create | update | update-config | run | destroy"
    echo ""
    echo "  create         Set up a new SDK server for the given site"
    echo "  update         Redeploy updated artifacts to an existing server"
    echo "  update-config  Redeploy configuration only to an existing server"
    echo "  run            Start the server (use Ctrl+C to stop)"
    echo "  destroy        Delete the server directory and drop its database"
    echo ""
    echo "Environment variable overrides:"
    echo "  SERVER_ID     Server ID (default: site name)"
    echo "  SERVER_PORT   Tomcat port (default: 8080)"
    echo "  DEBUG_PORT    Remote debug port (default: 1044)"
    echo "  JMX_PORT      Enable JMX monitoring on this port (default: disabled)"
    echo "  JAVA_HOME     Java installation to use (default: system Java)"
    echo ""
    echo "Database:"
    echo "  (default)     SDK creates and manages its own Docker MySQL container"
    echo "  DB_CONTAINER  Connect to an existing Docker container (e.g. DB_CONTAINER=mysql56)"
    echo "  DB_HOST       Database host (default: localhost)"
    echo "  DB_PORT       Database port (default: 3308)"
    echo "  DB_NAME       Database name (default: server ID)"
    echo "  DB_USER       Database user (default: root)"
    echo "  DB_PASSWORD   Database password (default: root)"
    echo ""
    echo "Flags (create only):"
    echo "  --reset-db    Reset the existing database if one already exists (default: keep)"
    exit 1
}

RESET_DB=false
for arg in "${@:3}"; do
    case "$arg" in
        --reset-db) RESET_DB=true ;;
        *) echo "Unknown argument: '$arg'"; echo ""; usage ;;
    esac
done

case "$SITE" in
    botsabelo-demo)       PIH_CONFIG="lesotho,lesotho-botsabelo-demo" ;;
    *) echo "Unknown site: '$SITE'"; echo ""; usage ;;
esac

[ -z "$COMMAND" ] && usage

SERVER_ID="${SERVER_ID:-${SITE}}"
SERVER_DIR="$HOME/openmrs/${SERVER_ID}"  # used by destroy
DB_NAME="${DB_NAME:-${SERVER_ID}}"
DB_URI="jdbc:mysql://${DB_HOST}:${DB_PORT}/${DB_NAME}?autoReconnect=true&useUnicode=true&characterEncoding=UTF-8&sessionVariables=default_storage_engine%3DInnoDB"

SETUP_PARAMS=(
    "-DserverId=${SERVER_ID}"
    "-Dpih.config=${PIH_CONFIG}"
    "-DserverPort=${SERVER_PORT}"
    "-Ddebug=${DEBUG_PORT}"
)

if [ -n "${DB_CONTAINER:-}" ]; then
    # Connect to an existing Docker container — wizard selects it, then we provide container/user/pass via batchAnswers
    # -DdbUri is passed so the URI prompt is skipped (promptForValueIfMissingWithDefault returns early)
    SETUP_PARAMS+=("-DdbUri=${DB_URI}")
    BATCH_ANSWERS="Existing docker container (requires pre-installed Docker),${DB_CONTAINER},${DB_USER},${DB_PASSWORD}"
    MYSQL_CONTAINER="${DB_CONTAINER}"
    MYSQL_USER="${DB_USER}"
    MYSQL_PASS="${DB_PASSWORD}"
else
    # SDK creates and manages its own Docker MySQL container
    # Must go through the wizard (batchAnswers) so promptForDockerizedSdkMysql runs and sets the URI/credentials
    BATCH_ANSWERS="MySQL 8.4.1 and above in SDK docker container (requires pre-installed Docker)"
    MYSQL_CONTAINER=$(docker ps --format "{{.Names}}" | grep "^openmrs-sdk-mysql" | head -1 || true)
    MYSQL_USER="root"
    MYSQL_PASS="Admin123"
fi

if [ -n "${JAVA_HOME:-}" ]; then
    SETUP_PARAMS+=("-DjavaHome=${JAVA_HOME}")
fi

cd "$SCRIPT_DIR"

case "$COMMAND" in
    create)
        mvn clean install -U
        # Check if the database already exists; if so, append the SDK's reset prompt answer to batchAnswers
        if [ -n "${MYSQL_CONTAINER:-}" ]; then
            _db_exists=$(docker exec "${MYSQL_CONTAINER}" mysql -u"${MYSQL_USER}" -p"${MYSQL_PASS}" \
                -e "SHOW DATABASES LIKE '${DB_NAME}';" 2>/dev/null | grep -c "${DB_NAME}" || echo 0)
            if [ "${_db_exists}" -gt 0 ]; then
                # Prompt asks "use existing data?"; "n" = reset, "y" = keep
                BATCH_ANSWERS="${BATCH_ANSWERS},$( [ "$RESET_DB" = true ] && echo n || echo y )"
            fi
        fi
        mvn openmrs-sdk:setup -Ddistro="${SCRIPT_DIR}/distro/target/classes/openmrs-distro.properties" "${SETUP_PARAMS[@]}" "-DbatchAnswers=${BATCH_ANSWERS}"
        ;;
    update)
        mvn clean install -U
        mvn openmrs-sdk:deploy -Ddistro="${SCRIPT_DIR}/distro/target/classes/openmrs-distro.properties" -DserverId="${SERVER_ID}"
        ;;
    update-config)
        mvn clean install -U -pl content
        mvn openmrs-sdk:deploy -Ddistro="${SCRIPT_DIR}/distro/target/classes/openmrs-distro.properties" -DserverId="${SERVER_ID}" -DconfigOnly=true
        ;;
    run)
        # Set JMX_PORT to enable JMX remote monitoring (e.g. JMX_PORT=9000 ./sdk.sh botsabelo-demo run)
        if [ -n "${JMX_PORT:-}" ]; then
            MAVEN_OPTS="${MAVEN_OPTS} -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=${JMX_PORT} -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false"
        fi
        mvn openmrs-sdk:run -DserverId="${SERVER_ID}"
        ;;
    destroy)
        echo "This will permanently delete ${SERVER_DIR} and drop the '${DB_NAME}' database."
        read -r -p "Are you sure? [y/N] " confirm
        [[ "$confirm" =~ ^[Yy]$ ]] || exit 0
        if [ -n "${MYSQL_CONTAINER:-}" ]; then
            docker exec "${MYSQL_CONTAINER}" mysql -u"${MYSQL_USER}" -p"${MYSQL_PASS}" \
                -e "DROP DATABASE IF EXISTS \`${DB_NAME}\`;" 2>/dev/null \
                && echo "Dropped database '${DB_NAME}'." \
                || echo "Warning: could not drop database '${DB_NAME}' — may need manual cleanup."
        fi
        rm -rf "${SERVER_DIR}"
        echo "Deleted ${SERVER_DIR}"
        ;;
    *) echo "Unknown command: '$COMMAND'"; echo ""; usage ;;
esac
