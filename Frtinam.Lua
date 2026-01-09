-- ================== GLOBAL SWITCH ================== _G.ESP_ENABLED = false _G.LINES_ENABLED = false _G.TEAMCHECK = true _G.HIGHLIGHT_ENABLED = false _G.BOX_ENABLED = false _G.CROSSHAIR_ENABLED = false _G.SKELETON_ENABLED = false

local MAX_VIEW_DISTANCE = 1000

-- ================== SERVICES ================== local RS = game:GetService("RunService") local Players = game:GetService("Players") local Cam = workspace.CurrentCamera local LP = Players.LocalPlayer local UIS = game:GetService("UserInputService")

-- ================== SETTINGS ================== local ESPObjects = {} local COLOR_THRESHOLD = 50 local CROSS_SIZE = 6

-- ================== HELPERS ================== local function getColorByDistance(dist) if dist <= COLOR_THRESHOLD then return Color3.fromRGB(0,255,0) elseif dist >= MAX_VIEW_DISTANCE then return Color3.fromRGB(255,0,0) else local ratio = (dist - COLOR_THRESHOLD)/(MAX_VIEW_DISTANCE - COLOR_THRESHOLD) local r = math.floor(0*(1-ratio) + 255ratio) local g = math.floor(255(1-ratio) + 0*ratio) return Color3.fromRGB(r,g,0) end end

local function getPlayerItems(model) local humanoid = model:FindFirstChildOfClass("Humanoid") local items = {} for _, tool in ipairs(model:GetChildren()) do if tool:IsA("Tool") then table.insert(items, tool.Name) end end local player = Players:GetPlayerFromCharacter(model) if player then for _, t in ipairs(player.Backpack:GetChildren()) do if t:IsA("Tool") then table.insert(items, t.Name) end end end if #items == 0 then if not humanoid or humanoid.Health <= 0 then return "Спящий" else return "Без предмета" end end return table.concat(items, ", ") end

local function getSkeletonParts(model) local parts = {} for _, name in ipairs({"Head","HumanoidRootPart","LeftUpperArm","RightUpperArm","LeftUpperLeg","RightUpperLeg","LeftLowerLeg","RightLowerLeg","LeftLowerArm","RightLowerArm"}) do local p = model:FindFirstChild(name) if p then parts[name] = p end end return parts end

-- ================== CREATE ESP ================== local function CreateESP(model) if ESPObjects[model] then return end if model == LP.Character then return end

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

for _, model in ipairs(workspace:GetChildren()) do if model:IsA("Model") and model:FindFirstChild("HumanoidRootPart") then CreateESP(model) end end

workspace.DescendantAdded:Connect(function(model) if model:IsA("Model") and model:FindFirstChild("HumanoidRootPart") then CreateESP(model) end end)

-- ================== CROSSHAIR ================== local crossH = Drawing.new("Line") local crossV = Drawing.new("Line") crossH.Thickness = 1.5 crossV.Thickness = 1.5 local hue = 0

