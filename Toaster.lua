--!strict
local Toaster = {}
Toaster.__index = Toaster

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false
screenGui.Name = "Toaster"
screenGui.Parent = CoreGui

local DefaultOptions = {
    Duration = 3,
    BackgroundColor = "2B2B2B",
    TextColor = "E5E7EB",
    AccentColor = "A855F7",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    Width = 300,
    Height = 50,
    Position = UDim2.new(1, 310, 1, -60),
    ShowIcon = false,
    Icon = "rbxassetid://7072706760"
}

local function createToast(message, options)
    options = options or {}
    for k, v in pairs(DefaultOptions) do
        if options[k] == nil then
            options[k] = v
        end
    end

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, options.Width, 0, options.Height)
    frame.Position = options.Position
    frame.BackgroundColor3 = hexToColor3(options.BackgroundColor)
    frame.BackgroundTransparency = 0.1
    frame.Parent = screenGui
    frame.ClipsDescendants = true

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = hexToColor3(options.AccentColor)
    stroke.Thickness = 1
    stroke.Transparency = 0.8

    local shadow = Instance.new("Frame", {
        Parent = frame,
        Size = UDim2.new(1, 10, 1, 10),
        Position = UDim2.new(0, -5, 0, -5),
        BackgroundTransparency = 1,
        ZIndex = -1
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
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -labelOffset - 10, 1, 0)
    label.Position = UDim2.new(0, labelOffset, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = message
    label.TextColor3 = hexToColor3(options.TextColor)
    label.Font = options.Font
    label.TextSize = options.TextSize
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = frame

    if options.ShowIcon then
        local icon = Instance.new("ImageLabel")
        icon.Size = UDim2.new(0, 24, 0, 24)
        icon.Position = UDim2.new(0, 10, 0.5, -12)
        icon.BackgroundTransparency = 1
        icon.Image = options.Icon
        icon.Parent = frame
    end

    TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -options.Width - 10, 1, -options.Height - 10)
    }):Play()

    task.delay(options.Duration, function()
        local tween = TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = options.Position
        })
        tween:Play()
        tween.Completed:Connect(function()
            frame:Destroy()
        end)
    end)
end

function Toaster.Notify(message, options)
    createToast(message, options)
end

return Toaster
