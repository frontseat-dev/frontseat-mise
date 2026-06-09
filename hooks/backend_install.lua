--- Installs the frontseat CLI and any declared plugins.
--- Plugins are declared via the "plugins" option as a comma-separated string:
---   "frontseat:frontseat" = { version = "latest", plugins = "maven,docker,go" }
---
--- Cross-platform notes:
---   * On Windows, vfox routes cmd.exec through cmd.exe. Single quotes are
---     literal characters there (not string delimiters) and Unix builtins
---     like `mkdir -p`, `chmod`, `rm -f` and `rm -rf` don't exist. We branch
---     on RUNTIME.osType to emit cmd.exe-compatible commands.
---   * tar is available on Windows 10+ (bsdtar in System32), so we keep the
---     same `.tar.gz` asset naming upstream uses for darwin/linux.
---   * Upstream's `go build -o bin/<plat>/<name>` does not append `.exe` for
---     GOOS=windows, so the extracted binary lacks the extension Windows
---     needs to execute it. We rename to `<name>.exe` after extraction.
---
--- @param ctx table Context with tool, version, install_path, options
function PLUGIN:BackendInstall(ctx)
    local cmd = require("cmd")
    local version = ctx.version
    local install_path = ctx.install_path
    local options = ctx.options or {}

    local os_name = RUNTIME.osType
    local arch = RUNTIME.archType
    local tag = "v" .. version
    local is_windows = (os_name == "windows")
    local exe = is_windows and ".exe" or ""

    local bin_dir = install_path .. "/bin"
    local tmp_dir = install_path .. "/tmp"

    local function q(s)
        -- cmd.exe groups with double quotes; sh groups with single quotes.
        -- Paths from mise don't contain quotes, so this is safe.
        if is_windows then return '"' .. s .. '"' else return "'" .. s .. "'" end
    end

    local function mkdir(path)
        if is_windows then
            -- cmd.exe `mkdir` creates intermediate directories by default
            -- (command extensions, on by default) but errors if the path
            -- already exists. Guard with `if not exist`.
            cmd.exec('if not exist ' .. q(path) .. ' mkdir ' .. q(path))
        else
            cmd.exec("mkdir -p " .. q(path))
        end
    end

    local function rm_file(path)
        if is_windows then
            cmd.exec('if exist ' .. q(path) .. ' del /F /Q ' .. q(path))
        else
            cmd.exec("rm -f " .. q(path))
        end
    end

    local function rm_dir(path)
        if is_windows then
            cmd.exec('if exist ' .. q(path) .. ' rmdir /S /Q ' .. q(path))
        else
            cmd.exec("rm -rf " .. q(path))
        end
    end

    local function extract(tarball, dest)
        cmd.exec("tar -xzf " .. q(tarball) .. " -C " .. q(dest))
    end

    local function make_executable(path)
        if not is_windows then
            cmd.exec("chmod +x " .. q(path))
        end
    end

    --- Ensure the extracted binary has the `.exe` suffix on Windows.
    --- Upstream's Go build pipeline doesn't add `.exe` to the archived
    --- binary, so we add it ourselves if missing.
    local function ensure_exe(bin_path)
        if not is_windows then return end
        local target = bin_path .. ".exe"
        cmd.exec('if exist ' .. q(bin_path) ..
                 ' if not exist ' .. q(target) ..
                 ' move /Y ' .. q(bin_path) .. ' ' .. q(target))
    end

    mkdir(bin_dir)
    mkdir(tmp_dir)

    -- Install the CLI
    local cli_tarball = "frontseat-" .. version .. "-" .. os_name .. "-" .. arch .. ".tar.gz"
    print("Downloading frontseat " .. version .. "...")
    cmd.exec("gh release download " .. q(tag) ..
             " --repo frontseat-dev/frontseat" ..
             " --pattern " .. q(cli_tarball) ..
             " --dir " .. q(tmp_dir))
    extract(tmp_dir .. "/" .. cli_tarball, bin_dir)
    ensure_exe(bin_dir .. "/frontseat")
    make_executable(bin_dir .. "/frontseat" .. exe)
    rm_file(tmp_dir .. "/" .. cli_tarball)
    print("frontseat " .. version .. " installed successfully!")

    -- Install declared plugins
    local plugins_str = options["plugins"] or options.plugins
    if plugins_str and plugins_str ~= "" then
        for plugin_name in plugins_str:gmatch("[^,]+") do
            plugin_name = plugin_name:match("^%s*(.-)%s*$") -- trim whitespace
            local tool = "frontseat-plugin-" .. plugin_name
            local tarball = tool .. "-" .. version .. "-" .. os_name .. "-" .. arch .. ".tar.gz"

            print("Downloading " .. tool .. " " .. version .. "...")
            cmd.exec("gh release download " .. q(tag) ..
                     " --repo frontseat-dev/frontseat" ..
                     " --pattern " .. q(tarball) ..
                     " --dir " .. q(tmp_dir))
            extract(tmp_dir .. "/" .. tarball, bin_dir)
            ensure_exe(bin_dir .. "/" .. tool)
            make_executable(bin_dir .. "/" .. tool .. exe)
            rm_file(tmp_dir .. "/" .. tarball)
            print(tool .. " " .. version .. " installed successfully!")
        end
    end

    rm_dir(tmp_dir)
    return {}
end
