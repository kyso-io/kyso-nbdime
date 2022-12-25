#!/bin/sh

set -e

# VARIABLES
IMG_NAME="registry.kyso.io/docker/kyso-nbdime/main"
CNAME="kyso-nbdime"

# RUNTIME VARIABLES
SCRIPT="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT")"
WORK_DIR="$(readlink -f "$SCRIPT_DIR/..")"

FLASK_PORT="3005"

# FUNCTIONS
_build() {
  cd "$WORK_DIR"
  docker build --build-arg "$(cat .build-args)" -t "$IMG_NAME" .
}

_pull() {
  # pull latest image
  docker pull "$IMG_NAME"
  # remove dangling images
  for _img in $(docker images --filter "dangling=true" -q "$IMG_NAME"); do
    docker rmi "${_img}" || true
  done
}

_run() {
  docker run --rm -ti \
    --publish "$FLASK_PORT:$FLASK_PORT" \
    --name "$CNAME" \
    "$IMG_NAME" "$@"
}

_run_daemon() {
  docker run --detach \
    --publish "$FLASK_PORT:$FLASK_PORT" \
    --restart always \
    --name "$CNAME" \
    "$IMG_NAME" "$@"
}

_logs() {
  docker logs "${CNAME}" "$@"
}

_ps_status() {
  docker ps -a -f name="${CNAME}" --format '{{.Status}}' 2>/dev/null || true
}

_inspect_status() {
  docker inspect ${CNAME} -f "{{.State.Status}}" 2>/dev/null || true
}

_status() {
  _st="$(_ps_status)"
  if [ -z "$_st" ]; then
    echo "The container '${CNAME}' does not exist"
    exit 1
  else
    echo "$_st"
  fi
}

_start() {
  _st="$(_inspect_status)"
  if [ -z "$_st" ]; then
    _run_daemon "$@"
  elif [ "$_st" != "running" ] && [ "$_st" != "restarting" ]; then
    docker start "${CNAME}"
  fi
}

_stop() {
  _st="$(_inspect_status)"
  if [ "$_st" = "running" ] || [ "$_st" = "restarting" ]; then
    docker stop "${CNAME}"
  fi
}

_restart() {
  _stop
  _start "$@"
}

_rm() {
  _st="$(_inspect_status)"
  if [ -n "$_st" ]; then
    _stop
    docker rm "${CNAME}"
  fi
}

_exec() {
  docker exec -ti "${CNAME}" "$@"
}

_usage() {
  cat <<EOF
Usage: $0 {start|stop|status|restart|rm|run|logs|exec|build|pull|init}
EOF
  exit 0
}

# ====
# MAIN
# ====
case "$1" in
start)
  shift
  _start "$@"
  ;;
stop) _stop ;;
status) _status ;;
restart)
  shift
  _restart "$@"
  ;;
run)
  shift
  # run the container removing the default ARGS if no argument is passed
  if [ "$*" ]; then
    _run "$@"
  else
    _run ""
  fi
  ;;
rm) _rm ;;
logs)
  shift
  _logs "$@"
  ;;
exec)
  shift
  _exec "$@"
  ;;
build) _build ;;
pull) _pull ;;
init)
  shift
  _init "$@"
  ;;
*) _usage ;;
esac

# vim: ts=2:sw=2:et
