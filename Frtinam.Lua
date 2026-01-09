-- ================== GLOBAL SWITCH ==================
_G.ESP_ENABLED = true
_G.LINES_ENABLED = true
_G.TEAMCHECK = true
_G.HIGHLIGHT_ENABLED = true
_G.BOX_ENABLED = true
_G.CROSSHAIR_ENABLED = true
_G.SKELETON_ENABLED = true

local MAX_VIEW_DISTANCE = 1000 -- Ограничение видимости

-- ================== SERVICES ==================
local RS = game:GetService("RunService")
local Players = game:GetService("Players")
local Cam = workspace.CurrentCamera
local LP = Players.LocalPlayer

-- ================== SETTINGS ==================
local ESPObjects = {}
local COLOR_THRESHOLD = 50
local CROSS_SIZE = 6

-- ================== HELPERS ==================
local function getColorByDistance(dist)
    if dist <= COLOR_THRESHOLD then
        return Color3.fromRGB(0,255,0)
    elseif dist >= MAX_VIEW_DISTANCE then
        return Color3.fromRGB(255,0,0)
    else
        local ratio = (dist - COLOR_THRESHOLD)/(MAX_VIEW_DISTANCE - COLOR_THRESHOLD)
        local r = math.floor(0*(1-ratio) + 255*ratio)
        local g = math.floor(255*(1-ratio) + 0*ratio)
        return Color3.fromRGB(r,g,0)
    end
end

local function getPlayerItems(model)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local items = {}

    -- Собираем инструменты в руках
    for _, tool in ipairs(model:GetChildren()) do
        if tool:IsA("Tool") then
            table.insert(items, tool.Name)
        end
    end

    -- Инструменты из рюкзака игрока
    local player = Players:GetPlayerFromCharacter(model)
    if player and player:FindFirstChild("Backpack") then
        for _, tool in ipairs(player.Backpack:GetChildren()) do
            if tool:IsA("Tool") then
                table.insert(items, tool.Name)
            end
        end
    end

    -- Если нет инструментов
    if #items == 0 then
        if humanoid then
            if humanoid.Health <= 0 then
                return "Спящий" -- Только мертвый
            else
                return "Без предмета" -- Живой, но без предметов
            end
        else
            return "Спящий"
        end
    end

    return table.concat(items, ", ")
end

local function getSkeletonParts(model)
    local parts = {}
    for _, name in ipairs({"Head","HumanoidRootPart","LeftUpperArm","RightUpperArm","LeftUpperLeg","RightUpperLeg","LeftLowerLeg","RightLowerLeg","LeftLowerArm","RightLowerArm"}) do
        local p = model:FindFirstChild(name)
        if p then parts[name] = p end
    end
    return parts
end

-- ================== CREATE ESP ==================
local function CreateESP(model)
    if ESPObjects[model] then return end
    if model == LP.Character then return end

    local hl = Instance.new("Highlight")
    hl.Name = "TridentESP"
    hl.FillColor = Color3.fromRGB(0,170,255)
    hl.OutlineColor = Color3.fromRGB(255,255,255)
    hl.FillTransparency = 0.6
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = model
    hl.Parent = game:GetService("CoreGui")

    local line = Drawing.new("Line")
    line.Thickness = 1.5
    line.Visible = true

    local infoText = Drawing.new("Text")
    infoText.Center = true
    infoText.Outline = true
    infoText.Size = 13
    infoText.Visible = true

    local box = Drawing.new("Square")
    box.Thickness = 2
    box.Filled = false
    box.Visible = true

    local skeletonLines = {}
    for i=1,10 do
        local l = Drawing.new("Line")
        l.Visible = true
        l.Thickness = 1.2
        skeletonLines[i] = l
    end

    ESPObjects[model] = {HL = hl, Line = line, Info = infoText, Box = box, Skeleton = skeletonLines}
end

-- ================== INIT ==================
for _, model in ipairs(workspace:GetChildren()) do
    if model:IsA("Model") and model:FindFirstChild("HumanoidRootPart") then
        CreateESP(model)
    end
end

workspace.DescendantAdded:Connect(function(model)
    if model:IsA("Model") and model:FindFirstChild("HumanoidRootPart") then
        CreateESP(model)
    end
end)

-- ================== CROSSHAIR ==================
local crossH = Drawing.new("Line")
local crossV = Drawing.new("Line")
crossH.Thickness = 1.5
crossV.Thickness = 1.5
local hue = 0

