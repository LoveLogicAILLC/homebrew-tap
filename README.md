# LoveLogicAI Homebrew Tap

Official Homebrew tap for [LoveLogicAI](https://github.com/LoveLogicAILLC) developer tools and autonomous agent infrastructure.

## Usage

Install any formula directly:

```bash
brew install LoveLogicAILLC/tap/<formula>
```

Or add the tap first:

```bash
brew tap LoveLogicAILLC/tap
brew install <formula>
```

## Available Formulae

| Formula | Description | Installation |
|---|---|---|
| [`mux-cockpit`](Formula/mux-cockpit.rb) | Terminal UI and RPC harness for the MUX host-driven agent swarm | `brew install LoveLogicAILLC/tap/mux-cockpit` |

### `mux-cockpit`

Installs three binaries into your Homebrew `$PATH`:
- `mux-cockpit` — The Charm/Bubble Tea terminal dashboard
- `mux-host` — The Python host orchestrator and priority router
- `mux-stack` — All-in-one stack launcher

```bash
# Start the host
mux-host serve &

# Open the TUI dashboard
mux-cockpit
```

## Documentation

Full documentation, architecture, and guides are available at [LoveLogicAILLC/mux-cockpit](https://github.com/LoveLogicAILLC/mux-cockpit).

## License

[MIT](https://github.com/LoveLogicAILLC/mux-cockpit/blob/main/LICENSE) © 2026 LoveLogic AI
