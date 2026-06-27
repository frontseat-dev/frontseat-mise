--- Lists available frontseat CLI versions from GitHub releases.
---
--- mise/vfox tool plugins return an array of version records from Available.
--- Keep the same stable-release policy the backend plugin used: drafts and
--- prereleases are excluded, and GitHub's latest release is hoisted to the end.
function PLUGIN:Available(ctx)
    local cmd = require("cmd")
    local json = require("json")

    local raw = cmd.exec(
        "gh release list --repo frontseat-dev/frontseat --limit 100 " ..
        "--json tagName,isPrerelease,isDraft"
    )
    local releases = json.decode(raw) or {}

    local versions = {}
    for _, r in ipairs(releases) do
        if r.isPrerelease == false and r.isDraft == false then
            local ver = (r.tagName or ""):match("^v(.+)")
            if ver then
                table.insert(versions, ver)
            end
        end
    end

    table.sort(versions, function(a, b)
        local function parts(s)
            local t = {}
            for n in s:gmatch("%d+") do t[#t+1] = tonumber(n) end
            return t
        end
        local pa, pb = parts(a), parts(b)
        for i = 1, math.max(#pa, #pb) do
            local na, nb = pa[i] or 0, pb[i] or 0
            if na ~= nb then return na > nb end
        end
        return false
    end)

    local ok, latestRaw = pcall(cmd.exec,
        "gh api repos/frontseat-dev/frontseat/releases/latest --jq .tag_name"
    )
    local latestVer
    if ok and latestRaw then
        for line in latestRaw:gmatch("[^\r\n]+") do
            local v = line:match("^v(.+)")
            if v then latestVer = v; break end
        end
    end

    -- Newest first: mise resolves `latest` to the first entry, so the GitHub
    -- "latest" release (which may not be the highest version number, e.g. a
    -- backport) goes to the front.
    if latestVer then
        local hoisted = { latestVer }
        for _, v in ipairs(versions) do
            if v ~= latestVer then table.insert(hoisted, v) end
        end
        versions = hoisted
    end

    local available = {}
    for _, version in ipairs(versions) do
        table.insert(available, { version = version })
    end

    return available
end
