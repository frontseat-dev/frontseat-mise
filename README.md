# frontseat-mise

The [mise](https://mise.jdx.dev/) plugin for [Frontseat](https://github.com/frontseat-dev/frontseat) - The build orchestrator for the AI age.

## Prerequisites

- [mise](https://mise.jdx.dev/) installed
- GitHub access to `frontseat-dev/frontseat`. `gh` is installed by mise as a
  plugin dependency, but it needs a token mise's install subprocess can see.
  Either run `gh auth login` (stores a config file), or — more reliably in CI
  and other non-interactive shells — export `GH_TOKEN` / `GITHUB_TOKEN`. A bare
  login token that lives only in the parent shell's environment may not reach
  the plugin hook.

## Installation

Add the plugin to mise:

```bash
mise plugin install frontseat https://github.com/frontseat-dev/frontseat-mise.git
```

## Usage

### Install frontseat CLI

```toml
# mise.toml
[tools]
frontseat = "0.1.0"
```

Or via command line:

```bash
mise use frontseat@0.1.0
```

## List Available Versions

```bash
mise ls-remote frontseat
```

## License

Apache-2.0
