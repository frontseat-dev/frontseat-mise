--- Advertises the Frontseat CLI version to install.
---
--- The actual download+extract happens in PostInstall: the release lives on a
--- private repo (so `gh` must fetch it, for auth), and mise refuses to fetch a
--- `file://` URL, so PreInstall cannot hand mise a locally-downloaded tarball.
--- It only needs to return the version.
function PLUGIN:PreInstall(ctx)
    return {
        version = ctx.version,
        note = "Installing frontseat " .. ctx.version
    }
end
