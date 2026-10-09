--- Lists Frontseat's versions from its public releases.
--- This backend installs the Frontseat CLI (`frontseat:cli`) and every Frontseat
--- plugin (`frontseat:<name>`, e.g. `frontseat:go`). All share one versioned
--- release stream, so version listing is the same for every tool.
--- Drafts are excluded. Prereleases are LISTED but never hoisted: semver
--- only selects a prerelease when one is asked for by name, and a
--- prerelease exists so a branch can be installed the way a user would
--- install it.
---
--- The releases are public, so the listing needs no credential. GitHub
--- limits anonymous API calls by address; with GITHUB_TOKEN or GH_TOKEN
--- set, the call is made with it and the limit is the token's.
local API = "https://api.github.com/repos/frontseat-dev/frontseat-releases/releases"

function PLUGIN:BackendListVersions(ctx)
    local http = require("http")
    local json = require("json")

    if not ctx.tool or ctx.tool == "" then
        error("frontseat tool name cannot be empty (use frontseat:cli or frontseat:<plugin>)")
    end

    local headers = { ["Accept"] = "application/vnd.github+json" }
    local token = os.getenv("GITHUB_TOKEN") or os.getenv("GH_TOKEN")
    if token and token ~= "" then
        headers["Authorization"] = "Bearer " .. token
    end

    local resp, err = http.get({ url = API .. "?per_page=100", headers = headers })
    if err ~= nil or resp.status_code ~= 200 then
        error("listing Frontseat releases: " .. tostring(err or (resp.status_code .. " " .. (resp.body or ""))))
    end
    local releases = json.decode(resp.body) or {}

    local versions = {}
    local latest
    for _, r in ipairs(releases) do
        local ver = (r.tag_name or ""):match("^v(.+)")
        if ver and not r.draft then
            table.insert(versions, ver)
            -- The API lists newest first; the first stable one is the latest.
            if not r.prerelease and not latest then
                latest = ver
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

    -- Hoist the stable latest to the end: mise treats the last entry as the
    -- newest, and a prerelease must never become what "latest" resolves to.
    if latest then
        local hoisted = {}
        for _, v in ipairs(versions) do
            if v ~= latest then table.insert(hoisted, v) end
        end
        table.insert(hoisted, latest)
        versions = hoisted
    end

    return { versions = versions }
end
