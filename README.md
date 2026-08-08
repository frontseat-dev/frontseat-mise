# frontseat-mise

The [mise](https://mise.jdx.dev/) plugin for [Frontseat](https://github.com/frontseat-dev/frontseat).

## Prerequisites

- [mise](https://mise.jdx.dev/) installed
- [GitHub CLI](https://cli.github.com/) (`gh`) — `mise use -g gh`
- `gh` authenticated (`gh auth login`) or `GH_TOKEN` / `GITHUB_TOKEN` set
- Read access to the `frontseat-dev/frontseat` repository
- `tar` available on PATH

## Installation

```bash
mise plugin install frontseat https://github.com/frontseat-dev/frontseat-mise.git
```

## Usage

This backend installs the Frontseat CLI as `frontseat:cli` and each Frontseat
plugin as `frontseat:<name>` (e.g. `frontseat:go`).

```toml
# mise.toml
[tools]
gh = "latest"
"frontseat:cli" = "0.1.0"
"frontseat:go" = "0.1.0"   # optional plugin
```

Or via command line:

```bash
mise use frontseat:cli@0.1.0
mise use frontseat:go@0.1.0
```

## List available versions

```bash
mise ls-remote frontseat:cli
```

## License

Apache-2.0
