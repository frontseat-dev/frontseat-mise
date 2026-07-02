--- Lists available Frontseat versions from GitHub releases.
--- This backend installs the Frontseat CLI (`frontseat:cli`) and every Frontseat
--- plugin (`frontseat:<name>`, e.g. `frontseat:go`). All share one versioned
--- release stream, so version listing is the same for every tool.
--- Drafts and prereleases are excluded; GitHub's "latest" is hoisted last.
function PLUGIN:BackendListVersions(ctx)
    local cmd = require("cmd")
    local json = require("json")

    if not ctx.tool or ctx.tool == "" then
        error("frontseat tool name cannot be empty (use frontseat:cli or frontseat:<plugin>)")
    end

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
            if na ~= nb then return na < nb end
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

    if latestVer then
        local hoisted = {}
        for _, v in ipairs(versions) do
            if v ~= latestVer then table.insert(hoisted, v) end
        end
        table.insert(hoisted, latestVer)
        versions = hoisted
    end

    return { versions = versions }
end
