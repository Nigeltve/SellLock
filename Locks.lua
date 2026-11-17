-- SellLock: sell-locked stacks, click blocking, auto-buyback, lock icons and the hovered-item keybind.
-- A lock belongs to one stack (its item GUID), saved per character in SL_DB_CHAR.locks.
local _, ns = ...

local logger = ns.logger

BINDING_HEADER_SELLLOCK = "SellLock"
BINDING_NAME_SELLLOCK_TOGGLE = "Toggle sell lock on hovered item"

local LAST_BAG = NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4
local ICON = "Interface\\LFGFrame\\UI-LFG-ICON-LOCK"

local merchantOpen = false
local stacks = {}     -- guid -> { itemID, count, link }: the bags at the last scan
local sold = {}       -- guid -> stack: locked stacks gone from the bags while the merchant is open
local returning = {}  -- { guid, itemID, count, link }: bought back, waiting to be re-locked
local hoveredBag, hoveredSlot
local buttons = setmetatable({}, { __mode = "k" }) -- bag button -> function returning bag, slot
local icons = setmetatable({}, { __mode = "k" })
local clickFrames = setmetatable({}, { __mode = "k" }) -- bag button -> the frame that gets its clicks
local blockers = setmetatable({}, { __mode = "k" })

local function Locks()
    if type(SL_DB_CHAR.locks) ~= "table" then SL_DB_CHAR.locks = {} end
    return SL_DB_CHAR.locks
end

-- GetItemGUID raises on an empty location, so check DoesItemExist first.
local function GUIDAt(bag, slot)
    local ok, guid = pcall(function()
        local location = ItemLocation:CreateFromBagAndSlot(bag, slot)
        return C_Item.DoesItemExist(location) and C_Item.GetItemGUID(location) or nil
    end)
    if ok and guid and not ns.IsSecret(guid) then return guid end
end

local function IsLockedAt(bag, slot)
    local guid = GUIDAt(bag, slot)
    return guid ~= nil and Locks()[guid] == true
end

local function ScanBags()
    local found = {}
    for bag = 0, LAST_BAG do
        for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
            local guid = GUIDAt(bag, slot)
            local info = guid and C_Container.GetContainerItemInfo(bag, slot)
            if info then
                found[guid] = { itemID = info.itemID, count = info.stackCount or 1, link = info.hyperlink }
            end
        end
    end
    return found
end

-- Newest first: a fresh sale is the last buyback entry.
local function FindBuyback(itemID, count, taken)
    for index = GetNumBuybackItems(), 1, -1 do
        local link = GetBuybackItemLink(index)
        local _, _, _, quantity = GetBuybackItemInfo(index)
        if not taken[index] and link and quantity == count and C_Item.GetItemInfoInstant(link) == itemID then
            return index
        end
    end
end

-- Our own frame over a locked slot while a merchant is open takes the click (and stops drags),
-- so the Blizzard button underneath never sells it. Mouse motion passes through so the
-- tooltip, and with it the keybind, still works.
local function UpdateBlocker(button, block)
    local target = clickFrames[button] or button
    local blocker = blockers[button]
    if block and not blocker then
        blocker = CreateFrame("Button", nil, target)
        blocker:SetAllPoints()
        blocker:RegisterForClicks("AnyUp")
        blocker:SetScript("OnClick", function()
            logger:Say("That stack is sell-locked. Unlock it with your keybind first.")
        end)
        if blocker.SetPropagateMouseMotion then blocker:SetPropagateMouseMotion(true) end
        blockers[button] = blocker
    end
    if not blocker then return end
    if block then blocker:SetFrameLevel(target:GetFrameLevel() + 5) end
    blocker:SetShown(block)
end

local function UpdateButton(button)
    local where = buttons[button]
    local ok, bag, slot = pcall(where)
    local locked = (ok and bag and slot and ns.IsEnabled() and IsLockedAt(bag, slot)) and true or false
    UpdateBlocker(button, locked and merchantOpen)
    local icon = icons[button]
    if locked and not icon then
        icon = button:CreateTexture(nil, "OVERLAY", nil, 5)
        icon:SetTexture(ICON)
        icon:SetSize(16, 16)
        icon:SetPoint("TOPRIGHT", -1, -1)
        icons[button] = icon
    end
    if icon then icon:SetShown(locked) end
end

local function UpdateAllButtons()
    for button in pairs(buttons) do UpdateButton(button) end
end

