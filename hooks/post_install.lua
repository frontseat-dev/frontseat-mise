--- Downloads the Frontseat CLI release asset and installs it.
---
--- Done here (rather than via a URL returned from PreInstall) because the
--- release is on a private repo — `gh` fetches it with the caller's auth — and
--- mise refuses to fetch the resulting `file://` path. We download with `gh`,
--- extract into the install dir, and make the binary executable.
function PLUGIN:PostInstall(ctx)
    local cmd = require("cmd")
    local path = ctx.rootPath
    -- PostInstall's ctx has no `version` field; the install dir is named after
    -- it (.../installs/frontseat/<version>), so derive it from rootPath.
    local version = ctx.version
    if not version or version == "" then
        version = (path:gsub("[/\\]+$", "")):match("([^/\\]+)$")
    end
    local os_name = RUNTIME.osType
    local arch = RUNTIME.archType
    local tag = "v" .. version
    local is_windows = (os_name == "windows")
    local sep = package.config:sub(1, 1)
    local filename = "frontseat-" .. version .. "-" .. os_name .. "-" .. arch .. ".tar.gz"
    local tmp_root = os.getenv("TMPDIR") or os.getenv("TEMP") or os.getenv("TMP") or "/tmp"
    local tmp_dir = table.concat({
        tmp_root,
        "frontseat-mise",
        version .. "-" .. os_name .. "-" .. arch
    }, sep)
    local tarball = tmp_dir .. sep .. filename

    local function q(s)
        if is_windows then return '"' .. s .. '"' else return "'" .. s .. "'" end
    end

    -- Fresh temp dir for the download.
    if is_windows then
        cmd.exec('if not exist ' .. q(tmp_dir) .. ' mkdir ' .. q(tmp_dir))
        cmd.exec('if exist ' .. q(tarball) .. ' del /F /Q ' .. q(tarball))
    else
        cmd.exec("mkdir -p " .. q(tmp_dir))
        cmd.exec("rm -f " .. q(tarball))
    end

    cmd.exec("gh release download " .. q(tag) ..
             " --repo frontseat-dev/frontseat" ..
             " --pattern " .. q(filename) ..
             " --dir " .. q(tmp_dir))

    -- Extract into the install dir.
    cmd.exec("tar -xzf " .. q(tarball) .. " -C " .. q(path))

    -- Make the CLI runnable.
    if is_windows then
        local bin_path = path .. sep .. "frontseat"
        local target = bin_path .. ".exe"
        cmd.exec('if exist ' .. q(bin_path) ..
                 ' if not exist ' .. q(target) ..
                 ' move /Y ' .. q(bin_path) .. ' ' .. q(target))
    else
        cmd.exec("chmod +x " .. q(path .. "/frontseat"))
    end

    -- Clean up the download.
    if is_windows then
        cmd.exec('if exist ' .. q(tarball) .. ' del /F /Q ' .. q(tarball))
    else
        cmd.exec("rm -f " .. q(tarball))
    end
end
