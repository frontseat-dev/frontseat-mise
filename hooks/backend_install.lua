--- Installs the frontseat CLI and any declared plugins.
--- Plugins are declared via the "plugins" option as a comma-separated string:
---   "frontseat:frontseat" = { version = "latest", plugins = "maven,docker,go" }
--- @param ctx table Context with tool, version, install_path, options
function PLUGIN:BackendInstall(ctx)
    local cmd = require("cmd")
    local version = ctx.version
    local install_path = ctx.install_path
    local options = ctx.options or {}

    local os_name = RUNTIME.osType
    local arch = RUNTIME.archType
    local tag = "v" .. version

    local bin_dir = install_path .. "/bin"
    local tmp_dir = install_path .. "/tmp"

    cmd.exec("mkdir -p '" .. bin_dir .. "' '" .. tmp_dir .. "'")

    -- Install the CLI
    local cli_tarball = "frontseat-" .. version .. "-" .. os_name .. "-" .. arch .. ".tar.gz"
    print("Downloading frontseat " .. version .. "...")
    cmd.exec("gh release download '" .. tag .. "' --repo jbadeau/frontseat --pattern '" .. cli_tarball .. "' --dir '" .. tmp_dir .. "'")
    cmd.exec("tar -xzf '" .. tmp_dir .. "/" .. cli_tarball .. "' -C '" .. bin_dir .. "'")
    cmd.exec("chmod +x '" .. bin_dir .. "/frontseat'")
    cmd.exec("rm -f '" .. tmp_dir .. "/" .. cli_tarball .. "'")
    print("frontseat " .. version .. " installed successfully!")

    -- Install declared plugins
    local plugins_str = options["plugins"] or options.plugins
    if plugins_str and plugins_str ~= "" then
        for plugin_name in plugins_str:gmatch("[^,]+") do
            plugin_name = plugin_name:match("^%s*(.-)%s*$") -- trim whitespace
            local tool = "frontseat-plugin-" .. plugin_name
            local tarball = tool .. "-" .. version .. "-" .. os_name .. "-" .. arch .. ".tar.gz"

            print("Downloading " .. tool .. " " .. version .. "...")
            cmd.exec("gh release download '" .. tag .. "' --repo jbadeau/frontseat --pattern '" .. tarball .. "' --dir '" .. tmp_dir .. "'")
            cmd.exec("tar -xzf '" .. tmp_dir .. "/" .. tarball .. "' -C '" .. bin_dir .. "'")
            cmd.exec("chmod +x '" .. bin_dir .. "/" .. tool .. "'")
            cmd.exec("rm -f '" .. tmp_dir .. "/" .. tarball .. "'")
            print(tool .. " " .. version .. " installed successfully!")
        end
    end

    cmd.exec("rm -rf '" .. tmp_dir .. "'")
    return {}
end
