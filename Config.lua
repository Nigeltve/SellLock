-- SellLock: saved variables and settings.
-- SL_DB (account): shared settings.  SL_DB_CHAR (character): enabled.
local _, ns = ...

local DEFAULTS = {}
local CHAR_DEFAULTS = { enabled = true }

function ns.InitDB()
    SL_DB = type(SL_DB) == "table" and SL_DB or {}
    SL_DB_CHAR = type(SL_DB_CHAR) == "table" and SL_DB_CHAR or {}
    for k, v in pairs(DEFAULTS) do
        if type(SL_DB[k]) ~= type(v) then SL_DB[k] = v end
    end
    for k, v in pairs(CHAR_DEFAULTS) do
        if type(SL_DB_CHAR[k]) ~= type(v) then SL_DB_CHAR[k] = v end
    end
end

-- Falls back to the default if saved variables aren't loaded yet.
function ns.Get(key)
    local value = SL_DB and SL_DB[key]
    if value == nil then value = DEFAULTS[key] end
    return value
end

function ns.IsEnabled()
    return SL_DB_CHAR and SL_DB_CHAR.enabled
end

function ns.SetEnabled(on)
    SL_DB_CHAR.enabled = on and true or false
    ns.SyncOptions()
    ns.RefreshLocks()
end
