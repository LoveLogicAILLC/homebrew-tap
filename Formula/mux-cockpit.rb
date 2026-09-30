class MuxCockpit < Formula
  desc "Terminal UI and RPC harness for the MUX host-driven agent swarm"
  homepage "https://github.com/LoveLogicAILLC/mux-cockpit"
  url "https://github.com/LoveLogicAILLC/mux-cockpit/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "2f780755d403c326fc5ff7a676421a057d534d18ac1f249d9f808522f3d610fe"
  license "MIT"
  head "https://github.com/LoveLogicAILLC/mux-cockpit.git", branch: "main"

  depends_on "go" => :build

  def install
    # 1. Compile native Go TUI binary
    system "go", "build", *std_go_args(
      output:  bin/"mux-cockpit",
      ldflags: "-s -w -X main.version=#{version}",
    ), "."

    # 2. Install Python orchestrator, router, and harness modules to libexec
    libexec.install "harness", "host_orchestrator.py", "mux_router.py",
                    "morph_engine.py", "cockpit_integration.py", "run.sh"

    # 3. Wrapper script for the Python host orchestrator
    (bin/"mux-host").write <<~SHELL
      #!/usr/bin/env bash
      exec python3 "#{libexec}/host_orchestrator.py" "$@"
    SHELL
    chmod 0755, bin/"mux-host"

    # 4. Wrapper script for the full stack (host + TUI)
    (bin/"mux-stack").write <<~SHELL
      #!/usr/bin/env bash
      cd "#{libexec}" && exec bash "#{libexec}/run.sh" "$@"
    SHELL
    chmod 0755, bin/"mux-stack"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/mux-cockpit -version 2>&1")
    assert_match "Usage of", shell_output("#{bin}/mux-cockpit -help 2>&1")
  end
end
