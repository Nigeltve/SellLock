-- SellLock: event wiring.
local ADDON, ns = ...

local events = CreateFrame("Frame")
local handlers = {}

function handlers.ADDON_LOADED(name)
    if name ~= ADDON then return end
    ns.InitDB()
    ns.CreateOptions()
    ns.HookBagButtons()
    events:UnregisterEvent("ADDON_LOADED")
end

-- Fires after a burst of bag changes (a sale, a buyback, moving items).
function handlers.BAG_UPDATE_DELAYED() ns.RefreshLocks() end
-- Fires when the buyback list changes, which can come after the bag update for a sale.
function handlers.MERCHANT_UPDATE() ns.RefreshLocks() end
function handlers.MERCHANT_SHOW() ns.SetMerchantOpen(true) end
function handlers.MERCHANT_CLOSED() ns.SetMerchantOpen(false) end

events:SetScript("OnEvent", function(_, event, ...)
    local h = handlers[event]
    if h then h(...) end
end)
for event in pairs(handlers) do
    pcall(events.RegisterEvent, events, event) -- some events may not exist on every client
end
