--!strict
local Toaster = {}
Toaster.__index = Toaster

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local function hexToColor3(hex)
    if not hex or type(hex) ~= "string" then
        return Color3.fromRGB(255, 255, 255)
    end
    hex = hex:gsub("#", "")
    if #hex ~= 6 then
        return Color3.fromRGB(255, 255, 255)
    end
    local r = tonumber("0x" .. hex:sub(1, 2))
    local g = tonumber("0x" .. hex:sub(3, 4))
    local b = tonumber("0x" .. hex:sub(5, 6))
    if not r or not g or not b then
        return Color3.fromRGB(255, 255, 255)
    end
    return Color3.fromRGB(r, g, b)
end

local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false
screenGui.Name = "Toaster"
screenGui.Parent = CoreGui
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local DefaultOptions = {
    Duration = 4,
    BackgroundColor = "#1F2937",
    TextColor = "#F9FAFB",
    AccentColor = "#8B5CF6",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    Width = 320,
    Height = 68,
    Position = UDim2.new(1, -330, 1, -80),
    ShowIcon = true,
    Icon = "rbxassetid://7072706760",
    BorderThickness = 0,
    CornerRadius = 12,
    AnimationStyle = Enum.EasingStyle.Expo,
    AnimationDuration = 0.6,
    Buttons = {},
    MaxToasts = 6,
    ToastSpacing = 12
}

local activeToasts = 0
local toastQueue = {}
local toastInstances = {}

local function updateToastPositions()
    for i, toast in ipairs(toastInstances) do
        if toast and toast.Parent then
            local newY = -80 - ((i - 1) * (DefaultOptions.Height + DefaultOptions.ToastSpacing))
            local targetPosition = UDim2.new(1, -330, 1, newY)
            
            TweenService:Create(toast, TweenInfo.new(0.4, Enum.EasingStyle.Expo, Enum.EasingDirection.Out), {
                Position = targetPosition
            }):Play()
        end
    end
end

local function removeToast(frame)
    for i, toast in ipairs(toastInstances) do
        if toast == frame then
            table.remove(toastInstances, i)
            break
        end
    end
    activeToasts = math.max(0, activeToasts - 1)
    updateToastPositions()
    
    if #toastQueue > 0 then
        local nextToast = table.remove(toastQueue, 1)
        task.wait(0.1) 
        createToast(nextToast[1], nextToast[2])
    end
