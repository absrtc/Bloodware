--!strict
local Bloodware = {}
Bloodware.__index = Bloodware

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local function new(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        if type(k) ~= "number" then
            pcall(function() 
                obj[k] = v 
            end)
        end
    end
    return obj
end

local function hexToColor3(hex)
    if not hex or type(hex) ~= "string" then
        return Color3.fromRGB(255, 255, 255)
    end
    hex = hex:gsub("#", "")
    if #hex ~= 6 then
        return Color3.fromRGB(255, 255, 255)
    end
    local r = tonumber("0x"..hex:sub(1,2))
    local g = tonumber("0x"..hex:sub(3,4))
    local b = tonumber("0x"..hex:sub(5,6))
    if not r or not g or not b then
        return Color3.fromRGB(255, 255, 255)
    end
    return Color3.fromRGB(r, g, b)
end

local DefaultThemes = {
    Amethyst = {
        Background = "#0F0F23",
        Sidebar = "#1A1A2E",
        Accent = "#8B5CF6",
        AccentHover = "#A855F7",
        Text = "#F1F5F9",
        TextSecondary = "#94A3B8",
        Border = "#374151",
        Success = "#10B981",
        Warning = "#F59E0B",
        Error = "#EF4444",
        Font = Enum.Font.Inter,
        Shadow = "#000000"
    },
    Dark = {
        Background = "#111827",
        Sidebar = "#1F2937",
        Accent = "#3B82F6",
        AccentHover = "#2563EB",
        Text = "#F9FAFB",
        TextSecondary = "#9CA3AF",
        Border = "#374151",
        Success = "#059669",
        Warning = "#D97706",
        Error = "#DC2626",
        Font = Enum.Font.Inter,
        Shadow = "#000000"
    }
}

local Keybinds = {}
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local kc = input.KeyCode
        local handlers = Keybinds[kc]
        if handlers then
            for _, fn in ipairs(handlers) do
                pcall(fn)
            end
        end
    end
end)

