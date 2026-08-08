--- Installs a Frontseat tool from GitHub releases.
---   frontseat:cli      -> the frontseat CLI       (artifact: frontseat)
---   frontseat:<name>   -> a plugin, e.g. go       (artifact: frontseat-plugin-<name>)
--- Downloads the release archive for the current os/arch with `gh` (the repo
--- may be private, so gh provides auth), extracts the binary into
--- <install_path>/bin, and marks it executable.
function PLUGIN:BackendInstall(ctx)
    local cmd = require("cmd")
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

    print("Downloading " .. artifact .. " " .. version .. "...")
    cmd.exec("gh release download " .. q(tag) ..
             " --repo frontseat-dev/frontseat" ..
             " --pattern " .. q(filename) ..
             " --dir " .. q(tmp_dir))

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