end

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

    if type(options.BackgroundColor) ~= "string" or #options.BackgroundColor:gsub("#", "") ~= 6 then
        options.BackgroundColor = DefaultOptions.BackgroundColor
    end
    if type(options.TextColor) ~= "string" or #options.TextColor:gsub("#", "") ~= 6 then
        options.TextColor = DefaultOptions.TextColor
    end
    if type(options.AccentColor) ~= "string" or #options.AccentColor:gsub("#", "") ~= 6 then
        options.AccentColor = DefaultOptions.AccentColor
    end

    local frame = Instance.new("Frame")
    frame.Name = "Toast"
    frame.Size = UDim2.new(0, options.Width, 0, options.Height)
    frame.Position = UDim2.new(1, 0, 1, -80 - (activeToasts - 1) * (options.Height + options.ToastSpacing))
    frame.BackgroundColor3 = hexToColor3(options.BackgroundColor)
    frame.BackgroundTransparency = 0.05
    frame.Parent = screenGui
    frame.ClipsDescendants = true
    frame.ZIndex = 10 + activeToasts

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, options.CornerRadius)
    corner.Parent = frame

    local gradient = Instance.new("Frame")
    gradient.Name = "Gradient"
    gradient.Size = UDim2.new(1, 0, 1, 0)
    gradient.BackgroundTransparency = 1
    gradient.Parent = frame
    
    local gradientCorner = Instance.new("UICorner")
    gradientCorner.CornerRadius = UDim.new(0, options.CornerRadius)
    gradientCorner.Parent = gradient
    
    local gradientUI = Instance.new("UIGradient")
    gradientUI.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
    }
    gradientUI.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.95),
        NumberSequenceKeypoint.new(1, 1)
    }
    gradientUI.Rotation = 45
    gradientUI.Parent = gradient

    if options.BorderThickness > 0 then
        local stroke = Instance.new("UIStroke")
        stroke.Color = hexToColor3(options.AccentColor)
        stroke.Thickness = options.BorderThickness
        stroke.Transparency = 0.6
        stroke.Parent = frame
    end

    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 16, 1, 16)
    shadow.Position = UDim2.new(0, -8, 0, -8)
    shadow.BackgroundTransparency = 1
    shadow.ZIndex = frame.ZIndex - 1
    shadow.Parent = frame

    local shadowImage = Instance.new("ImageLabel")
    shadowImage.Size = UDim2.new(1, 0, 1, 0)
    shadowImage.BackgroundTransparency = 1
    shadowImage.Image = "rbxassetid://1316045217"
    shadowImage.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadowImage.ImageTransparency = 0.85
    shadowImage.ScaleType = Enum.ScaleType.Slice
    shadowImage.SliceCenter = Rect.new(10, 10, 118, 118)
    shadowImage.Parent = shadow

    local progressBar = Instance.new("Frame")
    progressBar.Name = "ProgressBar"
    progressBar.Size = UDim2.new(1, 0, 0, 2)
    progressBar.Position = UDim2.new(0, 0, 1, -2)
    progressBar.BackgroundColor3 = hexToColor3(options.AccentColor)
    progressBar.BackgroundTransparency = 0.3
    progressBar.BorderSizePixel = 0
    progressBar.Parent = frame

    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0, 2)
    progressCorner.Parent = progressBar

    local labelOffset = options.ShowIcon and 52 or 16
    local labelWidth = options.Width - labelOffset - 16
    if #options.Buttons > 0 then
        labelWidth = labelWidth - (#options.Buttons * 84)
    end

    local label = Instance.new("TextLabel")
    label.Name = "MessageLabel"
    label.Size = UDim2.new(0, labelWidth, 1, -8)
    label.Position = UDim2.new(0, labelOffset, 0, 4)
    label.BackgroundTransparency = 1
    label.Text = message or "No message provided"
    label.TextColor3 = hexToColor3(options.TextColor)
    label.Font = options.Font
    label.TextSize = options.TextSize
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextWrapped = true
    label.RichText = true
    label.Parent = frame

    if options.ShowIcon then
        local iconFrame = Instance.new("Frame")
        iconFrame.Name = "IconFrame"
        iconFrame.Size = UDim2.new(0, 32, 0, 32)
        iconFrame.Position = UDim2.new(0, 12, 0.5, -16)
        iconFrame.BackgroundColor3 = hexToColor3(options.AccentColor)
        iconFrame.BackgroundTransparency = 0.9
        iconFrame.Parent = frame

        local iconCorner = Instance.new("UICorner")
        iconCorner.CornerRadius = UDim.new(0, 8)
        iconCorner.Parent = iconFrame

        local icon = Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.Size = UDim2.new(0, 20, 0, 20)
        icon.Position = UDim2.new(0.5, -10, 0.5, -10)
        icon.BackgroundTransparency = 1
        icon.Image = options.Icon
        icon.ImageColor3 = hexToColor3(options.AccentColor)
        icon.Parent = iconFrame

        TweenService:Create(iconFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 32, 0, 32)
        }):Play()
    end

    for i, button in ipairs(options.Buttons) do
        local btn = Instance.new("TextButton")
        btn.Name = "ToastButton" .. i
        btn.Size = UDim2.new(0, 76, 0, 32)
        btn.Position = UDim2.new(1, -84 * (#options.Buttons - i + 1) - 12, 0.5, -16)
        btn.BackgroundColor3 = hexToColor3(options.AccentColor)
        btn.BackgroundTransparency = 0.1
        btn.Text = button.Text or "Button"
        btn.TextColor3 = hexToColor3(options.TextColor)
        btn.Font = options.Font
        btn.TextSize = 14
        btn.BorderSizePixel = 0
        btn.Parent = frame

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = btn

        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = hexToColor3(options.AccentColor)
        btnStroke.Thickness = 1
        btnStroke.Transparency = 0.7
        btnStroke.Parent = btn

        -- Button hover effects
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                BackgroundTransparency = 0,
                Size = UDim2.new(0, 80, 0, 34)
            }):Play()
        end)

        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                BackgroundTransparency = 0.1,
                Size = UDim2.new(0, 76, 0, 32)
            }):Play()
        end)

        btn.MouseButton1Click:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
                Size = UDim2.new(0, 72, 0, 30)
            }):Play()
            
            task.wait(0.1)
            
            TweenService:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Back), {
                Size = UDim2.new(0, 76, 0, 32)
            }):Play()

            if button.Callback then
                pcall(button.Callback)
            end

            local slideOut = TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Expo, Enum.EasingDirection.In), {
                Position = UDim2.new(1, options.Width + 20, frame.Position.Y.Scale, frame.Position.Y.Offset),
                BackgroundTransparency = 1
            })
            slideOut:Play()
            slideOut.Completed:Connect(function()
                frame:Destroy()
                removeToast(frame)
            end)
        end)
    end

    table.insert(toastInstances, frame)

    local slideIn = TweenService:Create(frame, TweenInfo.new(options.AnimationDuration, options.AnimationStyle, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -options.Width - 10, frame.Position.Y.Scale, frame.Position.Y.Offset)
    })
    slideIn:Play()

    TweenService:Create(shadowImage, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {
        ImageTransparency = 0.85
    }):Play()

    TweenService:Create(progressBar, TweenInfo.new(options.Duration, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 0, 2)
    }):Play()

    task.delay(options.Duration, function()
        if frame and frame.Parent then
            local slideOut = TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Expo, Enum.EasingDirection.In), {
                Position = UDim2.new(1, options.Width + 20, frame.Position.Y.Scale, frame.Position.Y.Offset),
                BackgroundTransparency = 1
            })
            slideOut:Play()
            slideOut.Completed:Connect(function()
                if frame and frame.Parent then
                    frame:Destroy()
                    removeToast(frame)
                end
            end)
        end
    end)
end

function Toaster.Notify(message, options)
    createToast(message, options)
end

function Toaster.Success(message, options)
    options = options or {}
    options.AccentColor = options.AccentColor or "#10B981"
    options.Icon = options.Icon or "rbxassetid://7072706764"
    createToast(message, options)
end

function Toaster.Error(message, options)
    options = options or {}
    options.AccentColor = options.AccentColor or "#EF4444"
    options.Icon = options.Icon or "rbxassetid://7072706899"
    createToast(message, options)
end

function Toaster.Warning(message, options)
    options = options or {}
    options.AccentColor = options.AccentColor or "#F59E0B"
    options.Icon = options.Icon or "rbxassetid://7072706999"
    createToast(message, options)
end

function Toaster.Info(message, options)
    options = options or {}
    options.AccentColor = options.AccentColor or "#3B82F6"
    options.Icon = options.Icon or "rbxassetid://7072707037"
    createToast(message, options)
end

return Toaster
