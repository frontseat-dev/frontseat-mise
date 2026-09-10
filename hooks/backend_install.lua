--- Installs a Frontseat tool from GitHub releases.
---   frontseat:cli      -> the frontseat CLI       (artifact: frontseat)
---   frontseat:<name>   -> a plugin, e.g. go       (artifact: frontseat-plugin-<name>)
--- Downloads the release archive with `gh` (the repo may be private, so gh
--- provides auth), extracts it into <install_path>/bin, and marks a binary
--- executable.
---
--- A plugin ships as a WASM MODULE where it can: one platform-independent
--- artifact instead of one archive per os/arch. The daemon loads such a
--- module under wazero with no filesystem granted, and prefers it over a
--- same-named binary. Not every plugin qualifies — one whose own task
--- commands invoke its executable (homebrew, scoop) still needs a binary, as
--- does the CLI — so the module is TRIED and the per-platform archive is the
--- fallback. That ordering, rather than a hardcoded list, is what keeps this
--- plugin working against older releases (which have no modules at all) and
--- against future changes to which plugins qualify.
function PLUGIN:BackendInstall(ctx)
    local cmd = require("cmd")

    -- `depends = { "gh" }` in metadata.lua orders gh first and exposes it on
    -- PATH *when gh is a mise-managed tool*; it does not guarantee gh exists.
    -- Fail early with an actionable message instead of a cryptic exec error.
    if not pcall(cmd.exec, "gh --version") then
        error("frontseat backend requires the GitHub CLI (gh). " ..
              "Install it with `mise use -g gh`, or add gh to your mise.toml.")
    end

    local tool_name = ctx.tool
    local version = ctx.version
    local install_path = ctx.install_path

    if not tool_name or tool_name == "" then
        error("frontseat tool name cannot be empty (use frontseat:cli or frontseat:<plugin>)")
    end

    local is_cli = (tool_name == "cli")
    if not is_cli then
        if tool_name:match("[/\\]") or tool_name:match("^frontseat%-plugin%-") then
            error("use plugin names like frontseat:go, not '" .. tostring(tool_name) .. "'")
        end
    end

    local artifact = is_cli and "frontseat" or ("frontseat-plugin-" .. tool_name)

    local os_name = RUNTIME.osType
    local arch = RUNTIME.archType
    local tag = "v" .. version
    local is_windows = (os_name == "windows")
    local module_file = artifact .. "-" .. version .. "-wasm.tar.gz"
    -- Frontseat ships a .zip on Windows (binary inside), .tar.gz elsewhere.
    local ext = is_windows and ".zip" or ".tar.gz"
    local exe = is_windows and ".exe" or ""
    local filename = artifact .. "-" .. version .. "-" .. os_name .. "-" .. arch .. ext
    local bin_dir = install_path .. "/bin"
    local tmp_dir = install_path .. "/tmp"

    local function q(s)
        if is_windows then return '"' .. s .. '"' else return "'" .. s .. "'" end
    end

    local function mkdir(path)
        if is_windows then
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

    mkdir(bin_dir)
    mkdir(tmp_dir)

    local function download(pattern)
        return pcall(cmd.exec, "gh release download " .. q(tag) ..
                     " --repo frontseat-dev/frontseat" ..
                     " --pattern " .. q(pattern) ..
                     " --dir " .. q(tmp_dir))
    end

    print("Downloading " .. artifact .. " " .. version .. "...")

    -- The module first, for anything but the CLI. A release that has one
    -- publishes no per-platform archives for that plugin, so this is not a
    -- preference between two available forms — it is the only artifact.
    if not is_cli and download(module_file) then
        -- tar -xf auto-detects gzip (GNU tar) and reads zip (bsdtar on Windows).
        cmd.exec("tar -xf " .. q(tmp_dir .. "/" .. module_file) .. " -C " .. q(bin_dir))
        rm_file(tmp_dir .. "/" .. module_file)
        rm_dir(tmp_dir)
        -- No chmod: a module is not executed, it is loaded.
        print(artifact .. " " .. version .. " installed successfully (wasm module)!")
        return {}
    end

    local ok = download(filename)
    if not ok then
        error("no artifact for " .. artifact .. " " .. version .. ": tried " ..
              (is_cli and "" or (module_file .. " and ")) .. filename ..
              ". Check that the release exists and includes this tool.")
    end

    -- tar -xf auto-detects gzip (GNU tar) and reads zip (bsdtar on Windows).
    cmd.exec("tar -xf " .. q(tmp_dir .. "/" .. filename) .. " -C " .. q(bin_dir))

    if is_windows then
        cmd.exec('if exist ' .. q(bin_dir .. "/" .. artifact) ..
                 ' if not exist ' .. q(bin_dir .. "/" .. artifact .. ".exe") ..
                 ' move /Y ' .. q(bin_dir .. "/" .. artifact) .. ' ' ..
                 q(bin_dir .. "/" .. artifact .. ".exe"))
    else
        cmd.exec("chmod +x " .. q(bin_dir .. "/" .. artifact .. exe))
    end

    rm_file(tmp_dir .. "/" .. filename)
    rm_dir(tmp_dir)
    print(artifact .. " " .. version .. " installed successfully!")

    return {}
end
