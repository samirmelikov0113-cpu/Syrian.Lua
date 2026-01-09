-- ================== GLOBAL SWITCH ==================
_G.ESP_ENABLED = true
_G.BOX_ENABLED = true
_G.SKELETON_ENABLED = true
_G.WEAPONESP_ENABLED = true

local MAX_VIEW_DISTANCE = 1000
local COLOR_THRESHOLD = 50
local HBSizeX, HBSizeY, HBSizeZ = 9, 13, 7
local HBTrans = 0.5

-- ================== SERVICES ==================
local RS = game:GetService("RunService")
local Players = game:GetService("Players")
local Cam = workspace.CurrentCamera
local LP = Players.LocalPlayer

-- ================== ESP STORAGE ==================
local ESPObjects = {}
local hitboxlist = {}

-- ================== WEAPON TABLE ==================
local Weapons = {
    Bow = {"Arrow","Fabric","Handle","Meshes/Bow","ADS","Mover","AnimationController"},
    AR15 = {"AnimSaves","Barrel","Body","Bolt","ChargingHandle","Decor","Grip","Handle","Mag","Rails","Stock","ADS","Muzzle","AnimationController"},
    AdminMinigun = {"AnimSaves","Barrel","BarrelBolts","Body","Bolt","Handle","Handle2","Trigger","AnimationController"},
    Bandage = {"Handle","Bandage","AnimationController"},
    Beans = {"Beans","Handle","AnimationController"},
    BloxyCola = {"Bloxy Cola HD","Handle","AnimationController"},
    Blunderbuss = {"Body","Handle","Tube","thing","ADS","Muzzle","AnimationController"},
    C4 = {"Handle","default","prim","Light","Timer","AnimationController"},
    C9 = {"Barrel","Body","Bolt","Decor","Grip","Handle","LowerSlide","Mag","Sight1","Sight2","UpperSlide","ADS","Muzzle","AnimationController"},
    ClimbingPick = {"Left","Right","AnimationController"},
    CrossBow = {"Arrow","BackMetal","Body","FrontNails","Handle","Release","SpringSteel","String","Wheel","ADS","Slide","AnimationController"},
    Crowbar = {"Handle","model","AnimationController"},
    Dynamite = {"Handle","Body","Fuse","AnimationController"},
    EnergyRifle = {"DefaultSight","FrontCover","Glowing","Grip","Handle","Mag","Metal","Metal2","RearCover","RearDecor","Screws","Tubes","AnimationController"},
    FlameThrower = {"Barrel","Body","Decor","Grip","Handle","Hoses","LowerTank","Mag","Strap","Tubes","Particle","AnimationController"},
    Flare = {"Handle","Body","Color","AnimationController"},
    Flashgrenade = {"Body","Color","Fuse","Handle","Lever","Ring","AnimationController"},
    GaussRifle = {"DefaultSight","Barrel","Body","CoilHolders","Coils","Decals1","Decals2","Grip","Handle","Housing","Mag","StockBack","AnimationController"},
    Glowstick = {"Ends","Handle","GlowPart","AnimationController"},
    Grenade = {"Body","Fuse","Handle","Lever","LeverHolder","Pin","AnimationController"},
    HMAR = {"DefaultSight","Body","Bolt","Bolts","Cover","Handle","Mag","Rails","Spring","Stock","Wood","Muzzle","AnimationController"},
    HMCharge = {"Charge","Fuse","Handle","Strap","AnimationController"},
    Hammer = {"Handle","Head","Dowel","AnimationController"},
    HealingBandage = {"Handle","Bandage","AnimationController"},
    IronHammer = {"Handle","Head","Dowel","AnimationController"},
    KABAR = {"Blade","Grip","Guard","Handle","AnimationController"},
    LeverActionRifle = {"9mm","DefaultSight","Body","Brass","Hammer","Handle","Lever","Metal","Thing","Wood","Muzzle","AnimationController"},
    M4A1 = {"DefaultSight","Body","Bolt","ChargeHandle","Grip","Handle","Mag","Metal","mbrk","Muzzle","AnimationController"},
    MedSerum = {"Body","Cross","Handle","Injector","Plunger","Spring","AnimationController"},
    Minigun = {"AnimSaves","Barrel","BarrelBolts","Body","Bolt","Handle","Handle2","Trigger","AnimationController"},
    MiningDrill = {"Bearings","Body","DrillBit","Handle","Inlets","Tubes","VisualHandle","AnimationController"},
    Molotov = {"Handle","default","Part","AnimationController"},
    PipePistol = {"DefaultSight","Body","Bolt","Handle","Mag","Muzzle","AnimationController","Animator"},
    PipeSMG = {"DefaultSight","Barrel","Body","Bolt","Flap","Grip","Handle","Mag","Stock","Muzzle","AnimationController"},
    PumpShotgun = {"Barrel","Body","Handle","MainMetal","RearSight","Shell","Slider","ADS","Muzzle","AnimationController"},
    RPG = {"RocketModel","Body","Body2","Caps","Fasteners","FireMech","Handle","Safety","Sight","Trigger","ADS","Muzzle","AnimationController"},
    RiotShield = {"Body","Glass","Handle","Metal","Straps","AnimationController"},
    SCAR = {"DefaultSight","Barrel","Body","ChargingHandle","Decals","Handle","Mag","Rails","ShoulderPad","Stock","Muzzle","AnimationController"},
    SVD = {"DefaultSight","Body","Bolt","Handle","Magazine","Magazine2","Metal2","Wood","AnimationController"},
    StelHammer = {"Handle","Head","Dowel","DowelDecor","AnimationController"},
    StoneHammer = {"Handle","Head","Dowel","AnimationController"},
    USP9 = {"Body","Handle","Mag","Slide","ADS","Muzzle","AnimationController"},
    UZI = {"DefaultSight","Body","Body2","Bolt","ChargingHandle","Decor","Grip","Handle","Mag","Stock","Muzzle","AnimationController"}
}

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

