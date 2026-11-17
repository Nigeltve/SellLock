-- SellLock: /slock slash command.
local _, ns = ...

local logger = ns.logger

local function status()
    logger:Say(("v%s enabled=%s"):format(ns.VERSION, tostring(ns.IsEnabled())))
end

SLASH_SELLLOCK1 = "/selllock"
SLASH_SELLLOCK2 = "/slock"
SlashCmdList.SELLLOCK = function(msg)
    local cmd = (msg or ""):lower():match("^%s*(%S*)")
    if cmd == "" then
        logger:Say("v" .. ns.VERSION .. "  (/slock help for commands)")
        ns.OpenOptions()
    elseif cmd == "config" then
        ns.OpenOptions()
    elseif cmd == "toggle" then
        local on = not ns.IsEnabled()
        ns.SetEnabled(on)
        logger:Say(on and "enabled for this character." or "disabled for this character.")
    elseif cmd == "status" then
        status()
    elseif cmd == "lock" then
        ns.ToggleHoveredLock()
    else
        logger:Say("/slock [config | toggle | status | lock]")
    end
end
