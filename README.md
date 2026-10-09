# frontseat-mise

The [mise](https://mise.jdx.dev/) plugin for [Frontseat](https://github.com/frontseat-dev/frontseat).

## Prerequisites

- [mise](https://mise.jdx.dev/) installed
- `tar` and `sha256sum` (or `shasum`) on PATH

Nothing else: the releases are public in
[frontseat-dev/frontseat-releases](https://github.com/frontseat-dev/frontseat-releases),
so installing needs no GitHub CLI and no credential, and every download is
checked against the release's `checksums.txt`. Listing versions calls
GitHub's API, which limits anonymous calls by address; set `GITHUB_TOKEN`
(any token) where that limit is shared, as on CI runners.

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
"frontseat:cli" = "0.49.1"
"frontseat:go" = "0.49.1"   # optional plugin
```

Or via command line:

```bash
mise use frontseat:cli@0.49.1
mise use frontseat:go@0.49.1
```

## List available versions

```bash
mise ls-remote frontseat:cli
```

## License

Apache-2.0
