#!/usr/bin/env bash
# Prepares the TinyTydi submodule after the container is created.
#
# Run from postCreateCommand in both container flavours. It is idempotent, and
# it deliberately never fails the container: a problem here should leave you at
# a working prompt with a clear message, not a container that refuses to start.
# Everything it does can be re-run by hand with `bash .devcontainer/bootstrap.sh`.
set -u

cd "$(dirname "$0")/.." || exit 0
PROBLEMS=()

note()  { printf '\n\033[1m==> %s\033[0m\n' "$1"; }
warn()  { printf '\033[33m    %s\033[0m\n' "$1"; PROBLEMS+=("$1"); }

# 1. The workspace is a bind mount from the host, so its files are owned by the
#    host user while the container runs as root. Git refuses to operate on a
#    repository it sees as someone else's ("detected dubious ownership"), which
#    would break the submodule step below and every git command you type later.
note "Trusting the bind-mounted workspace"
git config --global --add safe.directory '*' 2>/dev/null \
  || warn "could not set safe.directory; git commands may report dubious ownership"

# 2. The submodule may be absent if the repository was cloned without
#    --recurse-submodules. Pinned, not --remote: the recorded commit is the one
#    this branch was tested against, and moving it is a deliberate act.
note "Checking out the TinyTydi submodule"
if [ -f .gitmodules ]; then
  git submodule update --init tinytydi || warn "git submodule update failed"
fi

if [ ! -f tinytydi/main.py ]; then
  warn "tinytydi/ is empty. Run: git submodule update --init tinytydi"
  printf '\n%s\n' "Bootstrap finished with problems; see above."
  exit 0
fi

# 3. hdl/bundles/ is gitignored in TinyTydi, so a fresh checkout has none, and
#    hdl/Interface.test.scala asserts that at least one exists. Without this
#    step `scala-cli test .` fails with "no bundles found", which reads like a
#    broken toolchain rather than missing inputs.
note "Building the stimulus bundles the Chisel tests read"
(
  cd tinytydi || exit 1

  # The tutorial's own chat data. It normalises to three physical streams whose
  # middle leaf packs timestamp, message_id and user_id into one 64-bit payload,
  # which is the interesting case for typed waveforms.
  ./main.py export --json ../tydi-material/chat-messages/chat-messages.json \
                   --lanes 1,2,4 --out hdl/bundles/chatmsgs

  # One small type as well, so there is a bundle that simulates in a dozen
  # cycles when you only want to check the toolchain.
  ./main.py export --type "Dim(Dim(Bits(8)))" --lanes 4 --out hdl/bundles/demo
) || warn "bundle export failed; run ./main.py export by hand in tinytydi/"

note "Ready"
cat <<'EOF'
  python3 tinytydi/main.py json tydi-material/chat-messages/chat-messages.json --type-only
      the tutorial's chat data as a Tydi type

  cd tinytydi/hdl && scala-cli test .
      elaborate the interface per bundle and check it against the semantics

  cd tinytydi/hdl && ./invoke-surfer chatmsgs
      open the waveform (says whether Tywaves type info was found)
EOF

if [ ${#PROBLEMS[@]} -gt 0 ]; then
  printf '\n\033[33mBootstrap finished with %d problem(s); see above.\033[0m\n' "${#PROBLEMS[@]}"
fi
exit 0