RS.RenderStepped:Connect(function() hue = (hue + 1) % 360 local rad = math.rad(hue) local r = math.floor((math.sin(rad)+1)/2255) local g = math.floor((math.sin(rad + 2)+1)/2255) local b = math.floor((math.sin(rad + 4)+1)/2*255) crossH.Color = Color3.fromRGB(r,g,b) crossV.Color = Color3.fromRGB(r,g,b)

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

-- ================== UPDATE ESP ================== RS.RenderStepped:Connect(function() local center = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2) for model, data in pairs(ESPObjects) do if not model or not model.Parent or not model:FindFirstChild("HumanoidRootPart") then data.HL.Enabled = false data.Line.Visible = false data.Info.Visible = false data.Box.Visible = false for _, l in ipairs(data.Skeleton) do l.Visible = false end else local hrp = model:FindFirstChild("HumanoidRootPart") local dist = (Cam.CFrame.Position - hrp.Position).Magnitude if dist > MAX_VIEW_DISTANCE then data.HL.Enabled = false data.Line.Visible = false data.Info.Visible = false data.Box.Visible = false for _, l in ipairs(data.Skeleton) do l.Visible = false end else local color = getColorByDistance(dist) local isEnemy = true if _G.TEAMCHECK and LP.Team and model:FindFirstChild("Team") then if model.Team.Value == LP.Team then isEnemy = false end end

data.HL.Enabled = _G.HIGHLIGHT_ENABLED and isEnemy

            local pos, onScreen = Cam:WorldToViewportPoint(hrp.Position)

            data.Line.Visible = _G.LINES_ENABLED and isEnemy and onScreen and pos.Z > 0
            if data.Line.Visible then
                data.Line.From = center
                data.Line.To = Vector2.new(pos.X,pos.Y)
                data.Line.Color = color
            end

            data.Box.Visible = _G.BOX_ENABLED and isEnemy and onScreen and pos.Z > 0
            if data.Box.Visible then
                local minX,minY,maxX,maxY
                for _, part in ipairs(model:GetChildren()) do
                    if part:IsA("BasePart") then
                        local p = Cam:WorldToViewportPoint(part.Position)
                        if not minX or p.X < minX then minX = p.X end
                        if not maxX or p.X > maxX then maxX = p.X end
                        if not minY or p.Y < minY then minY = p.Y end
                        if not maxY or p.Y > maxY then maxY = p.Y end
                    end
                end
                if minX then
                    data.Box.Position = Vector2.new(minX,minY)
                    data.Box.Size = Vector2.new(maxX-minX,maxY-minY)
                    data.Box.Color = color
                    data.Info.Text = string.format("[%dm] %s",math.floor(dist),getPlayerItems(model))
                    data.Info.Position = Vector2.new(minX+(maxX-minX)/2, minY-12)
                    data.Info.Color = color
                end
            end

            if _G.SKELETON_ENABLED and isEnemy and onScreen and pos.Z>0 then
                local parts = getSkeletonParts(model)
                local lines = data.Skeleton
                local connections = {
                    {"Head","HumanoidRootPart"},{"LeftUpperArm","LeftLowerArm"},{"RightUpperArm","RightLowerArm"},
                    {"LeftUpperLeg","LeftLowerLeg"},{"RightUpperLeg","RightLowerLeg"},{"LeftUpperArm","HumanoidRootPart"},
                    {"RightUpperArm","HumanoidRootPart"},{"LeftUpperLeg","HumanoidRootPart"},{"RightUpperLeg","HumanoidRootPart"},
                    {"Head","HumanoidRootPart"}
                }
                for i,pair in ipairs(connections) do
                    local a = parts[pair[1]]
                    local b = parts[pair[2]]
                    if a and b then
                        local pa = Cam:WorldToViewportPoint(a.Position)
                        local pb = Cam:WorldToViewportPoint(b.Position)
                        lines[i].From = Vector2.new(pa.X,pa.Y)
                        lines[i].To = Vector2.new(pb.X,pb.Y)
                        lines[i].Color = color
                        lines[i].Visible = true
                    else lines[i].Visible = false end
                end
            else
                for _, l in ipairs(data.Skeleton) do l.Visible = false end
            end
        end
    end
end

end)

-- ================== MENU GUI ================== local gui = Instance.new("ScreenGui", LP.PlayerGui) gui.ResetOnSpawn = false

local menuFrame = Instance.new("Frame", gui) menuFrame.Size = UDim2.new(0,65,0,65) menuFrame.Position = UDim2.new(0.5,-32.5,0.5,-32.5) menuFrame.BackgroundColor3 = Color3.fromRGB(25,25,25) menuFrame.Active = true menuFrame.Draggable = true Instance.new("UICorner", menuFrame).CornerRadius = UDim.new(0,6)

local title = Instance.new("TextLabel", menuFrame) title.Size = UDim2.new(1,0,0.15,0) title.Position = UDim2.new(0,0,0,0) title.Text = "Risman Script" title.TextColor3 = Color3.new(1,1,1) title.BackgroundTransparency = 1

local toggleBtn = Instance.new("TextButton", gui) toggleBtn.Size = UDim2.new(0,650.1,0,650.1) toggleBtn.Position = menuFrame.Position + UDim2.new(0,65,0,0) toggleBtn.Text = "🔱" toggleBtn.BackgroundColor3 = Color3.fromRGB(50,50,50) toggleBtn.Active = true toggleBtn.Draggable = true Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0,4)

local menuVisible = true

toggleBtn.MouseButton1Click:Connect(function() menuVisible = not menuVisible menuFrame.Visible = menuVisible end)

local function createButton(text,posY,varName) local btn = Instance.new("TextButton", menuFrame) btn.Size = UDim2.new(0.9,0,0.15,0) btn.Position = UDim2.new(0.05,0,posY,0) btn.Text = text .. " 🔴" btn.BackgroundColor3 = Color3.fromRGB(40,40,40) btn.TextColor3 = Color3.new(1,1,1) Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4) btn.MouseButton1Click:Connect(function() _G[varName] = not _G[varName] end) RS.RenderStepped:Connect(function() btn.Text = text .. (_G[varName] and " 🟢" or " 🔴") end) end

createButton("BOX+PODSVET",0.2,"BOX_ENABLED") createButton("Line",0.4,"LINES_ENABLED") createButton("Skeleton",0.6,"SKELETON_ENABLED") createButton("Cursor",0.8,"CROSSHAIR_ENABLED")
