--- Lists available frontseat versions from GitHub releases
--- @param ctx table Context with tool info
--- @return table List of available versions
function PLUGIN:BackendListVersions(ctx)
    local cmd = require("cmd")
    local result = cmd.exec("gh release list --repo jbadeau/frontseat --json tagName --jq '.[].tagName'")
    local versions = {}
    for line in result:gmatch("[^\r\n]+") do
        local ver = line:match("^v(.+)")
        if ver and not ver:find("-") then
            table.insert(versions, ver)
        end
    end
    -- Sort ascending so mise picks the last one as "latest"
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
