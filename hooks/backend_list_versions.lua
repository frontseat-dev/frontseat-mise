--- Lists available frontseat versions from GitHub releases.
---
--- Two rules drive what ends up in the returned list and how mise resolves
--- the "latest" alias:
---
---  1. Only stable releases are listed. A release is "stable" when GitHub
---     marks it as neither prerelease nor draft. Tag-name heuristics (e.g.
---     "contains a -") are not authoritative — a release may be a clean
---     SemVer tag yet still be flagged as prerelease, or vice versa.
---     Prereleases remain installable by exact version (the install hook
---     constructs the asset name from the version string directly and
---     never consults this list), they just don't pollute "latest".
---
---  2. The release tagged `latest` on GitHub wins, even if a higher SemVer
---     stable release exists. mise picks the last entry in the returned
---     list as the "latest" alias, so we sort ascending by SemVer and then
---     hoist GitHub's `latest` tag to the end. This matters when a newer
---     release gets retracted (admin unmarks it as latest because of a
---     regression) — without this hoist, mise would still install the
---     broken higher version.
---
--- Filtering is done in Lua against gh's raw JSON rather than via a `--jq`
--- filter. cmd.exe (which vfox uses to shell out on Windows) treats single
--- quotes as literal characters and `|` as a pipe operator, so a filter
--- like `'.[] | select(...) | .tagName'` is parsed as a cmd.exe pipeline
--- and fails with "'select' is not recognized…".
---
--- @param ctx table Context with tool info
--- @return table List of available stable versions
function PLUGIN:BackendListVersions(ctx)
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

    -- Ascending SemVer sort.
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

    -- Hoist GitHub's `latest` tag to the end of the list so mise's
    -- "latest" alias follows the GitHub release label, not raw SemVer
    -- ordering. If the API call fails (network, auth, or no release is
    -- flagged latest) we fall back to SemVer-sorted order.
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
