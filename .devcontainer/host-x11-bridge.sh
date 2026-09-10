#!/usr/bin/env bash
# Bridges the host's X server to a loopback TCP port, for the "CLI, X11 over
# TCP" container flavour. Runs on the HOST, from that flavour's
# initializeCommand, on every container create and start.
#
# Why this is needed at all: Docker Desktop on Linux runs containers inside a
# VM. Its file sharing only covers /home, so /tmp/.X11-unix and
# $XDG_RUNTIME_DIR cannot be bind-mounted, and sharing them would not help
# anyway: a Unix domain socket is a kernel object, so connect() needs the
# listener in the same kernel. Socket forwarding, which is what the Dev
# Containers extension normally does for GUI apps, is therefore impossible
# there. TCP is the only route left.
#
# On the native Docker Engine none of this applies and you do not need this
# script; see the README.
#
# Like bootstrap.sh, this deliberately never fails: a problem here should leave
# you with a working container and a clear message, not a container that
# refuses to start.
set -u

PORT=6000          # X display :0 over TCP is port 6000
AUTH="$HOME/.tydi-xauth"

warn() { printf '\033[33m[x11-bridge] %s\033[0m\n' "$1"; }
note() { printf '[x11-bridge] %s\n' "$1"; }

# Only meaningful on a Linux host with a running X server. On macOS and Windows
# the Dev Containers extension handles GUI forwarding itself, so do nothing.
[ "$(uname -s)" = "Linux" ] || exit 0
if [ -z "${DISPLAY:-}" ]; then
  warn "DISPLAY is not set; skipping. GUI apps will not open."
  exit 0
fi

# DISPLAY may be ":0", ":1", "host:0.0", ... Take the display number and map it
# to its Unix socket. Under Wayland this socket is Xwayland's, which is fine:
# X11 clients cannot tell the difference.
DISPNUM="${DISPLAY##*:}"
DISPNUM="${DISPNUM%%.*}"
SOCK="/tmp/.X11-unix/X${DISPNUM}"
if [ ! -S "$SOCK" ]; then
  warn "no X socket at $SOCK; skipping. GUI apps will not open."
  exit 0
fi

# 1. The cookie. GNOME's Xwayland has access control enabled and keeps its
#    cookie in a per-session file, so a container connecting over TCP is
#    refused ("Authorization required, but no authorization protocol
#    specified") unless it presents one.
#
#    Rewriting the address family to ffff (FamilyWild) makes the entry match
#    regardless of the hostname the client connects from, which is what we
#    need: the container sees itself under a random container hostname.
#
#    The file must live under $HOME, because that is the only path Docker
#    Desktop shares into its VM. It is regenerated on every start, since the
#    cookie changes with each login session.
if ! command -v xauth >/dev/null 2>&1; then
  warn "xauth not found; install x11-xserver-utils. GUI apps will not open."
  exit 0
fi
rm -f "$AUTH"
if ! (umask 077 && touch "$AUTH"); then
  warn "could not create $AUTH; skipping."
  exit 0
fi
if ! xauth nlist "$DISPLAY" | sed -e 's/^..../ffff/' | xauth -f "$AUTH" nmerge - 2>/dev/null; then
  warn "could not copy the X cookie into $AUTH. GUI apps will not open."
  exit 0
fi

# 2. The bridge. Bound to loopback on purpose: Docker Desktop's userspace
#    network stack forwards host.docker.internal to the host's loopback, so
#    this is reachable from the container while staying off your LAN. Never
#    bind this to 0.0.0.0; that exposes your X server, and an X server is a
#    keylogger to anyone who can reach it.
if ! command -v socat >/dev/null 2>&1; then
  warn "socat not found; install it (sudo apt install socat). GUI apps will not open."
  exit 0
fi

# Idempotent: on a restart the previous bridge is usually still running.
if (exec 3<>/dev/tcp/127.0.0.1/"$PORT") 2>/dev/null; then
  note "bridge already listening on 127.0.0.1:$PORT"
  exit 0
fi

# setsid detaches it from VS Code's process tree, so it survives this script
# returning and does not keep container start waiting on it.
setsid socat "TCP-LISTEN:$PORT,bind=127.0.0.1,reuseaddr,fork" "UNIX-CONNECT:$SOCK" \
  >/tmp/tydi-x11-bridge.log 2>&1 < /dev/null &
disown 2>/dev/null || true

note "bridging 127.0.0.1:$PORT -> $SOCK (log: /tmp/tydi-x11-bridge.log)"
note "stop it later with: pkill -f 'TCP-LISTEN:$PORT'"
exit 0