function Bloodware.CreateWindow(options)
    options = options or {}
    local windowName = options.Name or "Bloodware"
    local toggleKey = options.ToggleKey or Enum.KeyCode.RightShift
    local theme = options.Theme or DefaultThemes.Amethyst
    local size = options.Size or {800, 520}

    local self = setmetatable({}, Bloodware)
    self.Tabs = {}
    self.Theme = theme

    local screenGui = new("ScreenGui", {
        Name = windowName .. "_UI",
        Parent = CoreGui,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true
    })
    self.ScreenGui = screenGui

    local backdrop = new("Frame", {
        Name = "Backdrop",
        Parent = screenGui,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.3,
        Visible = true
    })

    local main = new("Frame", {
        Name = "MainFrame",
        Parent = backdrop,
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = hexToColor3(theme.Background),
        ClipsDescendants = true,
        ZIndex = 2
    })
    
    local mainCorner = new("UICorner", {
        Parent = main, 
        CornerRadius = UDim.new(0, 20)
    })
    
    local mainStroke = new("UIStroke", {
        Parent = main, 
        Color = hexToColor3(theme.Border), 
        Thickness = 1, 
        Transparency = 0.5
    })

    local shadowContainer = new("Frame", {
        Parent = main,
        Size = UDim2.new(1, 40, 1, 40),
        Position = UDim2.new(0, -20, 0, -20),
        BackgroundTransparency = 1,
        ZIndex = 1
    })

    for i = 1, 3 do
        local shadow = new("ImageLabel", {
            Parent = shadowContainer,
            Size = UDim2.new(1, i * 10, 1, i * 10),
            Position = UDim2.new(0, -i * 5, 0, -i * 5),
            BackgroundTransparency = 1,
            Image = "rbxassetid://1316045217",
            ImageColor3 = hexToColor3(theme.Shadow),
            ImageTransparency = 0.7 + (i * 0.1),
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(10, 10, 118, 118),
            ZIndex = 1 - i
        })
    end

    local header = new("Frame", {
        Name = "Header",
        Parent = main,
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundTransparency = 1,
        ZIndex = 3
    })

    local headerGradient = new("Frame", {
        Parent = header,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = hexToColor3(theme.Accent),
        BackgroundTransparency = 0.9,
        ZIndex = 3
    })
    
    new("UICorner", {
        Parent = headerGradient, 
        CornerRadius = UDim.new(0, 20)
    })
    
    local gradientUI = new("UIGradient", {
        Parent = headerGradient,
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, hexToColor3(theme.Accent)),
            ColorSequenceKeypoint.new(1, hexToColor3(theme.AccentHover))
        },
        Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.85),
            NumberSequenceKeypoint.new(1, 0.95)
        },
        Rotation = 45
    })

    local rotationConnection
    rotationConnection = RunService.Heartbeat:Connect(function()
        if gradientUI and gradientUI.Parent then
            gradientUI.Rotation = (gradientUI.Rotation + 0.5) % 360
        else
            rotationConnection:Disconnect()
        end
    end)

    local title = new("TextLabel", {
        Name = "Title",
        Parent = header,
        Size = UDim2.new(1, -120, 1, 0),
        Position = UDim2.new(0, 24, 0, 0),
        Text = windowName,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Font = theme.Font,
        TextSize = 24,
        BackgroundTransparency = 1,
        TextColor3 = hexToColor3(theme.Text),
        ZIndex = 4
    })

    local controlsFrame = new("Frame", {
        Name = "Controls",
        Parent = header,
        Size = UDim2.new(0, 100, 0, 36),
        Position = UDim2.new(1, -120, 0.5, -18),
        BackgroundTransparency = 1,
        ZIndex = 4
    })

    local controlsLayout = new("UIListLayout", {
        Parent = controlsFrame,
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    local btnMinimize = new("TextButton", {
        Name = "Minimize",
        Parent = controlsFrame,
        Size = UDim2.new(0, 36, 0, 36),
        Text = "−",
        BackgroundColor3 = hexToColor3(theme.Sidebar),
        BorderSizePixel = 0,
        TextColor3 = hexToColor3(theme.Text),
        Font = theme.Font,
        TextSize = 20,
        ZIndex = 4,
        LayoutOrder = 1
    })
    new("UICorner", {Parent = btnMinimize, CornerRadius = UDim.new(0, 8)})
    new("UIStroke", {Parent = btnMinimize, Color = hexToColor3(theme.Border), Thickness = 1, Transparency = 0.7})

    local btnClose = new("TextButton", {
        Name = "Close",
        Parent = controlsFrame,
        Size = UDim2.new(0, 36, 0, 36),
        Text = "×",
        BackgroundColor3 = hexToColor3(theme.Error),
        BorderSizePixel = 0,
        TextColor3 = Color3.new(1, 1, 1),
        Font = theme.Font,
        TextSize = 22,
        ZIndex = 4,
        LayoutOrder = 2
    })
    new("UICorner", {Parent = btnClose, CornerRadius = UDim.new(0, 8)})

    local function addButtonHover(button, hoverColor, originalColor)
        button.MouseEnter:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                BackgroundColor3 = hoverColor,
                Size = UDim2.new(0, 38, 0, 38)
            }):Play()
        end)
        
        button.MouseLeave:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                BackgroundColor3 = originalColor,
                Size = UDim2.new(0, 36, 0, 36)
            }):Play()
        end)
    end

    addButtonHover(btnMinimize, hexToColor3(theme.Border), hexToColor3(theme.Sidebar))
    addButtonHover(btnClose, Color3.fromRGB(220, 38, 38), hexToColor3(theme.Error))

    btnClose.MouseButton1Click:Connect(function()
        local closeTween = TweenService:Create(main, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            Rotation = 180
        })
        local backdropTween = TweenService:Create(backdrop, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            BackgroundTransparency = 1
        })
        
        closeTween:Play()
        backdropTween:Play()
        
        closeTween.Completed:Connect(function()
            screenGui:Destroy()
            if rotationConnection then
                rotationConnection:Disconnect()
            end
        end)
    end)

    local minimized = false
    btnMinimize.MouseButton1Click:Connect(function()
        minimized = not minimized
        local targetSize = minimized and UDim2.new(0, size[1], 0, 60) or UDim2.new(0, size[1], 0, size[2])
        
        TweenService:Create(main, TweenInfo.new(0.4, Enum.EasingStyle.Expo, Enum.EasingDirection.Out), {
            Size = targetSize
        }):Play()
