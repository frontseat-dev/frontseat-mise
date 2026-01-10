# mise-frontseat

A [mise](https://mise.jdx.dev/) backend plugin for [Frontseat](https://github.com/jbadeau/frontseat) - the polyglot build system for the rest of us.

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

## Available Tools

### CLI
- `frontseat` - The frontseat CLI

### Plugins
- `frontseat-plugin-asyncapi` - AsyncAPI code generation
- `frontseat-plugin-crane` - Container image management
- `frontseat-plugin-deno` - Deno runtime support
- `frontseat-plugin-docker` - Docker build support
- `frontseat-plugin-dotnet` - .NET build support
- `frontseat-plugin-github` - GitHub releases
- `frontseat-plugin-go` - Go build support
- `frontseat-plugin-helm` - Helm chart packaging
- `frontseat-plugin-jib` - Java container builds
- `frontseat-plugin-maven` - Maven build support
- `frontseat-plugin-npm` - npm/Node.js support
- `frontseat-plugin-openapi` - OpenAPI code generation
- `frontseat-plugin-protobuf` - Protocol buffer compilation
- `frontseat-plugin-rust` - Rust/Cargo support
- `frontseat-plugin-vite` - Vite frontend builds

## List Available Versions

```bash
mise ls-remote frontseat:frontseat
```

## License

Apache-2.0
