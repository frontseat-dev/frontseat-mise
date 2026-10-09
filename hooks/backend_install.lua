--- Installs a Frontseat tool from its public release.
---   frontseat:cli      -> the frontseat CLI       (artifact: frontseat)
---   frontseat:<name>   -> a plugin, e.g. go       (artifact: frontseat-plugin-<name>)
--- Releases are public in frontseat-dev/frontseat-releases, so every asset
--- downloads over plain HTTPS with no credential and no GitHub CLI.
---
--- A plugin ships as a WASM MODULE: one platform-independent file,
--- frontseat-plugin-<name>.wasm, that the daemon loads under wazero with no
--- filesystem granted. The CLI ships as an archive per os/arch,
--- frontseat-<os>-<arch>.tar.gz (.zip on Windows), holding frontseat, with
--- the Linux launchers fsexec-linux-<arch> beside it in the release.
---
--- Every download is checked against the release's checksums.txt.
local RELEASES = "https://github.com/frontseat-dev/frontseat-releases/releases/download/"

function PLUGIN:BackendInstall(ctx)
    local cmd = require("cmd")
    local http = require("http")

    local tool_name = ctx.tool
    local version = ctx.version
    local install_path = ctx.install_path

    if not tool_name or tool_name == "" then
        error("frontseat tool name cannot be empty (use frontseat:cli or frontseat:<plugin>)")
    end

    local is_cli = (tool_name == "cli")
    if not is_cli and (tool_name:match("[/\\]") or tool_name:match("^frontseat%-plugin%-")) then
        error("use plugin names like frontseat:go, not '" .. tostring(tool_name) .. "'")
    end

    local artifact = is_cli and "frontseat" or ("frontseat-plugin-" .. tool_name)
    local os_name = RUNTIME.osType
    local is_windows = (os_name == "windows")
    local base = RELEASES .. "v" .. version .. "/"
    local bin_dir = install_path .. "/bin"
    local tmp_dir = install_path .. "/tmp"

    local function q(s)
        if is_windows then return '"' .. s .. '"' else return "'" .. s .. "'" end
    end

    if is_windows then
        cmd.exec('if not exist ' .. q(bin_dir) .. ' mkdir ' .. q(bin_dir))
        cmd.exec('if not exist ' .. q(tmp_dir) .. ' mkdir ' .. q(tmp_dir))
    else
        cmd.exec("mkdir -p " .. q(bin_dir) .. " " .. q(tmp_dir))
    end

    -- checksums.txt: "<sha256>  <asset>" per line.
    local resp, err = http.get({ url = base .. "checksums.txt" })
    if err ~= nil or resp.status_code ~= 200 then
        error("frontseat " .. version .. " has no release at " .. base ..
              " (" .. tostring(err or resp.status_code) .. ")")
    end
    local sums = {}
    for sum, name in resp.body:gmatch("(%x+)%s+%*?([^\r\n]+)") do
        sums[name] = sum:lower()
    end

    local function sha256(path)
        local out
        if is_windows then
            out = cmd.exec("certutil -hashfile " .. q(path) .. " SHA256")
            out = out:match("\n(%x+)%s*\n")
        elseif pcall(cmd.exec, "command -v sha256sum") then
            out = cmd.exec("sha256sum " .. q(path)):match("^(%x+)")
        else
            out = cmd.exec("shasum -a 256 " .. q(path)):match("^(%x+)")
        end
        return out and out:lower()
    end

    -- fetch downloads one asset into dir, checked against checksums.txt.
    local function fetch(name, dir)
        local want = sums[name]
        if not want then
            error(name .. " is not in frontseat " .. version .. "'s checksums.txt")
        end
        local path = dir .. "/" .. name
        local derr = http.download_file({ url = base .. name }, path)
        if derr ~= nil then
            error("downloading " .. base .. name .. ": " .. tostring(derr))
        end
        local got = sha256(path)
        if got ~= want then
            error(name .. ": sha256 " .. tostring(got) .. ", checksums.txt says " .. want)
        end
        return path
    end

    print("Downloading " .. artifact .. " " .. version .. "...")

    if not is_cli then
        fetch(artifact .. ".wasm", bin_dir)
    else
        local archive = artifact .. "-" .. os_name .. "-" .. RUNTIME.archType .. (is_windows and ".zip" or ".tar.gz")
        local path = fetch(archive, tmp_dir)
        -- tar -xf reads gzip (GNU tar) and zip (bsdtar on Windows).
        cmd.exec("tar -xf " .. q(path) .. " -C " .. q(bin_dir))
        if is_windows then
            cmd.exec('if exist ' .. q(bin_dir .. "/frontseat") ..
                     ' if not exist ' .. q(bin_dir .. "/frontseat.exe") ..
                     ' move /Y ' .. q(bin_dir .. "/frontseat") .. ' ' .. q(bin_dir .. "/frontseat.exe"))
        else
            cmd.exec("chmod +x " .. q(bin_dir .. "/frontseat"))
        end

        -- A grid runs actions through the launcher built for its platform,
        -- which the CLI finds beside itself: the release carries one for
        -- each Linux grid, whatever machine the CLI runs on.
        for _, grid_arch in ipairs({ "amd64", "arm64" }) do
            local launcher = fetch("fsexec-linux-" .. grid_arch, bin_dir)
            if not is_windows then
                cmd.exec("chmod +x " .. q(launcher))
            end
        end
    end

    if is_windows then
        cmd.exec('if exist ' .. q(tmp_dir) .. ' rmdir /S /Q ' .. q(tmp_dir))
    else
        cmd.exec("rm -rf " .. q(tmp_dir))
    end
    print(artifact .. " " .. version .. " installed successfully!")
    return {}
end
