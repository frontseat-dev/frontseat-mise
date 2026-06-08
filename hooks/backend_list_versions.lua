--- Lists available frontseat versions from GitHub releases.
---
--- IMPORTANT: This intentionally filters out SemVer prereleases (any tag
--- containing a "-", e.g. v0.2.0-rc.1, v0.2.0-feature-foo.1) so that
--- mise's "latest" resolves to the highest STABLE release.
---
--- Frontseat publishes prereleases as preview builds from feature
--- branches. Those are still installable explicitly
--- (e.g. `mise install frontseat:frontseat@0.2.0-feature-foo.1`) — the
--- install hook constructs the asset name from the version string and
--- doesn't consult this list — but they must not pollute "latest".
---
--- @param ctx table Context with tool info
--- @return table List of available stable versions
function PLUGIN:BackendListVersions(ctx)
    local cmd = require("cmd")
    local result = cmd.exec("gh release list --repo frontseat-dev/frontseat --json tagName --jq '.[].tagName'")
    local versions = {}
    for line in result:gmatch("[^\r\n]+") do
        local ver = line:match("^v(.+)")
        -- ver:find("-") returns a position when the version has a
        -- prerelease identifier; nil otherwise. Skip prereleases.
        if ver and not ver:find("-") then
            table.insert(versions, ver)
        end
    end
    -- Sort ascending so mise picks the last one as "latest".
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
    return { versions = versions }
end
