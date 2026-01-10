--- Lists available frontseat versions from GitHub releases
--- Fetches tags matching 'frontseat@x.y.z' pattern
--- @param ctx table Context with tool info
--- @return table List of available versions
function PLUGIN:BackendListVersions(ctx)
    local tool = ctx.tool
    local result = {}

    -- All tools (CLI and plugins) share the same version from frontseat releases
    local cmd = [[gh release list --repo jbadeau/frontseat --json tagName --jq '.[].tagName' | grep '^frontseat@' | sed 's/frontseat@//' | grep -v '-']]
    local handle = io.popen(cmd)

    if handle then
        for line in handle:lines() do
            -- Skip prerelease versions (contain -)
            if not string.find(line, "-") then
                table.insert(result, line)
            end
        end
        handle:close()
    end

    return { versions = result }
end
