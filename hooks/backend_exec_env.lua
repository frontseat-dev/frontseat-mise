--- Adds the installed Frontseat binary to PATH. For the CLI, also exports
--- FRONTSEAT_HOME.
function PLUGIN:BackendExecEnv(ctx)
    local env_vars = {
        { key = "PATH", value = ctx.install_path .. "/bin" }
    }
    if ctx.tool == "cli" then
        table.insert(env_vars, { key = "FRONTSEAT_HOME", value = ctx.install_path })
    end
    return { env_vars = env_vars }
end
