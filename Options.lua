-- SellLock options panel (Settings > AddOns > SellLock).
local _, ns = ...

local panel, category, enabledBox

function ns.SyncOptions()
    if not panel then return end
    enabledBox:SetChecked(ns.IsEnabled())
end

function ns.CreateOptions()
    if panel or not Settings or not Settings.RegisterCanvasLayoutCategory then return end

    panel = CreateFrame("Frame", nil, UIParent)
    panel:Hide()

    local header = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", 16, -16)
    header:SetText("SellLock")

    local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -6)
    sub:SetText("Locks items so they can't be sold by accident.")

    enabledBox = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    enabledBox:SetSize(28, 28)
    enabledBox:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", -4, -16)
    local cbLabel = enabledBox:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    cbLabel:SetPoint("LEFT", enabledBox, "RIGHT", 4, 0)
    cbLabel:SetText("Enabled (this character)")
    enabledBox:SetScript("OnClick", function(self) ns.SetEnabled(self:GetChecked()) end)

    panel:SetScript("OnShow", ns.SyncOptions)

    category = Settings.RegisterCanvasLayoutCategory(panel, "SellLock")
    Settings.RegisterAddOnCategory(category)
end

function ns.OpenOptions()
    if category and Settings.OpenToCategory then
        Settings.OpenToCategory(category:GetID())
    else
        ns.logger:Say("Options panel unavailable; use /slock toggle.")
    end
end
