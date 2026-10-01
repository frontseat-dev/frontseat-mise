--- Installs a Frontseat tool from GitHub releases.
---   frontseat:cli      -> the frontseat CLI       (artifact: frontseat)
---   frontseat:<name>   -> a plugin, e.g. go       (artifact: frontseat-plugin-<name>)
--- Downloads the release archive with `gh` (the repo may be private, so gh
--- provides auth), extracts it into <install_path>/bin, and marks a binary
--- executable.
---
--- A plugin ships as a WASM MODULE: one platform-independent file the
--- daemon loads under wazero with no filesystem granted. The CLI ships as
--- an archive per os/arch holding frontseat and fsexec.
---
--- Releases name their assets for what they hold, never for the version:
--- frontseat-plugin-<name>.wasm and frontseat-<os>-<arch>.tar.gz. Releases
--- before 0.42.0 named them with it, a module as
--- <artifact>-<version>-wasm.tar.gz and an archive as
--- <artifact>-<version>-<os>-<arch>.tar.gz; a published release never
--- changes, so those names are tried after.
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
    local module_file = artifact .. ".wasm"
    local module_archive = artifact .. "-" .. version .. "-wasm.tar.gz"
    -- Frontseat ships a .zip on Windows (binary inside), .tar.gz elsewhere.
    local ext = is_windows and ".zip" or ".tar.gz"
    local exe = is_windows and ".exe" or ""
    local archives = {
        artifact .. "-" .. os_name .. "-" .. arch .. ext,
        artifact .. "-" .. version .. "-" .. os_name .. "-" .. arch .. ext,
    }
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

    -- A plugin is a module, the file itself or, before 0.42.0, archived.
    if not is_cli then
        if download(module_file) then
            local from, to = q(tmp_dir .. "/" .. module_file), q(bin_dir .. "/" .. module_file)
            cmd.exec(is_windows and ("move /Y " .. from .. " " .. to) or ("mv " .. from .. " " .. to))
            rm_dir(tmp_dir)
            print(artifact .. " " .. version .. " installed successfully (wasm module)!")
            return {}
        end
        if download(module_archive) then
            -- tar -xf auto-detects gzip (GNU tar) and reads zip (bsdtar on Windows).
            cmd.exec("tar -xf " .. q(tmp_dir .. "/" .. module_archive) .. " -C " .. q(bin_dir))
            rm_dir(tmp_dir)
            print(artifact .. " " .. version .. " installed successfully (wasm module)!")
            return {}
        end
    end

    local filename
    for _, name in ipairs(archives) do
        if download(name) then
            filename = name
            break
        end
    end
    if not filename then
        error("no artifact for " .. artifact .. " " .. version .. ": tried " ..
              (is_cli and "" or (module_file .. ", " .. module_archive .. ", ")) .. table.concat(archives, ", ") ..
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

    -- A grid runs actions through the launcher built for its platform,
    -- which the CLI finds beside itself: the release carries one for each
    -- Linux grid, whatever machine the CLI runs on.
    if is_cli then
        for _, grid_arch in ipairs({ "amd64", "arm64" }) do
            local launcher = "fsexec-linux-" .. grid_arch
            if download(launcher) then
                local from, to = q(tmp_dir .. "/" .. launcher), q(bin_dir .. "/" .. launcher)
                cmd.exec(is_windows and ("move /Y " .. from .. " " .. to) or ("mv " .. from .. " " .. to))
                if not is_windows then
                    cmd.exec("chmod +x " .. to)
                end
            end
        end
    end

    rm_dir(tmp_dir)
    print(artifact .. " " .. version .. " installed successfully!")

    return {}
end
