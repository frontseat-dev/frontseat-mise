--- Sets up environment variables for frontseat.
function PLUGIN:EnvKeys(ctx)
    return {
        { key = "PATH", value = ctx.path },
        { key = "FRONTSEAT_HOME", value = ctx.path }
    }
end
