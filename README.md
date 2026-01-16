# frontseat-mise

The offical [Frontseat](https://github.com/jbadeau/frontseat) [mise](https://mise.jdx.dev/) plugin.

## Prerequisites

- [mise](https://mise.jdx.dev/) installed
- [gh](https://cli.github.com/) CLI installed and authenticated (`gh auth login`)

## Installation

Add the plugin to mise:

```bash
mise plugin add frontseat https://github.com/jbadeau/frontseat-mise
```

## Usage

### Install frontseat CLI

```toml
# mise.toml
[tools]
"frontseat:frontseat" = "0.1.0"
```

Or via command line:

```bash
mise use frontseat:frontseat@0.1.0
```

### Install plugins

Each plugin is installed as a separate tool:

```toml
# mise.toml
[tools]
"frontseat:frontseat" = "0.1.0"
"frontseat:frontseat-plugin-go" = "0.1.0"
"frontseat:frontseat-plugin-npm" = "0.1.0"
"frontseat:frontseat-plugin-docker" = "0.1.0"
```

Or via command line:

```bash
mise use frontseat:frontseat-plugin-go@0.1.0
mise use frontseat:frontseat-plugin-npm@0.1.0
```

## List Available Versions

```bash
mise ls-remote frontseat:frontseat
```

## License

Apache-2.0
