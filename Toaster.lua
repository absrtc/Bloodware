--!strict
local Toaster = {}
Toaster.__index = Toaster

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local function hexToColor3(hex)
    hex = hex:gsub("#", "")
    return Color3.fromRGB(tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6)))
end

local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false
screenGui.Name = "Toaster"
screenGui.Parent = CoreGui
screenGui.IgnoreGuiInset = true

local DefaultOptions = {
    Duration = 3,
    BackgroundColor = "2B2B2B",
    TextColor = "E5E7EB",
    AccentColor = "A855F7",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    Width = 300,
    Height = 60,
    Position = UDim2.new(1, -310, 1, -70),
    ShowIcon = false,
    Icon = "rbxassetid://7072706760",
    BorderThickness = 1,
    CornerRadius = 10,
    AnimationStyle = Enum.EasingStyle.Quad,
    AnimationDuration = 0.4,
    Buttons = {},
    MaxToasts = 5, 
    ToastSpacing = 10
}

local activeToasts = 0
local toastQueue = {}

local function createToast(message, options)
    if activeToasts >= DefaultOptions.MaxToasts then
        table.insert(toastQueue, {message, options})
        return
    end

    activeToasts = activeToasts + 1

    options = options or {}
    for k, v in pairs(DefaultOptions) do
        if options[k] == nil then
            options[k] = v
        end
    end

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, options.Width, 0, options.Height)
    frame.Position = UDim2.new(1, -options.Width - 10, 1, -options.Height - 10 - (activeToasts - 1) * (options.Height + options.ToastSpacing))
    frame.BackgroundColor3 = hexToColor3(options.BackgroundColor)
    frame.BackgroundTransparency = 0.1
    frame.Parent = screenGui
    frame.ClipsDescendants = true
    frame.ZIndex = 10 + activeToasts

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, options.CornerRadius)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = hexToColor3(options.AccentColor)
    stroke.Thickness = options.BorderThickness
    stroke.Transparency = 0.8

    local shadow = Instance.new("Frame", {
        Parent = frame,
        Size = UDim2.new(1, 10, 1, 10),
        Position = UDim2.new(0, -5, 0, -5),
        BackgroundTransparency = 1,
        ZIndex = frame.ZIndex - 1
    })
    Instance.new("ImageLabel", {
        Parent = shadow,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Image = "rbxassetid://1316045217",
        ImageColor3 = hexToColor3(options.BackgroundColor),
        ImageTransparency = 0.8,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(Vector2.new(10, 10), Vector2.new(10, 10))
    })

    local labelOffset = options.ShowIcon and 40 or 10
    local labelWidth = options.Width - labelOffset - 10
    if #options.Buttons > 0 then
        labelWidth = labelWidth - (#options.Buttons * 80)
    end

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, labelWidth, 1, 0)
    label.Position = UDim2.new(0, labelOffset, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = message
    label.TextColor3 = hexToColor3(options.TextColor)
    label.Font = options.Font
    label.TextSize = options.TextSize
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextWrapped = true
    label.Parent = frame

    if options.ShowIcon then
        local icon = Instance.new("ImageLabel")
        icon.Size = UDim2.new(0, 24, 0, 24)
        icon.Position = UDim2.new(0, 10, 0.5, -12)
        icon.BackgroundTransparency = 1
        icon.Image = options.Icon
        icon.Parent = frame
    end

    for i, button in ipairs(options.Buttons) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 70, 0, 30)
        btn.Position = UDim2.new(1, -80 * (#options.Buttons - i + 1) - 10, 0.5, -15)
        btn.BackgroundColor3 = hexToColor3(options.AccentColor)
        btn.Text = button.Text
        btn.TextColor3 = hexToColor3(options.TextColor)
        btn.Font = options.Font
        btn.TextSize = 14
        btn.BorderSizePixel = 0
        btn.Parent = frame
        Instance.new("UICorner", {Parent = btn, CornerRadius = UDim.new(0, 6)})
        Instance.new("UIStroke", {Parent = btn, Color = hexToColor3(options.BackgroundColor), Thickness = 1})

        btn.MouseButton1Click:Connect(function()
            pcall(button.Callback)
            local tween = TweenService:Create(frame, TweenInfo.new(options.AnimationDuration, options.AnimationStyle, Enum.EasingDirection.In), {
                Position = UDim2.new(1, options.Width + 10, frame.Position.Y)
            })
            tween:Play()
            tween.Completed:Connect(function()
                frame:Destroy()
                activeToasts = activeToasts - 1
                if #toastQueue > 0 then
                    local nextToast = table.remove(toastQueue, 1)
                    createToast(nextToast[1], nextToast[2])
                end
            end)
        end)
    end

    TweenService:Create(frame, TweenInfo.new(options.AnimationDuration, options.AnimationStyle, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -options.Width - 10, frame.Position.Y)
    }):Play()

    task.delay(options.Duration, function()
        local tween = TweenService:Create(frame, TweenInfo.new(options.AnimationDuration, options.AnimationStyle, Enum.EasingDirection.In), {
            Position = UDim2.new(1, options.Width + 10, frame.Position.Y)
        })
        tween:Play()
        tween.Completed:Connect(function()
            frame:Destroy()
            activeToasts = activeToasts - 1
            if #toastQueue > 0 then
                local nextToast = table.remove(toastQueue, 1)
                createToast(nextToast[1], nextToast[2])
            end
        end)
    end)
end

function Toaster.Notify(message, options)
    createToast(message, options)
end

return Toaster
