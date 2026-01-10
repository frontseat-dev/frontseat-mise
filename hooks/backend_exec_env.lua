--- Sets up environment variables for frontseat CLI or plugins
--- @param ctx table Context with install_path and tool
--- @return table Environment variables to set
function PLUGIN:BackendExecEnv(ctx)
    local install_path = ctx.install_path
    local tool = ctx.tool

    if tool == "frontseat" then
        -- CLI: add to PATH and set FRONTSEAT_HOME
        return {
            env_vars = {
                { key = "PATH", value = install_path .. "/bin" },
                { key = "FRONTSEAT_HOME", value = install_path }
            }
        }
    else
        -- Plugin: just add to PATH (frontseat discovers plugins via PATH)
        return {
            env_vars = {
                { key = "PATH", value = install_path .. "/bin" }
            }
        }
    end
end
