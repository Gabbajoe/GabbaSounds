local addonName, addon = ...
local button, icon
local dragging = false
local ignoreClick = false

local function Tooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("GabbaSounds")
    GameTooltip:AddLine(addon.db.enabled and "Aktiv" or "Ausgeschaltet",
        addon.db.enabled and 0.35 or 1, addon.db.enabled and 1 or 0.45, 0.45)
    GameTooltip:AddLine("Linksklick: an / aus", 1, 1, 1)
    GameTooltip:AddLine("Rechtsklick: Optionen", 1, 1, 1)
    GameTooltip:AddLine("Ziehen: Symbol verschieben", 0.75, 0.75, 0.75)
    GameTooltip:Show()
end

local function Position()
    local angle = math.rad(addon.db.minimapAngle)
    local x, y = math.cos(angle), math.sin(angle)
    -- Adapt to minimap size and the usual round or square replacement maps.
    if type(GetMinimapShape) == "function" and GetMinimapShape() == "SQUARE" then
        local edge = math.max(math.abs(x), math.abs(y))
        x, y = x / edge, y / edge
    end
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER",
        x * (Minimap:GetWidth() / 2 + 10), y * (Minimap:GetHeight() / 2 + 10))
end

function addon.RefreshMinimap()
    if not button or not addon.db then return end
    icon:SetDesaturated(not addon.db.enabled)
    icon:SetAlpha(addon.db.enabled and 1 or 0.55)
    Position()
    if addon.db.minimapHidden then
        button:SetScript("OnUpdate", nil)
        dragging = false
        button:Hide()
        if GameTooltip:IsOwned(button) then GameTooltip:Hide() end
    else
        button:Show()
        if GameTooltip:IsOwned(button) then Tooltip(button) end
    end
end

function addon.InitializeMinimap()
    if button then addon.RefreshMinimap(); return end
    if not Minimap then return end
    button = CreateFrame("Button", "GabbaSoundsMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    button:EnableMouse(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\AddOns\\" .. addonName .. "\\Assets\\minimap.tga")
    icon:SetSize(22, 22)
    icon:SetPoint("CENTER", 0, 0)
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT", 0, 0)
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    button:SetScript("OnMouseDown", function() if not dragging then ignoreClick = false end end)
    button:SetScript("OnClick", function(self, mouseButton)
        if dragging or ignoreClick then ignoreClick = false; return end
        if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
        if mouseButton == "RightButton" then
            addon.OpenUI()
        elseif mouseButton == "LeftButton" then
            addon.SetOption("enabled", not addon.db.enabled)
            addon.Print(addon.db.enabled and "Aktiviert." or "Ausgeschaltet.")
        end
    end)
    button:SetScript("OnDragStart", function(self)
        dragging = true
        ignoreClick = true
        if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
        self:SetScript("OnUpdate", function()
            local centerX, centerY = Minimap:GetCenter()
            if not centerX or not centerY then return end
            local cursorX, cursorY = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            local x, y = cursorX / scale - centerX, cursorY / scale - centerY
            -- WoW Lua 5.1 provides atan2; newer test interpreters use atan(y,x).
            local atan = math.atan2 or math.atan
            addon.db.minimapAngle = math.deg(atan(y, x)) % 360
            Position()
        end)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        dragging = false
        if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
    end)
    button:SetScript("OnEnter", function(self) if not dragging then Tooltip(self) end end)
    button:SetScript("OnLeave", function(self) if GameTooltip:IsOwned(self) then GameTooltip:Hide() end end)
    if Minimap.HookScript then Minimap:HookScript("OnSizeChanged", Position) end
    addon.RefreshMinimap()
end
