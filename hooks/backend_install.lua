--- Installs the frontseat CLI and any declared plugins.
--- Plugins are declared via the "plugins" option as a comma-separated string:
---   "frontseat:frontseat" = { version = "latest", plugins = "maven,docker,go" }
---
--- Cross-platform notes:
---   * On Windows, vfox routes cmd.exec through `cmd /C <string>`, but the
---     spawning layer escapes embedded double quotes as \" (MSVC rules),
---     which cmd.exe does not parse — any command containing a double quote
---     is corrupted before cmd.exe sees it. We therefore avoid double quotes
---     entirely: every command runs through `powershell -NoProfile -Command`
---     with single-quoted arguments (PowerShell treats them as string
---     delimiters; cmd passes them through untouched). The command string
---     must also avoid cmd metacharacters (| & ^ < > parens), so each call
---     is a single statement; braces are safe.
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
        -- Both PowerShell (Windows) and sh group with single quotes; escape
        -- embedded ones by doubling (PowerShell rule; mise paths never
        -- contain them, but usernames can). On Windows also flip forward
        -- slashes from the "/bin"-style concats above to backslashes.
        if is_windows then return "'" .. s:gsub("/", "\\"):gsub("'", "''") .. "'"
        else return "'" .. s .. "'" end
    end

    --- Run a command; on Windows wrap it in powershell to avoid the
    --- double-quote corruption described in the header notes.
    local function run(c)
        if is_windows then
            return cmd.exec("powershell -NoProfile -Command " .. c)
        end
        return cmd.exec(c)
    end

    local function mkdir(path)
        if is_windows then
            -- -Force makes New-Item succeed when the directory already
            -- exists, and it creates intermediate directories.
            run("New-Item -ItemType Directory -Force -Path " .. q(path))
        else
            run("mkdir -p " .. q(path))
        end
    end

    -- Deletions are best-effort (match `rm -f`/`rm -rf`): a suppressed
    -- PowerShell error still exits 1 from -Command, so swallow with
    -- try/catch to keep the exit code 0.
    local function rm_file(path)
        if is_windows then
            run("try { Remove-Item -Force -Path " .. q(path) ..
                " -ErrorAction Stop } catch { }")
        else
            run("rm -f " .. q(path))
        end
    end

    local function rm_dir(path)
        if is_windows then
            run("try { Remove-Item -Recurse -Force -Path " .. q(path) ..
                " -ErrorAction Stop } catch { }")
        else
            run("rm -rf " .. q(path))
        end
    end

    local function extract(tarball, dest)
        run("tar -xzf " .. q(tarball) .. " -C " .. q(dest))
    end

    local function make_executable(path)
        if not is_windows then
            run("chmod +x " .. q(path))
        end
    end

    --- Ensure the extracted binary has the `.exe` suffix on Windows.
    --- Upstream's Go build pipeline doesn't add `.exe` to the archived
    --- binary, so we add it ourselves if missing.
    local function ensure_exe(bin_path)
        if not is_windows then return end
        local target = bin_path .. ".exe"
        -- Slight semantic drift from the old `if not exist <target>` guard:
        -- -Force overwrites an existing target instead of skipping. The
        -- source is the freshly extracted binary, so the overwrite is
        -- idempotent; a missing source is swallowed like before.
        run("try { Move-Item -Force -Path " .. q(bin_path) ..
            " -Destination " .. q(target) ..
            " -ErrorAction Stop } catch { }")
    end

    mkdir(bin_dir)
    mkdir(tmp_dir)

    -- Install the CLI
    local cli_tarball = "frontseat-" .. version .. "-" .. os_name .. "-" .. arch .. ".tar.gz"
    print("Downloading frontseat " .. version .. "...")
    run("gh release download " .. q(tag) ..
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
            run("gh release download " .. q(tag) ..
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
