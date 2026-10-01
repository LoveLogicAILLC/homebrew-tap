class MuxCockpit < Formula
  desc "Terminal UI and RPC harness for the MUX host-driven agent swarm"
  homepage "https://github.com/LoveLogicAILLC/mux-cockpit"
  url "https://github.com/LoveLogicAILLC/mux-cockpit/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "2f780755d403c326fc5ff7a676421a057d534d18ac1f249d9f808522f3d610fe"
  license "MIT"
  revision 1
  head "https://github.com/LoveLogicAILLC/mux-cockpit.git", branch: "main"

  depends_on "go" => :build
  depends_on "python@3.14"

  def install
    system "go", "build", *std_go_args(
      output:  bin/"mux-cockpit",
      ldflags: "-s -w -X main.version=#{version}",
    ), "."

    libexec.install "harness", "host_orchestrator.py", "mux_router.py",
                    "morph_engine.py", "cockpit_integration.py"

    python = Formula["python@3.14"].opt_bin/"python3.14"
    (bin/"mux-host").write <<~SHELL
      #!/usr/bin/env bash
      exec "#{python}" "#{libexec}/host_orchestrator.py" "$@"
    SHELL

    (bin/"mux-stack").write <<~SHELL
      #!/usr/bin/env bash
      set -euo pipefail

      SOCK="${MUX_SOCK:-/tmp/mux_host.sock}"
      MEMORY="${MUX_MEMORY:-$HOME/.local/share/mux-cockpit}"
      WORKSPACE="${MUX_WORKSPACE:-$PWD}"
      PROVIDER="${MUX_PROVIDER:-openai}"
      MODEL="${MUX_MODEL:-gpt-5}"
      HOST_PID=""

      cleanup() {
        code=$?
        if [[ -n "$HOST_PID" ]]; then
          kill "$HOST_PID" 2>/dev/null || true
          wait "$HOST_PID" 2>/dev/null || true
        fi
        rm -f "$SOCK"
        exit "$code"
      }
      trap cleanup EXIT INT TERM

      if [[ "$PROVIDER" == "openai" && -z "${OPENAI_API_KEY:-}" && -z "${OPENAI_BASE_URL:-}" ]]; then
        echo "mux-stack: OPENAI_API_KEY or OPENAI_BASE_URL is required (or set MUX_PROVIDER=mock/ollama/gemini)" >&2
        exit 1
      fi
      if [[ "$PROVIDER" == "gemini" && -z "${GEMINI_API_KEY:-}" ]]; then
        echo "mux-stack: GEMINI_API_KEY is required (or select another MUX_PROVIDER)" >&2
        exit 1
      fi

      export MUX_PROVIDER="$PROVIDER" MUX_MODEL="$MODEL" MUX_WORKSPACE="$WORKSPACE"
      mkdir -p "$MEMORY"
      "#{bin}/mux-host" serve --memory "$MEMORY" --workspace "$WORKSPACE" --sock "$SOCK" \
        >>"$MEMORY/host.stdout.log" 2>&1 &
      HOST_PID=$!

      for _ in $(seq 1 40); do
        [[ -S "$SOCK" ]] && break
        kill -0 "$HOST_PID" 2>/dev/null || {
          echo "mux-stack: host failed to start" >&2
          tail -20 "$MEMORY/host.stdout.log" >&2 || true
          exit 1
        }
        sleep 0.25
      done
      [[ -S "$SOCK" ]] || { echo "mux-stack: host socket never appeared" >&2; exit 1; }

      "#{bin}/mux-cockpit" -sock "$SOCK"
    SHELL

    chmod 0755, bin/"mux-host", bin/"mux-stack"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/mux-cockpit -version 2>&1")
    assert_match "usage: host_orchestrator.py", shell_output("#{bin}/mux-host --help 2>&1")
  end
end
