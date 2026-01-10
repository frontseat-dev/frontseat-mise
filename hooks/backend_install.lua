--- Installs frontseat CLI or a specific plugin
--- Uses gh CLI for downloading (supports both public and private repos)
--- @param ctx table Context with tool, version, install_path
function PLUGIN:BackendInstall(ctx)
    local tool = ctx.tool
    local version = ctx.version
    local install_path = ctx.install_path

    -- Detect OS
    local os_handle = io.popen("uname -s")
    local os_name = os_handle:read("*l"):lower()
    os_handle:close()

    -- Detect architecture
    local arch_handle = io.popen("uname -m")
    local arch = arch_handle:read("*l")
    arch_handle:close()

    if arch == "x86_64" then
        arch = "amd64"
    elseif arch == "aarch64" or arch == "arm64" then
        arch = "arm64"
    end

    local tag = string.format("frontseat@%s", version)

    -- Create bin directory
    os.execute(string.format("mkdir -p '%s/bin' '%s/tmp'", install_path, install_path))

    if tool == "frontseat" then
        -- Install the CLI
        local cli_tarball = string.format("frontseat-%s-%s-%s.tar.gz", version, os_name, arch)

        print(string.format("Downloading frontseat %s...", version))
        local cli_cmd = string.format(
            "gh release download '%s' --repo jbadeau/frontseat --pattern '%s' --dir '%s/tmp' && " ..
            "tar -xzf '%s/tmp/%s' -C '%s/bin' && " ..
            "chmod +x '%s/bin/frontseat' && " ..
            "rm -f '%s/tmp/%s'",
            tag, cli_tarball, install_path,
            install_path, cli_tarball, install_path,
            install_path,
            install_path, cli_tarball
        )
        local cli_result = os.execute(cli_cmd)
        if cli_result ~= 0 then
            error("Failed to download frontseat CLI. Make sure gh is installed and authenticated.")
        end
    else
        -- Install a plugin (tool name is like "frontseat-plugin-go")
        local plugin_tarball = string.format("%s-%s-%s-%s.tar.gz", tool, version, os_name, arch)

        print(string.format("Downloading %s %s...", tool, version))
        local plugin_cmd = string.format(
            "gh release download '%s' --repo jbadeau/frontseat --pattern '%s' --dir '%s/tmp' && " ..
            "tar -xzf '%s/tmp/%s' -C '%s/bin' && " ..
            "chmod +x '%s/bin/%s' && " ..
            "rm -f '%s/tmp/%s'",
            tag, plugin_tarball, install_path,
            install_path, plugin_tarball, install_path,
            install_path, tool,
            install_path, plugin_tarball
        )
        local plugin_result = os.execute(plugin_cmd)
        if plugin_result ~= 0 then
            error(string.format("Failed to download %s. Make sure gh is installed and authenticated.", tool))
        end
    end

    -- Cleanup tmp directory
    os.execute(string.format("rm -rf '%s/tmp'", install_path))

    print(string.format("%s %s installed successfully!", tool, version))
    return { version = version }
end
