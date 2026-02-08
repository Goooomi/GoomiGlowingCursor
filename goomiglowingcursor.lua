-- goomiglowingcursor.lua - Cursor glow overlay module for GoomiUI

-- Wait for GoomiUI to be available
if not GoomiUI then
    print("Error: GoomiGlowingCursor requires GoomiUI to be installed!")
    return
end

local GlowingCursor = {
    name = "Glowing Cursor",
    version = "1.0",
}

-- Module's own SavedVariables
GoomiGlowingCursorDB = GoomiGlowingCursorDB or {}

local defaults = {
    enabled = true,
    size = 29,
    offsetX = 12,
    offsetY = -11,
    colorOverride = false,
    r = 1, g = 1, b = 1,
    a = 1,
    atlas = "Cursor_cast_32",
}

local function Clamp(n, lo, hi)
    if n < lo then return lo end
    if n > hi then return hi end
    return n
end

-- Initialize module settings
local function InitDB()
    local db = GoomiGlowingCursorDB
    for k, v in pairs(defaults) do
        if db[k] == nil then db[k] = v end
    end
    
    -- Sanitize values
    db.size = Clamp(tonumber(db.size) or defaults.size, 12, 128)
    db.r = Clamp(tonumber(db.r) or defaults.r, 0, 1)
    db.g = Clamp(tonumber(db.g) or defaults.g, 0, 1)
    db.b = Clamp(tonumber(db.b) or defaults.b, 0, 1)
    db.a = Clamp(tonumber(db.a) or defaults.a, 0, 1)
end

-- ======================
-- Cursor Glow Frame
-- ======================
local glow = CreateFrame("Frame", "GoomiGlowingCursorFrame", UIParent)
glow:SetFrameStrata("TOOLTIP")
glow:SetFrameLevel(9999)

local glowTex = glow:CreateTexture(nil, "OVERLAY")
glowTex:SetAllPoints(true)
glowTex:SetBlendMode("BLEND")

local parentScale = UIParent:GetEffectiveScale()
local function RefreshScale()
    parentScale = UIParent:GetEffectiveScale()
end

local function GlowOnUpdate()
    local db = GoomiGlowingCursorDB
    if not db.enabled then return end

    local scale = UIParent:GetEffectiveScale()
    local x, y = GetCursorPosition()
    x, y = x / scale, y / scale

    local left, bottom = UIParent:GetLeft(), UIParent:GetBottom()
    if left and bottom then
        x = x - left
        y = y - bottom
    end

    glow:ClearAllPoints()
    glow:SetPoint("CENTER", UIParent, "BOTTOMLEFT",
        x + (db.offsetX or 0),
        y + (db.offsetY or 0)
    )
end

local function SetGlowUpdating(isUpdating)
    if isUpdating then
        glow:SetScript("OnUpdate", GlowOnUpdate)
    else
        glow:SetScript("OnUpdate", nil)
    end
end

-- ======================
-- Apply Visual Settings
-- ======================
local function ApplyVisuals(previewTex, colorSwatchTex)
    local db = GoomiGlowingCursorDB
    
    local size = Clamp(tonumber(db.size) or defaults.size, 12, 128)
    glow:SetSize(size, size)
    
    if glowTex.SetAtlas then
        pcall(function()
            glowTex:SetAtlas(db.atlas, true)
        end)
    end
    
    if db.colorOverride then
        if glowTex.SetDesaturated then glowTex:SetDesaturated(true) end
        glowTex:SetVertexColor(db.r, db.g, db.b, 1)
        glowTex:SetAlpha(db.a)
    else
        if glowTex.SetDesaturated then glowTex:SetDesaturated(false) end
        glowTex:SetVertexColor(1, 1, 1, 1)
        glowTex:SetAlpha(1)
    end
    
    glow:SetShown(db.enabled)
    SetGlowUpdating(db.enabled)
    
    -- Update preview if provided
    if previewTex then
        if previewTex.SetAtlas then
            pcall(function()
                previewTex:SetAtlas(db.atlas, true)
            end)
        end
        
        if db.colorOverride then
            if previewTex.SetDesaturated then previewTex:SetDesaturated(true) end
            previewTex:SetVertexColor(db.r, db.g, db.b, 1)
            previewTex:SetAlpha(db.a)
        else
            if previewTex.SetDesaturated then previewTex:SetDesaturated(false) end
            previewTex:SetVertexColor(1, 1, 1, 1)
            previewTex:SetAlpha(1)
        end
    end
    
    -- Update color swatch
    if colorSwatchTex then
        colorSwatchTex:SetColorTexture(db.r, db.g, db.b, 1)
    end