local function getWeapon(character)
    local hand = character:FindFirstChild("HandModel")
    if not hand then return "None" end
    local bestWeapon, bestCount = "None", 0
    for wname, parts in pairs(Weapons) do
        local count = 0
        for _, part in ipairs(parts) do
            if hand:FindFirstChild(part, true) then
                count = count + 1
            end
        end
        if count > bestCount then
            bestCount = count
            bestWeapon = wname
        end
    end
    return bestWeapon
end

local function getMainParts(character)
    local head = character:FindFirstChild("Head")
    local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso") or character:FindFirstChild("LowerTorso")
    if head and torso then
        return head, torso
    end
end

-- ================== CREATE ESP ==================
local function CreateESP(character)
    if ESPObjects[character] or character == LP.Character then return end

    -- Box ESP
    local box = Drawing.new("Square")
    box.Thickness = 2
    box.Filled = false
    box.Visible = false

    -- Weapon/Text ESP
    local text = Drawing.new("Text")
    text.Center = true
    text.Outline = true
    text.Size = 13
    text.Visible = false

    -- Skeleton ESP
    local skeletonLines = {}
    for i=1,9 do
        local line = Drawing.new("Line")
        line.Thickness = 1.2
        line.Visible = false
        table.insert(skeletonLines, line)
    end

    -- Hitbox
    if character:FindFirstChild("HumanoidRootPart") and not character:FindFirstChild("Fake1") then
        local fh = Instance.new("Part", character)
        fh.Name = "Head"
        fh.Size = Vector3.new(HBSizeX, HBSizeY, HBSizeZ)
        fh.CFrame = character.HumanoidRootPart.CFrame
        fh.Anchored = true
        fh.CanCollide = false
        fh.Transparency = HBTrans
        fh.BrickColor = BrickColor.new("Really red")
        local tag = Instance.new("Part", character)
        tag.Name = "Fake1"
        table.insert(hitboxlist, fh)
    end

    ESPObjects[character] = {Box=box, Text=text, Skeleton=skeletonLines}
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