-- Re-lock stacks that came back from the buyback tab (they may get a new GUID).
local function RelockReturned(now)
    local locks = Locks()
    for i = #returning, 1, -1 do
        local entry = returning[i]
        for guid, stack in pairs(now) do
            if not stacks[guid] and not locks[guid] and stack.itemID == entry.itemID and stack.count == entry.count then
                locks[entry.guid] = nil
                locks[guid] = true
                table.remove(returning, i)
                logger:Say(("Bought back %s x%d — it's sell-locked."):format(entry.link or "item", entry.count))
                break
            end
        end
    end
end

local function BuyBackSold()
    local taken = {}
    for guid, stack in pairs(sold) do
        local index = FindBuyback(stack.itemID, stack.count, taken)
        if index then
            taken[index] = true
            sold[guid] = nil
            local ok = pcall(BuybackItem, index)
            if ok then
                returning[#returning + 1] = { guid = guid, itemID = stack.itemID, count = stack.count, link = stack.link }
            else
                logger:Say(("Couldn't buy back %s — check the buyback tab."):format(stack.link or "item"))
            end
        end
    end
end

function ns.RefreshLocks()
    local now = ScanBags()
    RelockReturned(now)
    if merchantOpen and ns.IsEnabled() then
        local locks = Locks()
        for guid, stack in pairs(stacks) do
            if locks[guid] and not now[guid] then sold[guid] = stack end
        end
        BuyBackSold()
    end
    stacks = now
    UpdateAllButtons()
end

function ns.SetMerchantOpen(open)
    if open then
        ns.RefreshLocks()
        merchantOpen = true
        UpdateAllButtons()
        return
    end
    merchantOpen = false
    UpdateAllButtons()
    for _, entry in ipairs(returning) do
        logger:Say(("Couldn't re-lock %s x%d — check your bags and the buyback tab."):format(entry.link or "item", entry.count))
    end
    wipe(returning)
    wipe(sold) -- locked stacks that left without a matching sale (used, merged, deleted)
end

function ns.ToggleHoveredLock()
    if not ns.IsEnabled() then
        logger:Say("disabled for this character.")
        return
    end
    local guid = hoveredBag and GUIDAt(hoveredBag, hoveredSlot)
    if not guid then
        logger:Say("Hover over an item in your bags first.")
        return
    end
    local locks = Locks()
    locks[guid] = not locks[guid] or nil
    local link = C_Container.GetContainerItemLink(hoveredBag, hoveredSlot) or "item"
    logger:Say((locks[guid] and "Locked " or "Unlocked ") .. link)
    UpdateAllButtons()
end

-- Both the default bags and BetterBags show a bag item's tooltip through SetBagItem.
hooksecurefunc(GameTooltip, "SetBagItem", function(_, bag, slot)
    hoveredBag, hoveredSlot = bag, slot
end)
GameTooltip:HookScript("OnHide", function()
    hoveredBag, hoveredSlot = nil, nil
end)

local function HookDefaultBags()
    local frames = { _G.ContainerFrameCombinedBags }
    for i = 1, NUM_CONTAINER_FRAMES or 13 do frames[#frames + 1] = _G["ContainerFrame" .. i] end
    for _, frame in ipairs(frames) do
        if frame and frame.UpdateItems and frame.EnumerateValidItems then
            hooksecurefunc(frame, "UpdateItems", function(self)
                for _, button in self:EnumerateValidItems() do
                    if not buttons[button] then
                        buttons[button] = function() return button:GetBagID(), button:GetID() end
                    end
                    UpdateButton(button)
                end
            end)
        end
    end
end

-- BetterBags draws each item on a "decoration" button and announces every redraw.
local function HookBetterBags()
    local AceAddon = LibStub and LibStub("AceAddon-3.0", true)
    local bb = AceAddon and AceAddon:GetAddon("BetterBags", true)
    local events = bb and bb:GetModule("Events", true)
    if not events then return end
    events:RegisterMessage("item/Updated", function(_, item, decoration)
        if not (item and decoration and item.GetItemData) then return end
        clickFrames[decoration] = item.button
        buttons[decoration] = function()
            local data = item:GetItemData()
            return data and data.bagid, data and data.slotid
        end
        UpdateButton(decoration)
    end)
    events:RegisterMessage("item/Clearing", function(_, _, decoration)
        buttons[decoration] = nil
        if icons[decoration] then icons[decoration]:Hide() end
        if blockers[decoration] then blockers[decoration]:Hide() end
    end)
end

function ns.HookBagButtons()
    HookDefaultBags()
    HookBetterBags()
end