end

-- ======================
-- Module Lifecycle
-- ======================
function GlowingCursor:OnLoad()
    InitDB()
    
    -- Handle scale changes and apply visuals after world loads
    local scaleFrame = CreateFrame("Frame")
    scaleFrame:RegisterEvent("UI_SCALE_CHANGED")
    scaleFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    scaleFrame:SetScript("OnEvent", function(self, event)
        if event == "UI_SCALE_CHANGED" then
            RefreshScale()
        elseif event == "PLAYER_ENTERING_WORLD" then
            -- Apply visuals after world is fully loaded to ensure atlas and colors work properly
            ApplyVisuals()
            self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        end
    end)
    
    RefreshScale()
    ApplyVisuals()
end

function GlowingCursor:OnEnable()
    InitDB()
    ApplyVisuals()
end

function GlowingCursor:OnDisable()
    glow:Hide()
    SetGlowUpdating(false)
end

-- ======================
-- Settings UI
-- ======================
function GlowingCursor:CreateSettings(parentFrame)
    local db = GoomiGlowingCursorDB
    
    -- Title
    local title = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", 0, 0)
    title:SetText("GLOWING CURSOR")
    title:SetTextColor(1, 1, 1, 1)
    
    -- Description
    local desc = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    desc:SetPoint("TOPLEFT", 0, -35)
    desc:SetWidth(550)
    desc:SetJustifyH("LEFT")
    desc:SetText("Add a customizable glow effect that follows your mouse cursor.")
    desc:SetTextColor(0.7, 0.7, 0.7, 1)
    
    local yOffset = 75
    
    -- Border helper function
    local function CreateBorder(parent, thickness, r, g, b, a)
        thickness = thickness or 1
        r, g, b, a = r or 0, g or 0, b or 0, a or 1
        
        local top = parent:CreateTexture(nil, "OVERLAY")
        top:SetColorTexture(r, g, b, a)
        top:SetHeight(thickness)
        top:SetPoint("TOPLEFT")
        top:SetPoint("TOPRIGHT")
        
        local bottom = parent:CreateTexture(nil, "OVERLAY")
        bottom:SetColorTexture(r, g, b, a)
        bottom:SetHeight(thickness)
        bottom:SetPoint("BOTTOMLEFT")
        bottom:SetPoint("BOTTOMRIGHT")
        
        local left = parent:CreateTexture(nil, "OVERLAY")
        left:SetColorTexture(r, g, b, a)
        left:SetWidth(thickness)
        left:SetPoint("TOPLEFT")
        left:SetPoint("BOTTOMLEFT")
        
        local right = parent:CreateTexture(nil, "OVERLAY")
        right:SetColorTexture(r, g, b, a)
        right:SetWidth(thickness)
        right:SetPoint("TOPRIGHT")
        right:SetPoint("BOTTOMRIGHT")
    end
    
    -- Size Control
    local sizeContainer = CreateFrame("Frame", nil, parentFrame)
    sizeContainer:SetSize(600, 40)
    sizeContainer:SetPoint("TOPLEFT", 0, -yOffset)
    
    sizeContainer.bg = sizeContainer:CreateTexture(nil, "BACKGROUND")
    sizeContainer.bg:SetAllPoints()
    sizeContainer.bg:SetColorTexture(0.1, 0.1, 0.1, 0.5)
    CreateBorder(sizeContainer, 1, 0.2, 0.2, 0.2, 0.5)
    
    local sizeLabel = sizeContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sizeLabel:SetPoint("LEFT", 10, 0)
    sizeLabel:SetText("Size:")
    sizeLabel:SetTextColor(1, 1, 1, 1)
    
    local minus = CreateFrame("Button", nil, sizeContainer, "UIPanelButtonTemplate")
    minus:SetSize(30, 24)
    minus:SetPoint("LEFT", sizeLabel, "RIGHT", 10, 0)
    minus:SetText("-")
    
    local sizeBox = CreateFrame("EditBox", nil, sizeContainer, "InputBoxTemplate")
    sizeBox:SetSize(50, 24)
    sizeBox:SetPoint("LEFT", minus, "RIGHT", 5, 0)
    sizeBox:SetNumeric(true)
    sizeBox:SetAutoFocus(false)
    sizeBox:SetJustifyH("CENTER")
    sizeBox:SetText(tostring(db.size))
    
    local plus = CreateFrame("Button", nil, sizeContainer, "UIPanelButtonTemplate")
    plus:SetSize(30, 24)
    plus:SetPoint("LEFT", sizeBox, "RIGHT", 5, 0)
    plus:SetText("+")
    
    local function SetSize(v)
        v = Clamp(tonumber(v) or defaults.size, 12, 128)
        db.size = v
        sizeBox:SetText(tostring(v))
        ApplyVisuals()
    end
    
    minus:SetScript("OnClick", function() SetSize(db.size - 1) end)
    plus:SetScript("OnClick", function() SetSize(db.size + 1) end)
    
    -- Store original value when focused
    local originalValue
    sizeBox:SetScript("OnEditFocusGained", function(self)
        originalValue = db.size
    end)
    
    sizeBox:SetScript("OnEnterPressed", function(self) 
        SetSize(self:GetText())
        self:ClearFocus()
    end)
    
    sizeBox:SetScript("OnEditFocusLost", function(self)
        -- Only update if we're not hitting escape
        if not self.escapingFocus then
            SetSize(self:GetText())
        end
        self.escapingFocus = nil
    end)
    
    sizeBox:SetScript("OnEscapePressed", function(self)
        self.escapingFocus = true
        db.size = originalValue
        self:SetText(tostring(originalValue))
        self:ClearFocus()
        ApplyVisuals()
    end)
    
    yOffset = yOffset + 60
    
    -- Section Header - Color
    local colorHeader = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    colorHeader:SetPoint("TOPLEFT", 0, -yOffset)
    colorHeader:SetText("Color Customization")
    colorHeader:SetTextColor(1, 1, 1, 1)
    
    yOffset = yOffset + 30
    
    local colorNote = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    colorNote:SetPoint("TOPLEFT", 0, -yOffset)
    colorNote:SetWidth(500)
    colorNote:SetJustifyH("LEFT")
    colorNote:SetText("Note: Color override desaturates the cursor texture to allow custom coloring.")
    colorNote:SetTextColor(0.7, 0.7, 0.7, 1)
    
    yOffset = yOffset + 40
    
    -- Enable Color Override
    local colorContainer = CreateFrame("Frame", nil, parentFrame)
    colorContainer:SetSize(600, 40)
    colorContainer:SetPoint("TOPLEFT", 0, -yOffset)
    
    colorContainer.bg = colorContainer:CreateTexture(nil, "BACKGROUND")
    colorContainer.bg:SetAllPoints()
    colorContainer.bg:SetColorTexture(0.1, 0.1, 0.1, 0.5)
    CreateBorder(colorContainer, 1, 0.2, 0.2, 0.2, 0.5)
    
    local colorCB = CreateFrame("CheckButton", nil, colorContainer, "UICheckButtonTemplate")
    colorCB:SetPoint("LEFT", 10, 0)
    colorCB:SetSize(24, 24)
    colorCB:SetChecked(db.colorOverride)
    
    colorCB.text:SetText("Enable Color Override")
    colorCB.text:SetPoint("LEFT", colorCB, "RIGHT", 5, 0)
    colorCB.text:SetTextColor(1, 1, 1, 1)
    colorCB.text:SetFontObject("GameFontNormal")
    
    -- Preview and color swatch (declared here so colorCB can reference them)
    local previewTex, colorSwatchTex
    
    colorCB:SetScript("OnClick", function(self)
        db.colorOverride = self:GetChecked() and true or false
        ApplyVisuals(previewTex, colorSwatchTex)
    end)
    
    yOffset = yOffset + 60
    
    -- Color Picker Row
    local colorPickerContainer = CreateFrame("Frame", nil, parentFrame)
    colorPickerContainer:SetSize(600, 60)
    colorPickerContainer:SetPoint("TOPLEFT", 0, -yOffset)
    
    colorPickerContainer.bg = colorPickerContainer:CreateTexture(nil, "BACKGROUND")
    colorPickerContainer.bg:SetAllPoints()
    colorPickerContainer.bg:SetColorTexture(0.1, 0.1, 0.1, 0.5)
    CreateBorder(colorPickerContainer, 1, 0.2, 0.2, 0.2, 0.5)
    
    local colorBtn = CreateFrame("Button", nil, colorPickerContainer, "UIPanelButtonTemplate")
    colorBtn:SetSize(120, 30)
    colorBtn:SetPoint("LEFT", 10, 0)
    colorBtn:SetText("Choose Color")
    
    -- Color Swatch
    local colorSwatch = CreateFrame("Frame", nil, colorPickerContainer, "BackdropTemplate")
    colorSwatch:SetSize(30, 30)
    colorSwatch:SetPoint("LEFT", colorBtn, "RIGHT", 10, 0)
    colorSwatch:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    colorSwatch:SetBackdropColor(0, 0, 0, 1)
    colorSwatch:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    
    colorSwatchTex = colorSwatch:CreateTexture(nil, "OVERLAY")
    colorSwatchTex:SetAllPoints(true)
    colorSwatchTex:SetColorTexture(db.r, db.g, db.b, 1)
    
    -- Preview Label
    local previewLabel = colorPickerContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    previewLabel:SetPoint("LEFT", colorSwatch, "RIGHT", 20, 0)
    previewLabel:SetText("Preview:")
    previewLabel:SetTextColor(1, 1, 1, 1)
    
    -- Preview Frame
    local preview = CreateFrame("Frame", nil, colorPickerContainer)
    preview:SetSize(48, 48)
    preview:SetPoint("LEFT", previewLabel, "RIGHT", 10, 0)
    
    local previewBg = preview:CreateTexture(nil, "BACKGROUND")
    previewBg:SetAllPoints()
    previewBg:SetColorTexture(0, 0, 0, 0.5)
    
    -- Border for preview
    local previewBorder = preview:CreateTexture(nil, "OVERLAY")
    previewBorder:SetColorTexture(0.3, 0.3, 0.3, 1)
    previewBorder:SetDrawLayer("OVERLAY", 1)
    
    local function CreatePreviewBorder()
        local t = preview:CreateTexture(nil, "OVERLAY")
        t:SetColorTexture(0.3, 0.3, 0.3, 1)
        t:SetHeight(1)
        t:SetPoint("TOPLEFT")
        t:SetPoint("TOPRIGHT")
        
        local b = preview:CreateTexture(nil, "OVERLAY")
        b:SetColorTexture(0.3, 0.3, 0.3, 1)
        b:SetHeight(1)
        b:SetPoint("BOTTOMLEFT")
        b:SetPoint("BOTTOMRIGHT")
        
        local l = preview:CreateTexture(nil, "OVERLAY")
        l:SetColorTexture(0.3, 0.3, 0.3, 1)
        l:SetWidth(1)
        l:SetPoint("TOPLEFT")
        l:SetPoint("BOTTOMLEFT")
        
        local r = preview:CreateTexture(nil, "OVERLAY")
        r:SetColorTexture(0.3, 0.3, 0.3, 1)
        r:SetWidth(1)
        r:SetPoint("TOPRIGHT")
        r:SetPoint("BOTTOMRIGHT")
    end
    CreatePreviewBorder()
    
    previewTex = preview:CreateTexture(nil, "ARTWORK")
    previewTex:SetSize(48, 48)
    previewTex:SetPoint("CENTER")
    previewTex:SetBlendMode("BLEND")
    
    -- Initialize preview
    ApplyVisuals(previewTex, colorSwatchTex)
    
    -- Color Picker Button
    colorBtn:SetScript("OnClick", function()
        local prevR, prevG, prevB, prevA = db.r, db.g, db.b, db.a
        
        local function ApplyFromPicker()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            local a = ColorPickerFrame:GetColorAlpha()
            
            db.r = Clamp(r or 1, 0, 1)
            db.g = Clamp(g or 1, 0, 1)
            db.b = Clamp(b or 1, 0, 1)
            db.a = Clamp(a or 1, 0, 1)
            
            ApplyVisuals(previewTex, colorSwatchTex)
        end
        
        ColorPickerFrame:SetupColorPickerAndShow({
            r = prevR, g = prevG, b = prevB,
            hasOpacity = true,
            opacity = prevA,
            swatchFunc = ApplyFromPicker,
            opacityFunc = ApplyFromPicker,
            cancelFunc = function()
                db.r, db.g, db.b, db.a = prevR, prevG, prevB, prevA
                ApplyVisuals(previewTex, colorSwatchTex)
            end,
        })
    end)
    
    yOffset = yOffset + 80
    
    -- Reset Button (bottom-right)
    local resetBtn = CreateFrame("Button", nil, parentFrame, "UIPanelButtonTemplate")
    resetBtn:SetSize(120, 30)
    resetBtn:SetPoint("BOTTOMRIGHT", parentFrame:GetParent(), "BOTTOMRIGHT", -20, 20)
    resetBtn:SetText("Reset to Default")
    
    resetBtn:SetScript("OnClick", function()
        for k, v in pairs(defaults) do
            db[k] = v
        end
        
        sizeBox:SetText(tostring(db.size))
        colorCB:SetChecked(db.colorOverride)
        
        ApplyVisuals(previewTex, colorSwatchTex)
    end)
end

-- Register this module with Goomi UI
GoomiUI:RegisterModule("Glowing Cursor", GlowingCursor)