-- ================== UPDATE ESP ==================
RS.RenderStepped:Connect(function()
    for character, data in pairs(ESPObjects) do
        if not _G.ESP_ENABLED or not character or not character.Parent or not character:FindFirstChild("HumanoidRootPart") then
            data.Box.Visible = false
            data.Text.Visible = false
            for _, l in ipairs(data.Skeleton) do l.Visible = false end
        else
            local hrp = character.HumanoidRootPart
            local dist = (Cam.CFrame.Position - hrp.Position).Magnitude
            if dist > MAX_VIEW_DISTANCE then
                data.Box.Visible = false
                data.Text.Visible = false
                for _, l in ipairs(data.Skeleton) do l.Visible = false end
                continue
            end

            local color = getColorByDistance(dist)
            local head, torso = getMainParts(character)
            if not head or not torso then continue end

            -- Box ESP (только ключевые части для стабильности)
            if _G.BOX_ENABLED then
                local corners = {}
                for _, partName in ipairs({"Head","Torso","LeftUpperArm","RightUpperArm","LeftUpperLeg","RightUpperLeg"}) do
                    local part = character:FindFirstChild(partName)
                    if part then
                        local pos, onScreen = Cam:WorldToViewportPoint(part.Position)
                        if onScreen then
                            table.insert(corners, Vector2.new(pos.X,pos.Y))
                        end
                    end
                end

                if #corners > 0 then
                    local minX = corners[1].X
                    local minY = corners[1].Y
                    local maxX = corners[1].X
                    local maxY = corners[1].Y
                    for _, c in ipairs(corners) do
                        minX = math.min(minX,c.X)
                        minY = math.min(minY,c.Y)
                        maxX = math.max(maxX,c.X)
                        maxY = math.max(maxY,c.Y)
                    end

                    data.Box.Position = Vector2.new(minX,minY)
                    data.Box.Size = Vector2.new(maxX-minX,maxY-minY)
                    data.Box.Color = color
                    data.Box.Visible = true

                    if _G.WEAPONESP_ENABLED then
                        data.Text.Text = string.format("[%dm] %s", math.floor(dist), getWeapon(character))
                        data.Text.Position = Vector2.new(minX + (maxX-minX)/2, minY - 14)
                        data.Text.Color = color
                        data.Text.Visible = true
                    else
                        data.Text.Visible = false
                    end
                else
                    data.Box.Visible = false
                    data.Text.Visible = false
                end
            else
                data.Box.Visible = false
                data.Text.Visible = false
            end

            -- Skeleton ESP
            if _G.SKELETON_ENABLED then
                local parts = {
                    head=head,
                    torso=torso,
                    LArm=character:FindFirstChild("LeftUpperArm"),
                    RArm=character:FindFirstChild("RightUpperArm"),
                    LLeg=character:FindFirstChild("LeftUpperLeg"),
                    RLeg=character:FindFirstChild("RightUpperLeg"),
                    LHand=character:FindFirstChild("LeftLowerArm"),
                    RHand=character:FindFirstChild("RightLowerArm"),
                    LFoot=character:FindFirstChild("LeftLowerLeg"),
                    RFoot=character:FindFirstChild("RightLowerLeg")
                }

                local skeletonPairs = {
                    {"head","torso"},{"torso","LArm"},{"torso","RArm"},
                    {"torso","LLeg"},{"torso","RLeg"},{"LArm","LHand"},
                    {"RArm","RHand"},{"LLeg","LFoot"},{"RLeg","RFoot"}
                }

                for i, pair in ipairs(skeletonPairs) do
                    local a = parts[pair[1]]
                    local b = parts[pair[2]]
                    if a and b then
                        local pa, onA = Cam:WorldToViewportPoint(a.Position)
                        local pb, onB = Cam:WorldToViewportPoint(b.Position)
                        if onA or onB then
                            data.Skeleton[i].From = Vector2.new(pa.X, pa.Y)
                            data.Skeleton[i].To = Vector2.new(pb.X, pb.Y)
                            data.Skeleton[i].Color = color
                            data.Skeleton[i].Visible = true
                        else
                            data.Skeleton[i].Visible = false
                        end
                    else
                        data.Skeleton[i].Visible = false
                    end
                end
            else
                for _, l in ipairs(data.Skeleton) do l.Visible = false end
            end
        end
    end
end)