RS.RenderStepped:Connect(function()
    hue = (hue + 1) % 360
    local rad = math.rad(hue)
    local r = math.floor((math.sin(rad)+1)/2*255)
    local g = math.floor((math.sin(rad + 2)+1)/2*255)
    local b = math.floor((math.sin(rad + 4)+1)/2*255)
    crossH.Color = Color3.fromRGB(r,g,b)
    crossV.Color = Color3.fromRGB(r,g,b)

    if _G.CROSSHAIR_ENABLED then
        local center = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)
        crossH.From = Vector2.new(center.X - CROSS_SIZE, center.Y)
        crossH.To   = Vector2.new(center.X + CROSS_SIZE, center.Y)
        crossV.From = Vector2.new(center.X, center.Y - CROSS_SIZE)
        crossV.To   = Vector2.new(center.X, center.Y + CROSS_SIZE)
        crossH.Visible = true
        crossV.Visible = true
    else
        crossH.Visible = false
        crossV.Visible = false
    end
end)

-- ================== UPDATE ESP ==================
RS.RenderStepped:Connect(function()
    local center = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)

    for model, data in pairs(ESPObjects) do
        if not _G.ESP_ENABLED or not model or not model.Parent or not model:FindFirstChild("HumanoidRootPart") then
            data.HL.Enabled = false
            data.Line.Visible = false
            data.Info.Visible = false
            data.Box.Visible = false
            for _, l in ipairs(data.Skeleton) do l.Visible = false end
        else
            local hrp = model.HumanoidRootPart
            local dist = (Cam.CFrame.Position - hrp.Position).Magnitude

            if dist > MAX_VIEW_DISTANCE then
                data.HL.Enabled = false
                data.Line.Visible = false
                data.Box.Visible = false
                data.Info.Visible = false
                for _, l in ipairs(data.Skeleton) do l.Visible = false end
                continue
            end

            local color = getColorByDistance(dist)

            local isEnemy = true
            if _G.TEAMCHECK and LP.Team and model:FindFirstChild("Team") then
                if model.Team.Value == LP.Team then isEnemy = false end
            end

            data.HL.Enabled = _G.HIGHLIGHT_ENABLED and isEnemy

            -- Линия
            local pos, onScreen = Cam:WorldToViewportPoint(hrp.Position)
            if _G.LINES_ENABLED and isEnemy and onScreen and pos.Z > 0 then
                data.Line.From = center
                data.Line.To = Vector2.new(pos.X, pos.Y)
                data.Line.Color = color
                data.Line.Visible = true
            else
                data.Line.Visible = false
            end

            -- Box + Info
            if _G.BOX_ENABLED and isEnemy and onScreen and pos.Z > 0 then
                local minX, minY, maxX, maxY
                for _, part in ipairs(model:GetChildren()) do
                    if part:IsA("BasePart") then
                        local p = Cam:WorldToViewportPoint(part.Position)
                        minX = minX and math.min(minX, p.X) or p.X
                        maxX = maxX and math.max(maxX, p.X) or p.X
                        minY = minY and math.min(minY, p.Y) or p.Y
                        maxY = maxY and math.max(maxY, p.Y) or p.Y
                    end
                end
                if minX and minY and maxX and maxY then
                    data.Box.Position = Vector2.new(minX, minY)
                    data.Box.Size = Vector2.new(maxX - minX, maxY - minY)
                    data.Box.Color = color
                    data.Box.Visible = true

                    data.Info.Text = string.format("[%dm] %s", math.floor(dist), getPlayerItems(model))
                    data.Info.Position = Vector2.new(minX + (maxX-minX)/2, minY - 12)
                    data.Info.Color = color
                    data.Info.Visible = true
                else
                    data.Box.Visible = false
                    data.Info.Visible = false
                end
            else
                data.Box.Visible = false
                data.Info.Visible = false
            end

            -- Skeleton
            if _G.SKELETON_ENABLED and isEnemy and onScreen and pos.Z > 0 then
                local parts = getSkeletonParts(model)
                local lines = data.Skeleton
                local connections = {
                    {"Head","HumanoidRootPart"},
                    {"LeftUpperArm","LeftLowerArm"},
                    {"RightUpperArm","RightLowerArm"},
                    {"LeftUpperLeg","LeftLowerLeg"},
                    {"RightUpperLeg","RightLowerLeg"},
                    {"LeftUpperArm","HumanoidRootPart"},
                    {"RightUpperArm","HumanoidRootPart"},
                    {"LeftUpperLeg","HumanoidRootPart"},
                    {"RightUpperLeg","HumanoidRootPart"},
                    {"Head","HumanoidRootPart"}
                }
                for i, pair in ipairs(connections) do
                    local a = parts[pair[1]]
                    local b = parts[pair[2]]
                    if a and b then
                        local pa = Cam:WorldToViewportPoint(a.Position)
                        local pb = Cam:WorldToViewportPoint(b.Position)
                        lines[i].From = Vector2.new(pa.X, pa.Y)
                        lines[i].To = Vector2.new(pb.X, pb.Y)
                        lines[i].Color = color
                        lines[i].Visible = true
                    else
                        lines[i].Visible = false
                    end
                end
            else
                for _, l in ipairs(data.Skeleton) do l.Visible = false end
            end
        end
    end
end)
