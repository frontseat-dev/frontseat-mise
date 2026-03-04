--- Sets up environment variables for frontseat
--- All binaries (CLI + plugins) are in the same bin directory
--- @param ctx table Context with install_path and tool
--- @return table Environment variables to set
function PLUGIN:BackendExecEnv(ctx)
    return {
        env_vars = {
            { key = "PATH", value = ctx.install_path .. "/bin" },
            { key = "FRONTSEAT_HOME", value = ctx.install_path }
        }
    }
end
