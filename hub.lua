--[[
    Prisma Hub — 1.8.2
    Arquivo único. PC. Sem key. Anti-detecção básica.
    Base: listas clicáveis de mobs/bosses/jogadores, teleporte por coordenadas,
    espectar, anti-AFK, kill switch e save/load.
    Novidades 1.8: ESP (jogadores/bosses/frutas/baús), notificador de frutas,
    lista + TP de frutas, Auto Quest (1º/2º/3º mar), Auto Raid pairando alto e
    matando na hora, Auto Skills Z/X/C, Kill Aura instantâneo, ataque rápido,
    Auto Stats, server hop, auto rejoin, fly, noclip, pulo infinito e
    auto guardar frutas (confere o espaço antes de guardar).
    UI estilo hub genérico: sidebar, tema escuro e acento violeta.
]]

-- resolve onde a GUI vai morar (gethui se existir, senão PlayerGui/CoreGui)
local function resolveGuiParent()
    if gethui then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    local PlayersSvc = game:GetService("Players")
    local lp = PlayersSvc.LocalPlayer
    if lp then
        local ok, pg = pcall(function() return lp:WaitForChild("PlayerGui", 5) end)
        if ok and pg then return pg end
    end
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok then return cg end
    return nil
end

local GUI_PARENT = resolveGuiParent()

local bootOk, bootErr = pcall(function()

--==================== CONFIG ====================
local CONFIG = {
    name = "Prisma Hub",
    version = "1.8.2",

    jitter = 0.30,
    maxErrors = 3,
    remoteMinInterval = 0.08,
    maxScan = 100000,

    farmRange = 20,
    bossRange = 22,
    attackDelay = 0.10,
    farmDelay = 0.30,
    fastAttackDelay = 0.03,
    killAuraRange = 30,
    killAuraDelay = 0.02,
    killAuraBurst = 3,
    autoRaidDelay = 2,

    esp = {
        refresh = 0.25,
        maxDistance = 3000,
        playerColor = Color3.fromRGB(88, 140, 255),
        bossColor = Color3.fromRGB(255, 90, 90),
        fruitColor = Color3.fromRGB(120, 230, 140),
        chestColor = Color3.fromRGB(255, 210, 90),
    },

    skills = {
        z = 0.55,
        x = 0.85,
        c = 1.15,
    },

    flySpeed = 70,
    noclipRefresh = 0.2,

    remotes = {
        main = "CommF_",
        event = "CommE",
    },
}

--==================== ILHAS (coordenadas reais) ====================
-- PlaceId -> mar
local PLACE_IDS = {
    [2753915549] = 1,
    [4442272183] = 2,
    [7449423635] = 3,
}

local ISLANDS = {
    [1] = {
        { name = "Wild Mill", pos = Vector3.new(1042.15, 16.30, 1444.34) },
        { name = "Marine 1st", pos = Vector3.new(-2599.67, 6.91, 2062.22) },
        { name = "Marine 2nd", pos = Vector3.new(-5081.35, 85.22, 4257.36) },
        { name = "Middle Town", pos = Vector3.new(-655.97, 7.88, 1573.76) },
        { name = "Jungle", pos = Vector3.new(-1499.99, 22.88, 353.87) },
        { name = "Pirate Village", pos = Vector3.new(-1163.39, 44.78, 3842.83) },
        { name = "Desert", pos = Vector3.new(954.02, 6.63, 4262.61) },
        { name = "Frozen Village", pos = Vector3.new(1144.53, 7.33, -1164.73) },
        { name = "Colosseum", pos = Vector3.new(-1667.59, 39.39, -3135.58) },
        { name = "Prison", pos = Vector3.new(4857.70, 5.68, 732.76) },
        { name = "Mob Leader", pos = Vector3.new(-2841.96, 7.36, 5318.10) },
        { name = "Magma Village", pos = Vector3.new(-5328.87, 8.62, 8427.40) },
        { name = "Underwater Gate", pos = Vector3.new(3893.95, 5.40, -1893.49) },
        { name = "Underwater City", pos = Vector3.new(61191.12, 18.50, 1561.89) },
        { name = "Fountain City", pos = Vector3.new(5244.71, 38.53, 4073.50) },
        { name = "Sky 1st", pos = Vector3.new(-4878.04, 717.71, -2637.73) },
        { name = "Sky 2nd", pos = Vector3.new(-7899.62, 5545.60, -422.22) },
        { name = "Sky 3rd", pos = Vector3.new(-7868.53, 5638.21, -1482.55) },
    },
    [2] = {
        { name = "Dock", pos = Vector3.new(-12.52, 19.30, 2827.85) },
        { name = "Mansion", pos = Vector3.new(-390.35, 321.90, 869.01) },
        { name = "Kingdom of Rose", pos = Vector3.new(-388.30, 138.36, 1132.17) },
        { name = "Cafe", pos = Vector3.new(-379.71, 73.05, 304.85) },
        { name = "Sunflower Field", pos = Vector3.new(-1576.72, 198.62, 13.73) },
        { name = "Jeramy Mountain", pos = Vector3.new(1986.35, 448.96, 796.70) },
        { name = "Colosseum", pos = Vector3.new(-1871.90, 45.82, 1359.68) },
        { name = "Factory", pos = Vector3.new(349.54, 74.45, -355.62) },
        { name = "The Bridge", pos = Vector3.new(-1860.64, 88.38, -1859.16) },
        { name = "Green Bit", pos = Vector3.new(-2202.37, 73.10, -2819.27) },
        { name = "Graveyard", pos = Vector3.new(-5617.59, 492.22, -778.30) },
        { name = "Dark Area", pos = Vector3.new(3464.77, 13.38, -3368.90) },
        { name = "Snow Mountain", pos = Vector3.new(561.24, 401.45, -5297.14) },
        { name = "Hot Island", pos = Vector3.new(-5505.96, 15.98, -5366.61) },
        { name = "Cold Island", pos = Vector3.new(-5924.72, 15.98, -4996.43) },
        { name = "Ice Castle", pos = Vector3.new(6111.71, 294.41, -6716.48) },
        { name = "Usopp Island", pos = Vector3.new(4760.50, 8.34, 2849.24) },
        { name = "Inscription Island", pos = Vector3.new(-5099.01, 98.24, 2424.40) },
        { name = "Forgotten Island", pos = Vector3.new(-3051.95, 238.87, -10250.81) },
        { name = "Ghost Ship", entrance = Vector3.new(923.21, 126.98, 32852.83) },
        { name = "Mini Sky", pos = Vector3.new(-262.12, 49325.69, -35272.50) },
    },
    [3] = {
        { name = "Port Town", pos = Vector3.new(-275.22, 43.76, 5451.07) },
        { name = "Hydra Island", pos = Vector3.new(5541.27, 668.30, 195.48) },
        { name = "Giant Tree", pos = Vector3.new(2276.09, 25.88, -6493.03) },
        { name = "Zou Island", pos = Vector3.new(-10034.40, 331.79, -8319.69) },
        { name = "Pineapple Village", pos = Vector3.new(-11172.95, 331.80, -10151.03) },
        { name = "Mansion", pos = Vector3.new(-12549.00, 332.40, -7603.19) },
        { name = "Castle on the Sea", pos = Vector3.new(-5498.05, 313.79, -2860.60) },
        { name = "Graveyard Island", pos = Vector3.new(-9515.07, 142.13, 5537.58) },
        { name = "Haunted Castle", pos = Vector3.new(-8932.86, 143.26, 6063.31) },
        { name = "Raid Lab", pos = Vector3.new(-5057.15, 314.54, -2934.80) },
        { name = "Mini Sky", pos = Vector3.new(-263.67, 49325.50, -35260.00) },
        { name = "Ice Cream Island", pos = Vector3.new(-691.83, 371.94, -11106.40) },
        { name = "Sea of Cake", pos = Vector3.new(-2073.26, 37.16, -10183.33) },
        { name = "Cake Loaf", pos = Vector3.new(-2099.33, 67.00, -12128.60) },
    },
}

local WORLD_TRAVEL = {
    { name = "Primeiro Mar", remote = "TravelMain" },
    { name = "Segundo Mar", remote = "TravelDressrosa" },
    { name = "Terceiro Mar", remote = "TravelZou" },
}

--==================== SERVIÇOS ====================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")

local LP = Players.LocalPlayer
local CURRENT_SEA = PLACE_IDS[game.PlaceId]

--==================== ESTADO ====================
local State = {
    attacking = false,
    farming = false,
    farmTarget = "",
    farmTargetLevel = nil,
    bossFarming = false,
    bossTarget = "",
    lastToolName = nil,
    baseWalkSpeed = 16,
    spectateTarget = nil,
    selectedPlayer = nil,
    spawnPos = nil,
    errors = {},

    -- ESP
    espPlayers = false,
    espFruits = false,
    espChests = false,
    espBosses = false,
    espRunning = false,
    espCache = {},
    fruitNotify = false,
    seenFruits = {},
    fruitTarget = nil,
    fruitNotifyStarted = false,
    fruitSpawnLast = nil,
    fruitSpawnEstimate = nil,
    fruitSpawnIntervals = {},
    fruitSpawnApprox = false,
    fruitRadarConn = nil,
    fruitRadarGrace = 0,
    fruitAutoStore = false,
    fruitStoreCapacity = 1,
    fruitStoreRunning = false,
    fruitStoreBusy = false,
    fruitStoreWarned = {},

    -- combate
    skillZ = false,
    skillX = false,
    skillC = false,
    skillRunning = false,
    fastAttack = false,
    fastAttackOwnsAttack = false,

    -- progressão
    autoQuest = false,
    autoRaid = false,
    raidKey = nil,
    raidStartedFarm = false,
    raidInRaid = false,
    raidElement = "Flame",
    raidConn = nil,
    raidLastStart = 0,
    raidRunning = false,
    raidNoTimerSince = nil,
    raidIsland = nil,
    raidClearSince = nil,
    autoAwaken = false,
    awakenRunning = false,
    instantFarm = true,
    killAura = false,
    questKey = nil,
    questStartedFarm = false,
    autoStats = false,
    statTarget = "Melee",

    -- movimento
    fly = false,
    noclip = false,
    infiniteJump = false,

    -- servidor
    autoRejoin = false,
    hopping = false,
}

local UI = { toggles = {}, sliders = {}, lists = {} }
local antiAfkConn = nil
local mobCache = { time = 0, name = "", list = {} }

-- Kill aura/farm instantâneo: SimulationRadius + Humanoid.Health = 0.
local AURA = {
    hitId = nil,
    hooked = false,
    combo = 0,
    lastWeapon = 0,
    lastSim = 0,
    simOk = nil,
    lastHitIdWarn = 0,
}

-- declarada aqui e definida mais abaixo; usada também pelo farm/raid
local forceSimulationRadius

--==================== RAID ====================
-- Locais do botão de raid (2º e 3º mar). O 1º mar não tem raid.
local RAID_LOCATIONS = {
    [2] = {
        tube = Vector3.new(-6546.1, 310.5, -4767.7),
        button = Vector3.new(-6530.7, 304.8, -4798.4),
    },
    [3] = {
        tube = Vector3.new(-5010.1, 315.0, -2816.5),
        button = Vector3.new(-5010.1, 315.0, -2816.5),
    },
}

local RAID_ELEMENTS = {
    "Flame", "Ice", "Quake", "Dark", "Light", "Sand", "Magma", "Rumble",
    "Buddha", "Paw", "Gravity", "Dough", "Shadow", "Venom", "Control",
    "Spirit", "Bomb", "Spike", "Blizzard", "Phoenix",
}

--==================== BOSSES ====================
-- Nomes dos bosses (todas as ilhas/mar). Usados para separar boss de mob comum.
local BOSS_NAMES = {
    -- Primeiro mar
    "The Gorilla King", "Bobby", "The Saw", "Yeti", "Mob Leader",
    "Vice Admiral", "Saber Expert", "Warden", "Chief Warden", "Swan",
    "Magma Admiral", "Fishman Lord", "Wysper", "Thunder God", "Cyborg",
    "Ice Admiral", "Greybeard",
    -- Segundo mar
    "Diamond", "Jeremy", "Jeramy", "Fajita", "Don Swan", "Smoke Admiral",
    "Awakened Ice Admiral", "Tide Keeper", "Darkbeard", "Cursed Captain", "Order",
    -- Terceiro mar
    "Stone", "Hydra Leader", "Kilo Admiral", "Captain Elephant",
    "Beautiful Pirate", "Cake Queen", "Longma", "Soul Reaper",
    "Island Empress", "Dough King", "Cake Prince", "rip_indra True Form",
}

-- normaliza nome: minúsculo, sem "the " inicial, sem espaços extras
local function normName(name)
    local n = string.lower(tostring(name))
    n = n:gsub("^the%s+", "")
    n = n:gsub("%s+", " ")
    return n
end

local BOSS_SET = {}
for _, n in ipairs(BOSS_NAMES) do
    BOSS_SET[normName(n)] = n
end

local function isBossName(name)
    return BOSS_SET[normName(name)] ~= nil
end

-- setStatus é definido na seção de UI; declarado aqui para uso anterior
local setStatus

--==================== CORE ====================
local function jitter(base)
    local f = 1 + (math.random() * 2 - 1) * CONFIG.jitter
    return base * f
end

local function trackError(key)
    State.errors[key] = (State.errors[key] or 0) + 1
    if State.errors[key] >= CONFIG.maxErrors then
        State.errors[key] = 0
        return true
    end
    return false
end

local function clearErrors(key)
    State.errors[key] = 0
end

local function getChar()
    return LP.Character
end

local function getHRP()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function isAlive()
    local h = getHum()
    return h ~= nil and h.Health > 0
end

-- registra a última arma equipada para poder reequipar após um TP
local function watchTools(char)
    if not char then return end
    pcall(function()
        char.ChildAdded:Connect(function(c)
            if c:IsA("Tool") then
                State.lastToolName = c.Name
            end
        end)
        local t = char:FindFirstChildOfClass("Tool")
        if t then State.lastToolName = t.Name end
    end)
end

local function notify(text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = CONFIG.name,
            Text = tostring(text),
            Duration = duration or 3,
        })
    end)
end

local function safeCall(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then
        if setStatus then setStatus("Erro: " .. tostring(err), true) end
        notify("Erro: " .. tostring(err), 5)
    end
    return ok
end

-- remotes: busca em ReplicatedStorage (inclui pasta Remotes) com cache
local remoteCache = {}
local function getRemote(name)
    if remoteCache[name] then return remoteCache[name] end
    local found = nil
    local roots = { ReplicatedStorage }
    local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
    if remotesFolder then table.insert(roots, remotesFolder) end

    for _, root in ipairs(roots) do
        if not found then
            for _, v in ipairs(root:GetDescendants()) do
                if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) and v.Name == name then
                    found = v
                    break
                end
            end
        end
    end

    remoteCache[name] = found
    return found
end

local remoteLast = {}
local function fireRemote(name, ...)
    local args = { ... }
    local now = os.clock()
    if remoteLast[name] and now - remoteLast[name] < CONFIG.remoteMinInterval then
        return false
    end
    remoteLast[name] = now

    local r = getRemote(name)
    if not r then return false end

    local ok
    if r:IsA("RemoteFunction") then
        ok = pcall(function() return r:InvokeServer(table.unpack(args)) end)
    else
        ok = pcall(function() r:FireServer(table.unpack(args)) end)
    end
    return ok
end

--==================== TELEPORTE ====================
local function setNoclip(on)
    local char = getChar()
    if not char then return end
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") then
            pcall(function() v.CanCollide = not on end)
        end
    end
end

-- movimento contínuo, ~300 studs/s (acima disso o jogo costuma reverter)
local function teleport(pos, label, silent, shouldStop)
    if not pos then
        if not silent and setStatus then setStatus("TP falhou: posição inválida", true) end
        return false
    end

    local char = getChar()
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    if not hrp then
        if not silent and setStatus then setStatus("TP falhou: sem personagem", true) end
        return false
    end
    if hum and hum.Health <= 0 then
        if not silent and setStatus then setStatus("TP falhou: personagem morto", true) end
        return false
    end

    local dist = (pos - hrp.Position).Magnitude
    if dist < 3 then
        if not silent and setStatus then
            setStatus("TP ok" .. (label and (": " .. label) or ""))
        end
        return true
    end

    local speed = 300
    local deadline = os.clock() + math.clamp(dist / speed + 4, 5, 180)
    local lastStatus = 0

    setNoclip(true)
    local ok = pcall(function()
        while os.clock() < deadline do
            if shouldStop and shouldStop() then break end
            if hum and hum.Health <= 0 then break end
            local cur = hrp.Position
            local delta = pos - cur
            local d = delta.Magnitude
            if d <= 3 then break end
            local step = math.min(speed * task.wait(), d)
            hrp.CFrame = hrp.CFrame + delta.Unit * step
            if not silent and os.clock() - lastStatus > 0.5 then
                lastStatus = os.clock()
                setStatus("TP... faltam " .. math.floor(d) .. " studs")
            end
        end
    end)
    setNoclip(false)

    if not ok then
        if not silent and setStatus then setStatus("TP falhou durante o movimento", true) end
        return false
    end

    task.wait(0.2)
    local finalDist = (hrp.Position - pos).Magnitude

    if finalDist <= 20 then
        if not silent and setStatus then
            setStatus("TP ok" .. (label and (": " .. label) or ""))
        end
        return true
    end

    if not silent and setStatus then
        setStatus("TP bloqueado (dist " .. math.floor(finalDist) .. ")", true)
    end
    return false
end

--==================== COMBATE ====================
-- Lembra o nome da última arma equipada. O jogo costuma desequipar as tools
-- durante/depois de teleportes, então reequipamos a mesma arma antes de atacar.
local function pickBackpackTool()
    local backpack = LP:FindFirstChild("Backpack")
    if not backpack then return nil end

    local tools = {}
    for _, v in ipairs(backpack:GetChildren()) do
        if v:IsA("Tool") then table.insert(tools, v) end
    end
    if #tools == 0 then return nil end

    if State.lastToolName then
        for _, t in ipairs(tools) do
            if t.Name == State.lastToolName then return t end
        end
    end

    -- prefere pelo ToolTip do Blox Fruits
    for _, t in ipairs(tools) do
        local tip = tostring(t.ToolTip)
        if tip == "Melee" or tip == "Sword" or tip == "Blox Fruit" or tip == "Gun" or tip == "Fighting Style" then
            return t
        end
    end

    -- ignora haki/mapa, que não servem para atacar
    for _, t in ipairs(tools) do
        local n = string.lower(t.Name)
        if not string.find(n, "haki", 1, true) and not string.find(n, "map", 1, true) then
            return t
        end
    end

    return tools[1]
end

local function equipWeapon()
    local char = getChar()
    if not char then return nil end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end

    local equipped = char:FindFirstChildOfClass("Tool")

    -- prefere a última arma memorizada (o jogo pode ter equipado outra coisa)
    if State.lastToolName then
        if equipped and equipped.Name == State.lastToolName then
            return equipped
        end
        local backpack = LP:FindFirstChild("Backpack")
        local wanted = backpack and backpack:FindFirstChild(State.lastToolName)
        if wanted and wanted:IsA("Tool") then
            pcall(function() hum:EquipTool(wanted) end)
            task.wait(0.15)
            local nowEq = char:FindFirstChildOfClass("Tool")
            if nowEq then return nowEq end
        end
    end

    if equipped then
        State.lastToolName = equipped.Name
        return equipped
    end

    local chosen = pickBackpackTool()
    if not chosen then return nil end

    pcall(function() hum:EquipTool(chosen) end)
    task.wait(0.15)

    local nowEquipped = char:FindFirstChildOfClass("Tool")
    if not nowEquipped then
        pcall(function() chosen.Parent = char end)
        task.wait(0.15)
        nowEquipped = char:FindFirstChildOfClass("Tool")
    end

    if nowEquipped then State.lastToolName = nowEquipped.Name end
    return nowEquipped or chosen
end

local function attackOnce()
    if not isAlive() then return end
    local char = getChar()
    if not char then return end

    -- reequipa se o jogo tirou a arma
    local tool = equipWeapon()

    if tool then
        pcall(function()
            tool.Enabled = true
            tool:Activate()
        end)
    end

    -- clique virtual como reforço (funciona para melee/algumas armas)
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new(0, 0))
    end)

    -- fallback de executor, quando disponível
    pcall(function()
        if mouse1click then mouse1click() end
    end)
end

local function attackLoop()
    while State.attacking do
        if isAlive() then attackOnce() end
        local delay = State.fastAttack and CONFIG.fastAttackDelay or CONFIG.attackDelay
        task.wait(jitter(delay))
    end
end

local function startAttack()
    if State.attacking then return end
    State.attacking = true
    task.spawn(attackLoop)
end

local function stopAttack()
    State.attacking = false
end

--==================== INIMIGOS ====================
-- Workspace.Enemies guarda apenas mobs/bosses matáveis.
-- NPCs de missão e outras entidades ficam fora dessa pasta.
local function getEnemiesFolder()
    local folder = Workspace:FindFirstChild("Enemies")
    if folder then return folder end
    local ok, found = pcall(function()
        return Workspace:FindFirstChild("Enemies", true)
    end)
    if ok and found then return found end
    return nil
end

local function enemyIsAlive(model)
    if not model or not model.Parent then return false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    local hrp = model:FindFirstChild("HumanoidRootPart")
    return hum ~= nil and hrp ~= nil and hum.Health > 0
end

-- retorna os modelos vivos da pasta Enemies (fallback: Workspace sem jogadores)
local function collectEnemies()
    local list = {}
    local folder = getEnemiesFolder()

    if folder then
        for _, obj in ipairs(folder:GetChildren()) do
            if enemyIsAlive(obj) then table.insert(list, obj) end
        end
    else
        local scanned = 0
        for _, obj in ipairs(Workspace:GetDescendants()) do
            scanned = scanned + 1
            if scanned > CONFIG.maxScan then break end
            if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) and enemyIsAlive(obj) then
                table.insert(list, obj)
            end
        end
    end

    return list
end

local function getEnemies(name)
    if name == "" then return {} end
    local now = os.clock()

    if mobCache.name == name and now - mobCache.time < 1.5 then
        local alive = {}
        for _, m in ipairs(mobCache.list) do
            if enemyIsAlive(m) then table.insert(alive, m) end
        end
        mobCache.list = alive
        return alive
    end

    local list = {}
    for _, obj in ipairs(collectEnemies()) do
        if obj.Name == name then table.insert(list, obj) end
    end

    mobCache = { time = now, name = name, list = list }
    return list
end

local function nearestEnemy(name)
    local hrp = getHRP()
    if not hrp then return nil, math.huge end
    local best, bestDist = nil, math.huge
    for _, mob in ipairs(getEnemies(name)) do
        local mhrp = mob:FindFirstChild("HumanoidRootPart")
        if mhrp then
            local d = (mhrp.Position - hrp.Position).Magnitude
            if d < bestDist then
                best, bestDist = mob, d
            end
        end
    end
    return best, bestDist
end

--==================== NÍVEL DOS MOBS ====================
-- Preenchido com a tabela de quests mais abaixo (nome -> nível).
local MOB_LEVELS = {}

local function parseLevelFromText(text)
    if type(text) ~= "string" then return nil end
    local lv = text:match("[Ll][Vv]%.?%s*(%d+)")
    if lv then return tonumber(lv) end
    lv = text:match("%[(%d+)%]")
    return lv and tonumber(lv)
end

local function readGuiLevel(gui)
    if not gui then return nil end
    for _, d in ipairs(gui:GetDescendants()) do
        if d:IsA("TextLabel") then
            local lv = parseLevelFromText(d.Text)
            if lv then return lv end
        end
    end
    return nil
end

-- Tenta ler o nível do próprio mob; se não achar, usa a tabela de quests.
local function getMobLevel(mob)
    if type(mob) == "string" then return MOB_LEVELS[mob] end
    if not mob then return nil end

    local ok, lvl = pcall(function()
        local attr = mob:GetAttribute("Level")
        if attr then return tonumber(attr) end

        local levelObj = mob:FindFirstChild("Level")
        if levelObj and levelObj:IsA("ValueBase") then
            local v = tonumber(levelObj.Value)
            if v then return v end
        end

        local hum = mob:FindFirstChildOfClass("Humanoid")
        if hum then
            local v = parseLevelFromText(hum.DisplayName)
            if v then return v end
        end

        local vName = parseLevelFromText(mob.Name)
        if vName then return vName end

        local head = mob:FindFirstChild("Head")
        if head then
            local gui = head:FindFirstChildOfClass("BillboardGui")
            local v = readGuiLevel(gui)
            if v then return v end
        end

        local gui2 = mob:FindFirstChildOfClass("BillboardGui")
        local v2 = readGuiLevel(gui2)
        if v2 then return v2 end
        return nil
    end)

    if ok and lvl then return lvl end
    return MOB_LEVELS[mob.Name]
end

-- agrupado por nome. onlyBoss=true -> só bosses; false -> só mobs comuns
local function listEnemies(onlyBoss)
    local map = {}
    for _, obj in ipairs(collectEnemies()) do
        local boss = isBossName(obj.Name)
        if (onlyBoss and boss) or ((not onlyBoss) and not boss) then
            local name = obj.Name
            if not map[name] then
                map[name] = { name = name, count = 0, level = getMobLevel(obj) }
            end
            map[name].count = map[name].count + 1
        end
    end

    local list = {}
    for _, v in pairs(map) do
        table.insert(list, v)
    end
    table.sort(list, function(a, b)
        if (a.level or 0) ~= (b.level or 0) then
            return (a.level or 0) < (b.level or 0)
        end
        return a.name < b.name
    end)
    return list
end

-- escolhe o mob mais forte que o jogador já pode matar (nível <= nível do player)
local function playerLevel()
    local ok, lvl = pcall(function()
        local data = LP:FindFirstChild("Data")
        local level = data and data:FindFirstChild("Level")
        return level and tonumber(level.Value)
    end)
    if ok then return lvl end
    return nil
end

local function bestMobForLevel(list)
    if #list == 0 then return nil end
    local lvl = playerLevel()
    if not lvl then return list[1] end

    local best, bestLevel = nil, -math.huge
    for _, e in ipairs(list) do
        local eLvl = e.level
        if eLvl and eLvl <= lvl and eLvl >= bestLevel then
            best, bestLevel = e, eLvl
        end
    end
    return best or list[1]
end

--==================== FARM ====================
local function settleAndFace(mhrp)
    local char = getChar()
    local hrp = getHRP()
    if not char or not hrp or not mhrp then return end

    pcall(function()
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.PlatformStand = false
            hum.Sit = false
            if hum.WalkSpeed <= 0 then
                hum.WalkSpeed = State.baseWalkSpeed > 0 and State.baseWalkSpeed or 16
            end
            local st = hum:GetState()
            if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.FallingDown then
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end
        end
        hrp.Anchored = false
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        if (mhrp.Position - hrp.Position).Magnitude > 0.1 then
            hrp.CFrame = CFrame.new(hrp.Position, mhrp.Position)
        end
    end)
end

-- aumenta o hitbox do alvo e congela ele (truque comum de farm no Blox Fruits).
-- Isso faz o golpe registrar mesmo se o corpo a corpo estiver um pouco longe.
local function boostTarget(mob)
    if not mob then return end
    local mhrp = mob:FindFirstChild("HumanoidRootPart")
    local mhum = mob:FindFirstChildOfClass("Humanoid")

    if mhrp then
        pcall(function()
            mhrp.CanCollide = false
            mhrp.Size = Vector3.new(20, 20, 20)
        end)
    end

    if mhum then
        pcall(function()
            mhum.PlatformStand = true
            mhum.Sit = true
            mhum.WalkSpeed = 0
            mhum.JumpPower = 0
        end)
    end
end

-- mata o alvo na hora (mesmo método do Kill Aura instantâneo)
local function instantKillMob(mob)
    if not mob or not mob.Parent then return false end
    local hum = mob:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end

    forceSimulationRadius()
    if not AURA.simOk then return false end

    pcall(function()
        if hum.Parent and hum.Health > 0 then
            hum.Health = 0
        end
    end)
    return true
end

-- teleporta até o inimigo (se preciso), para a velocidade e ataca
local function engageEnemy(targetName, range)
    if targetName == "" or not isAlive() then return end

    local mob, dist = nearestEnemy(targetName)
    if not mob then return end
    local mhrp = mob:FindFirstChild("HumanoidRootPart")
    if not mhrp then return end

    boostTarget(mob)

    -- corpo a corpo precisa ficar perto de verdade; range do slider é teto
    local engageRange = math.min(range, 10)
    if dist > engageRange then
        local hrp = getHRP()
        if not hrp then return end
        teleport(mhrp.Position + Vector3.new(0, 3, -3), nil, true, function()
            return not (State.farming or State.bossFarming)
        end)
        if not (State.farming or State.bossFarming) then return end
        task.wait(0.25) -- deixa o servidor registrar a posição antes de atacar
    end

    settleAndFace(mhrp)

    -- puxa o alvo para a frente do player e trava ele (garante o golpe)
    local hrp2 = getHRP()
    if hrp2 then
        pcall(function()
            mhrp.CFrame = hrp2.CFrame * CFrame.new(0, 0, -4)
            mhrp.AssemblyLinearVelocity = Vector3.zero
            mhrp.AssemblyAngularVelocity = Vector3.zero
        end)
    end

    -- mata na hora (farm/raid instantâneo) e usa o ataque como reforço
    if State.instantFarm then
        instantKillMob(mob)
    end

    attackOnce()
end

local function farmLoop()
    while State.farming do
        local ok = pcall(function()
            if not isAlive() then return end
            if State.farmTarget == "" then return end
            engageEnemy(State.farmTarget, CONFIG.farmRange)
        end)

        if not ok then
            if trackError("farm") then
                State.farming = false
                if UI.toggles.autoFarm then UI.toggles.autoFarm.set(false) end
                if setStatus then setStatus("Auto farm desligado (erros repetidos)", true) end
            end
        else
            clearErrors("farm")
        end

        task.wait(jitter(CONFIG.farmDelay))
    end
end

local function startFarm()
    if State.farming then return end
    State.farming = true
    task.spawn(farmLoop)
end

local function stopFarm()
    State.farming = false
end

--==================== BOSS ====================
local function bossLoop()
    while State.bossFarming do
        local ok = pcall(function()
            if not isAlive() then return end
            if State.bossTarget == "" then return end
            engageEnemy(State.bossTarget, CONFIG.bossRange)
        end)

        if not ok then
            if trackError("boss") then
                State.bossFarming = false
                if UI.toggles.autoBoss then UI.toggles.autoBoss.set(false) end
                if setStatus then setStatus("Auto boss desligado (erros repetidos)", true) end
            end
        else
            clearErrors("boss")
        end

        task.wait(jitter(CONFIG.farmDelay))
    end
end

local function startBoss()
    if State.bossFarming then return end
    State.bossFarming = true
    task.spawn(bossLoop)
end

local function stopBoss()
    State.bossFarming = false
end

--==================== ALVOS EXTRAS ====================
-- Frutas ficam no Workspace como Tool (ou Model) com Handle. As frutas que o
-- servidor spawna aparecem como filhos diretos do Workspace e têm "Fruit" no
-- nome; algumas variantes usam só o nome da fruta ("Rocket", "Dragon") ou o
-- atributo OriginalName. A detecção abaixo cobre todos esses casos.
local FRUIT_NAMES = {
    barrier = true, blade = true, blizzard = true, bomb = true, buddha = true,
    chop = true, control = true, creation = true, dark = true, diamond = true,
    door = true, dough = true, dragon = true, eagle = true, falcon = true,
    flame = true, gas = true, ghost = true, gravity = true, ice = true,
    kilo = true, kitsune = true, leopard = true, light = true, lightning = true,
    love = true, magma = true, mammoth = true, mochi = true, pain = true,
    paw = true, phoenix = true, portal = true, quake = true, revive = true,
    rocket = true, rubber = true, rumble = true, sand = true, shadow = true,
    smoke = true, sound = true, spider = true, spike = true, spin = true,
    spirit = true, spring = true, string = true, ["t-rex"] = true, venom = true,
    yeti = true,
}

-- nomes genéricos que NÃO são fruta no chão (ex. prop "Fruit" da Creation)
local FRUIT_BLOCKED = {
    "fruitspawn", "fruitdealer", "fruitnotifier", "fruitgiver", "fruitquest",
    "fruitbasket", "fruitstand", "fruitshop", "fruitmarker", "fruitpoint",
    "fruitlocation", "physicalfruit", "fruitmodel",
}

local function isGenericFruitName(name)
    local n = string.lower(tostring(name)):gsub("[%s%-_]", "")
    if n == "fruit" or n == "fruits" then return true end
    for _, b in ipairs(FRUIT_BLOCKED) do
        if string.find(n, b, 1, true) then return true end
    end
    return false
end

local function isFruitTool(obj)
    if not obj then return false end
    local isTool = obj:IsA("Tool")
    local isModel = obj:IsA("Model")
    if not (isTool or isModel) then return false end

    -- fruta no chão tem um Handle como FILHO DIRETO. Não usamos descendente:
    -- ilhas são Models grandes cheias de partes e eram confundidas com fruta
    -- (ex. "Ice Castle" por causa de "Ice", "Magma Village" por "Magma").
    local handle = obj:FindFirstChild("Handle")
    if not handle or not handle:IsA("BasePart") then return false end

    local name = tostring(obj.Name)
    local lower = string.lower(name)
    if isGenericFruitName(name) then return false end

    -- 1) Tool de fruta equipável
    if isTool then
        local okTip, tip = pcall(function() return obj.ToolTip end)
        if okTip and tip == "Blox Fruit" then return true end
    end

    -- 2) atributo OriginalName (ex. "Rocket-Rocket Fruit")
    local okOrig, original = pcall(function() return obj:GetAttribute("OriginalName") end)
    if okOrig and type(original) == "string" and #original > 0 then
        local orig = tostring(original)
        if not isGenericFruitName(orig) then
            local ol = string.lower(orig)
            if string.find(ol, "fruit", 1, true) then return true end
            local obase = ol:match("^([^%-%s]+)") or ol
            if (string.find(orig, "-", 1, true) or not string.find(orig, "%s")) and FRUIT_NAMES[obase] then
                return true
            end
        end
    end

    -- 3) "Fruit" com algo antes (ex. "Rocket Fruit"); rejeita só "Fruit"
    local fs = string.find(lower, "fruit", 1, true)
    if fs then
        local prefix = string.sub(lower, 1, fs - 1):gsub("[%s%-_%d]", "")
        if #prefix > 0 then return true end
    end

    -- 4) nome no formato "Rocket-Rocket" ou o nome exato da fruta ("Rocket").
    -- Nome composto ("Ice Castle") NÃO conta: senão ilhas entram na lista.
    local base = string.lower(name:match("^([^%-%s]+)") or name)
    if FRUIT_NAMES[base] then
        if string.find(name, "-", 1, true) then return true end
        local rest = string.sub(lower, #base + 1)
        if rest == "" then return true end
    end

    return false
end

local function collectFruits()
    local list = {}
    local seen = {}

    local function add(obj)
        if obj and not seen[obj] and isFruitTool(obj) then
            seen[obj] = true
            table.insert(list, obj)
        end
    end

    for _, obj in ipairs(Workspace:GetChildren()) do
        add(obj)
        -- frutas spawnadas podem ficar em uma pasta (Fruits/FruitSpawn/...).
        -- Só entramos em pastas com nome relacionado para não varrer o mapa.
        if obj:IsA("Folder") then
            local n = string.lower(obj.Name)
            if string.find(n, "fruit", 1, true) or string.find(n, "spawn", 1, true) then
                for _, inner in ipairs(obj:GetChildren()) do add(inner) end
            end
        end
    end
    return list
end

local function collectChests()
    local list = {}
    local scanned = 0
    for _, obj in ipairs(Workspace:GetDescendants()) do
        scanned = scanned + 1
        if scanned > CONFIG.maxScan then break end
        local n = obj.Name
        if string.find(n, "Chest", 1, true) or string.find(n, "chest", 1, true) then
            if obj:IsA("BasePart") or obj:IsA("Model") then
                table.insert(list, obj)
            end
        end
    end
    return list
end

local function fruitPosition(fruit)
    local handle = fruit and fruit:FindFirstChild("Handle")
    if handle then return handle.Position end
    local part = fruit and fruit:FindFirstChildWhichIsA("BasePart", true)
    return part and part.Position or nil
end

-- cache curto: ESP roda a cada 0.25s e não precisa reescanear o mapa inteiro
local fruitCache = { time = 0, list = {} }
local function getFruitsCached()
    local now = os.clock()
    if now - fruitCache.time < 0.5 then return fruitCache.list end
    fruitCache = { time = now, list = collectFruits() }
    return fruitCache.list
end

--==================== GUARDAR FRUTAS ====================
-- O jogo guarda 1 cópia de cada fruta por padrão; cada "+1 Fruit Storage"
-- adiciona um slot para todas as frutas. O cliente não expõe esse limite, então
-- o usuário ajusta "slots por fruta" na UI. A quantidade guardada vem de
-- getInventoryFruits (uma entrada por cópia). Se o servidor recusar mesmo com
-- vaga na conta, o hub reduz a capacidade aprendida.
local function fruitBaseKey(name)
    local s = tostring(name or "")
    s = s:gsub("%s*[Ff][Rr][Uu][Ii][Tt]%s*$", "")
    s = string.lower(s)
    return (s:match("^([^%-:]+)") or s)
end

local function fruitDisplayName(tool)
    local s = tostring(tool and tool.Name or "?")
    s = s:gsub("%s*[Ff][Rr][Uu][Ii][Tt]%s*$", "")
    s = s:match("^([^%-:]+)") or s
    return s
end

local function fruitStoreName(tool)
    local name
    local ok, orig = pcall(function() return tool:GetAttribute("OriginalName") end)
    if ok and type(orig) == "string" and #orig > 0 then
        name = orig
    else
        name = tostring(tool.Name)
    end
    name = name:gsub("%s*[Ff][Rr][Uu][Ii][Tt]%s*$", "")
    if string.find(name, "-", 1, true) then return name end
    local base = name:match("^([^%-:]+)") or name
    return base .. "-" .. base
end

-- Só conta ferramentas que realmente são fruta na mochila. Evita pegar
-- "Dragon Talon" (melee) ou outros itens com nome de fruta.
local function isBackpackFruit(tool)
    if not tool or not tool:IsA("Tool") then return false end
    local name = tostring(tool.Name)
    if isGenericFruitName(name) then return false end

    local okTip, tip = pcall(function() return tool.ToolTip end)
    if okTip and tip == "Blox Fruit" then return true end
    if okTip and tip == "" then
        -- algumas frutas no chão/mochila vêm com ToolTip vazio (ex. "Rocket-Rocket")
        local tbase = string.lower(name:match("^([^%-%s]+)") or name)
        if FRUIT_NAMES[tbase] and (string.find(name, "-", 1, true) or not string.find(name, "%s")) then
            return true
        end
    end

    local okOrig, orig = pcall(function() return tool:GetAttribute("OriginalName") end)
    if okOrig and type(orig) == "string" and #orig > 0 and not isGenericFruitName(orig) then
        local ol = string.lower(orig)
        if string.find(ol, "fruit", 1, true) then return true end
        local obase = ol:match("^([^%-%s]+)") or ol
        if string.find(orig, "-", 1, true) and FRUIT_NAMES[obase] then return true end
    end

    if string.find(string.lower(name), "fruit", 1, true) then return true end
    local base = string.lower(name:match("^([^%-%s]+)") or name)
    if string.find(name, "-", 1, true) and FRUIT_NAMES[base] then return true end
    return false
end

local fruitInvCache = { time = 0, counts = nil }

local function getStoredFruitCounts(force)
    local now = os.clock()
    if not force and fruitInvCache.counts and now - fruitInvCache.time < 2 then
        return fruitInvCache.counts
    end
    local ok, inv = pcall(function()
        return ReplicatedStorage.Remotes.CommF_:InvokeServer("getInventoryFruits")
    end)
    if not ok or type(inv) ~= "table" then
        fruitInvCache = { time = now, counts = nil }
        return nil
    end

    local counts = {}
    for k, item in pairs(inv) do
        local n = nil
        local amount = 1
        if type(item) == "table" then
            n = item.Name or item.name or item[1]
            if not n and type(k) == "string" then n = k end
            if tonumber(item.Count) then
                amount = math.max(1, math.floor(tonumber(item.Count)))
            end
        elseif type(item) == "string" then
            n = item
        elseif type(item) == "number" and type(k) == "string" then
            -- formato mapa: { ["Rocket-Rocket"] = 2 }
            n = k
            amount = math.max(1, math.floor(item))
        end
        if type(n) == "table" then n = n[1] end
        if type(n) == "string" then
            local key = fruitBaseKey(n)
            counts[key] = (counts[key] or 0) + amount
        end
    end
    fruitInvCache = { time = now, counts = counts }
    return counts
end

-- tenta guardar e confirma se a ferramenta saiu da mochila
local function tryStoreFruit(tool)
    local backpack = LP:FindFirstChild("Backpack")
    if not backpack or tool.Parent ~= backpack then return "fail" end
    local storeName = fruitStoreName(tool)

    pcall(function()
        ReplicatedStorage.Remotes.CommF_:InvokeServer("StoreFruit", storeName, tool)
    end)
    task.wait(0.45)
    if tool.Parent ~= backpack then return "stored" end

    -- algumas versões aceitam só o nome
    pcall(function()
        ReplicatedStorage.Remotes.CommF_:InvokeServer("StoreFruit", storeName)
    end)
    task.wait(0.35)
    if tool.Parent ~= backpack then return "stored" end
    return "fail"
end

local function fruitStorePass(manual)
    if State.fruitStoreBusy then return 0, 0, 0 end
    State.fruitStoreBusy = true

    local stored, skipped, failed = 0, 0, 0
    local backpack = LP:FindFirstChild("Backpack")

    -- primeiro monta a lista: sem fruta na mochila nem chama o remote
    local fruits = {}
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if isBackpackFruit(tool) then
                table.insert(fruits, tool)
            end
        end
    end

    local capacity = math.max(1, math.floor(tonumber(State.fruitStoreCapacity) or 1))
    local counts = #fruits > 0 and getStoredFruitCounts(true) or nil

    for _, tool in ipairs(fruits) do
        if tool.Parent == backpack then
            local key = fruitBaseKey(tool.Name)
            local have = counts and (counts[key] or 0) or nil

            if have and have >= capacity then
                skipped = skipped + 1
                if not State.fruitStoreWarned[key] then
                    State.fruitStoreWarned[key] = true
                    notify("Sem espaço para " .. fruitDisplayName(tool) .. " (" .. have .. "/" .. capacity .. ")", 5)
                end
            else
                local result = tryStoreFruit(tool)
                if result == "stored" then
                    stored = stored + 1
                    if counts then counts[key] = (counts[key] or 0) + 1 end
                    State.fruitStoreWarned[key] = nil
                    local nowHave = counts and counts[key] or "?"
                    notify("Fruta guardada: " .. fruitDisplayName(tool) .. " (" .. tostring(nowHave) .. "/" .. capacity .. ")", 4)
                else
                    failed = failed + 1
                    -- pensávamos que havia vaga, mas o servidor recusou:
                    -- aprende a capacidade real para não tentar de novo à toa
                    if have and have < capacity then
                        State.fruitStoreCapacity = math.max(1, have)
                        if UI.sliders.fruitStoreCapacity then
                            UI.sliders.fruitStoreCapacity.set(State.fruitStoreCapacity)
                        end
                    end
                    if not State.fruitStoreWarned[key] then
                        State.fruitStoreWarned[key] = true
                        notify("Não consegui guardar " .. fruitDisplayName(tool) .. " (sem espaço)", 5)
                    end
                end
            end
        end
    end

    State.fruitStoreBusy = false
    if manual and setStatus then
        setStatus("Guardar frutas: " .. stored .. " guardada(s), " .. skipped .. " sem espaço, " .. failed .. " falhou")
    end
    return stored, skipped, failed
end

local function fruitStoreLoop()
    if State.fruitStoreRunning then return end
    State.fruitStoreRunning = true
    while State.fruitAutoStore do
        pcall(function() fruitStorePass(false) end)
        task.wait(1.5)
    end
    State.fruitStoreRunning = false
end

local chestCache = { time = 0, list = {} }
local function getChestsCached()
    local now = os.clock()
    if now - chestCache.time < 2.0 then return chestCache.list end
    chestCache = { time = now, list = collectChests() }
    return chestCache.list
end

--==================== ESP ====================
local function clearESP()
    for _, entry in pairs(State.espCache) do
        if entry.hl then pcall(function() entry.hl:Destroy() end) end
        if entry.bb then pcall(function() entry.bb:Destroy() end) end
    end
    State.espCache = {}
end

local function addESP(obj, color, labelText, offsetY)
    if not obj or not obj.Parent then return end
    local entry = State.espCache[obj]

    if not entry then
        entry = {}

        -- Tool não é Model/BasePart: o Highlight precisa apontar para o Handle
        local adorneeObj = obj
        if obj:IsA("Tool") then
            adorneeObj = obj:FindFirstChild("Handle") or obj
        end

        local hl = Instance.new("Highlight")
        hl.Name = "HubESP"
        hl.FillColor = color
        hl.OutlineColor = color
        hl.FillTransparency = 0.55
        hl.OutlineTransparency = 0.1
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Adornee = adorneeObj
        hl.Parent = adorneeObj
        entry.hl = hl

        local adorneePart = obj:FindFirstChild("HumanoidRootPart")
            or obj:FindFirstChild("Handle")
            or obj:FindFirstChildWhichIsA("BasePart", true)

        if adorneePart then
            local bb = Instance.new("BillboardGui")
            bb.Name = "HubESPName"
            bb.Size = UDim2.new(0, 180, 0, 18)
            bb.StudsOffset = Vector3.new(0, offsetY or 3, 0)
            bb.AlwaysOnTop = true
            bb.Adornee = adorneePart
            bb.Parent = adorneePart

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, 0, 1, 0)
            lbl.BackgroundTransparency = 1
            lbl.TextColor3 = color
            lbl.TextSize = 12
            lbl.Font = Enum.Font.GothamBold
            lbl.TextStrokeTransparency = 0.4
            lbl.Text = labelText or obj.Name
            lbl.Parent = bb

            entry.bb = bb
            entry.lbl = lbl
        end

        State.espCache[obj] = entry
    elseif entry.lbl then
        entry.lbl.Text = labelText or obj.Name
    end
end

local function espActive()
    return State.espPlayers or State.espFruits or State.espChests or State.espBosses
end

local function espLoop()
    while espActive() do
        pcall(function()
            local hrp = getHRP()
            local origin = hrp and hrp.Position or Vector3.zero
            local wanted = {}

            if State.espPlayers then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LP and p.Character then
                        local chr = p.Character
                        local phrp = chr:FindFirstChild("HumanoidRootPart")
                        local hum = chr:FindFirstChildOfClass("Humanoid")
                        if phrp and hum and hum.Health > 0 then
                            local d = (phrp.Position - origin).Magnitude
                            if d <= CONFIG.esp.maxDistance then
                                wanted[chr] = {
                                    color = CONFIG.esp.playerColor,
                                    text = p.Name .. " [" .. math.floor(d) .. "]",
                                    offset = 3,
                                }
                            end
                        end
                    end
                end
            end

            if State.espBosses then
                local folder = getEnemiesFolder()
                if folder then
                    for _, mob in ipairs(folder:GetChildren()) do
                        if isBossName(mob.Name) and enemyIsAlive(mob) then
                            local mhrp = mob:FindFirstChild("HumanoidRootPart")
                            local d = mhrp and (mhrp.Position - origin).Magnitude or 0
                            if d <= CONFIG.esp.maxDistance then
                                wanted[mob] = {
                                    color = CONFIG.esp.bossColor,
                                    text = mob.Name .. " [" .. math.floor(d) .. "]",
                                    offset = 3,
                                }
                            end
                        end
                    end
                end
            end

            if State.espFruits then
                for _, fruit in ipairs(getFruitsCached()) do
                    if fruit.Parent then
                        local pos = fruitPosition(fruit)
                        local d = pos and (pos - origin).Magnitude or 0
                        if d <= CONFIG.esp.maxDistance then
                            wanted[fruit] = {
                                color = CONFIG.esp.fruitColor,
                                text = fruit.Name,
                                offset = 2,
                            }
                        end
                    end
                end
            end

            if State.espChests then
                for _, chest in ipairs(getChestsCached()) do
                    if chest.Parent then
                        local pos = nil
                        if chest:IsA("BasePart") then
                            pos = chest.Position
                        else
                            local part = chest:FindFirstChildWhichIsA("BasePart", true)
                            pos = part and part.Position or nil
                        end
                        local d = pos and (pos - origin).Magnitude or 0
                        if pos and d <= CONFIG.esp.maxDistance then
                            wanted[chest] = {
                                color = CONFIG.esp.chestColor,
                                text = "Bau [" .. math.floor(d) .. "]",
                                offset = 2,
                            }
                        end
                    end
                end
            end

            for obj, entry in pairs(State.espCache) do
                if not wanted[obj] or not obj.Parent then
                    if entry.hl then pcall(function() entry.hl:Destroy() end) end
                    if entry.bb then pcall(function() entry.bb:Destroy() end) end
                    State.espCache[obj] = nil
                end
            end

            for obj, info in pairs(wanted) do
                addESP(obj, info.color, info.text, info.offset)
            end
        end)

        task.wait(CONFIG.esp.refresh)
    end

    State.espRunning = false
    clearESP()
end

local function syncESP()
    if espActive() and not State.espRunning then
        State.espRunning = true
        task.spawn(espLoop)
    end
end

--==================== FRUTAS ====================
-- Timer estimado de spawn: o jogo só avisa depois que a fruta nasce
-- (Remotes.RadarNotify). O spawn natural é a cada 60 min (45 min no fim de
-- semana) e a fruta some após 20 min. Guardamos o intervalo entre spawns vistos
-- para calibrar a estimativa. Previsão exata antes do spawn não existe no cliente.
local FRUIT_SPAWN_WEEKDAY = 3600 -- 60 min
local FRUIT_SPAWN_WEEKEND = 2700 -- 45 min

local function fruitDefaultInterval()
    local ok, t = pcall(function() return os.date("*t") end)
    if ok and type(t) == "table" and (t.wday == 1 or t.wday == 7) then
        return FRUIT_SPAWN_WEEKEND
    end
    return FRUIT_SPAWN_WEEKDAY
end

local function fruitTimeText(sec)
    sec = math.max(0, math.floor(sec or 0))
    local m = math.floor(sec / 60)
    local s = sec % 60
    if m > 0 then return m .. "m " .. s .. "s" end
    return s .. "s"
end

local function updateFruitSpawnLabel()
    if not UI.fruitSpawnLabel then return end
    local last = State.fruitSpawnLast
    if not last then
        UI.fruitSpawnLabel.Text = "Spawn: aguardando uma fruta para calibrar o timer"
        return
    end
    local elapsed = os.clock() - last
    local estimate = State.fruitSpawnEstimate or fruitDefaultInterval()
    local remaining = estimate - elapsed
    local n = #State.fruitSpawnIntervals
    local suffix
    if State.fruitSpawnApprox then
        suffix = " · aproximado (fruta já no chão)"
    elseif n > 0 then
        suffix = " · média de " .. n .. " spawn" .. (n > 1 and "s" or "")
    else
        suffix = " · estimado"
    end
    if remaining > 0 then
        local text = "Spawn: ~" .. fruitTimeText(remaining) .. " (última há " .. fruitTimeText(elapsed) .. ")"
        if State.fruitSpawnApprox then
            text = text .. " · aprox."
        elseif n > 0 then
            text = text .. " · média " .. n
        else
            text = text .. " · estimado"
        end
        UI.fruitSpawnLabel.Text = text
    else
        UI.fruitSpawnLabel.Text = "Spawn: iminente (última há " .. fruitTimeText(elapsed) .. ")" .. suffix
    end
end

local function noteFruitSpawn(now)
    now = now or os.clock()
    if State.fruitSpawnLast then
        local delta = now - State.fruitSpawnLast
        if delta >= 120 and delta <= 5400 then
            table.insert(State.fruitSpawnIntervals, delta)
            while #State.fruitSpawnIntervals > 10 do
                table.remove(State.fruitSpawnIntervals, 1)
            end
            local sum = 0
            for _, v in ipairs(State.fruitSpawnIntervals) do sum = sum + v end
            State.fruitSpawnEstimate = sum / #State.fruitSpawnIntervals
        end
    end
    State.fruitSpawnLast = now
    updateFruitSpawnLabel()
end

local function setupFruitRadar()
    if State.fruitRadarConn then return end
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local radar = remotes and remotes:FindFirstChild("RadarNotify")
    if not radar then return end

    State.fruitRadarConn = radar.OnClientEvent:Connect(function(kind, pos)
        if not State.fruitNotify then return end
        if kind == "Enabled" then return end
        local now = os.clock()
        State.fruitRadarGrace = now
        State.fruitSpawnApprox = false
        noteFruitSpawn(now)

        local extra = ""
        local hrp = getHRP()
        if hrp and typeof(pos) == "Vector3" then
            extra = " (" .. math.floor((pos - hrp.Position).Magnitude) .. "m)"
        end
        notify("Radar: uma fruta spawnou no servidor!" .. extra, 6)
    end)
end

local function fruitNotifyLoop()
    while State.fruitNotify do
        pcall(function()
            for obj in pairs(State.seenFruits) do
                if not obj.Parent then State.seenFruits[obj] = nil end
            end

            local firstPass = not State.fruitNotifyStarted
            local newFruit = false
            local seenCount = 0
            for _, fruit in ipairs(collectFruits()) do
                seenCount = seenCount + 1
                if not State.seenFruits[fruit] then
                    State.seenFruits[fruit] = true
                    if not firstPass then
                        newFruit = true
                        if os.clock() - (State.fruitRadarGrace or 0) > 5 then
                            notify("Fruta encontrada: " .. fruit.Name, 5)
                        end
                    end
                end
            end

            if newFruit then
                State.fruitSpawnApprox = false
                noteFruitSpawn()
            elseif firstPass and seenCount > 0 and not State.fruitSpawnLast then
                -- já havia fruta no chão: chuta o início do ciclo como agora
                State.fruitSpawnApprox = true
                noteFruitSpawn()
            end
            State.fruitNotifyStarted = true
            updateFruitSpawnLabel()
        end)
        task.wait(2)
    end
end

--==================== AUTO QUEST ====================
-- Tabelas por mar. O mob precisa existir em Workspace.Enemies.
local QUESTS = {
    [1] = {
        { level = 1,   mob = "Bandit",              remote = "BanditQuest1",   questId = 1 },
        { level = 10,  mob = "Monkey",              remote = "JungleQuest",    questId = 1 },
        { level = 15,  mob = "Gorilla",             remote = "JungleQuest",    questId = 2 },
        { level = 30,  mob = "Pirate",              remote = "BuggyQuest1",    questId = 1 },
        { level = 40,  mob = "Brute",               remote = "BuggyQuest1",    questId = 2 },
        { level = 60,  mob = "Desert Bandit",       remote = "DesertQuest",    questId = 1 },
        { level = 75,  mob = "Desert Officer",      remote = "DesertQuest",    questId = 2 },
        { level = 90,  mob = "Snow Bandit",         remote = "SnowQuest",      questId = 1 },
        { level = 100, mob = "Snowman",             remote = "SnowQuest",      questId = 2 },
        { level = 120, mob = "Chief Petty Officer", remote = "MarineQuest2",   questId = 1 },
        { level = 130, mob = "Vice Admiral",        remote = "MarineQuest2",   questId = 2 },
        { level = 150, mob = "Sky Bandit",          remote = "SkyQuest",       questId = 1 },
        { level = 175, mob = "Dark Master",         remote = "SkyQuest",       questId = 2 },
        { level = 190, mob = "Prisoner",            remote = "PrisonerQuest",  questId = 1 },
        { level = 210, mob = "Dangerous Prisoner",  remote = "PrisonerQuest",  questId = 2 },
        { level = 250, mob = "Toga Warrior",        remote = "ColosseumQuest", questId = 1 },
        { level = 275, mob = "Gladiator",           remote = "ColosseumQuest", questId = 2 },
        { level = 300, mob = "Military Soldier",    remote = "MagmaQuest",     questId = 1 },
        { level = 325, mob = "Military Spy",        remote = "MagmaQuest",     questId = 2 },
        { level = 375, mob = "Fishman Warrior",     remote = "FishmanQuest",   questId = 1 },
        { level = 400, mob = "Fishman Commando",    remote = "FishmanQuest",   questId = 2 },
        { level = 450, mob = "God's Guard",         remote = "SkyExp1Quest",   questId = 1 },
        { level = 475, mob = "Shanda",              remote = "SkyExp1Quest",   questId = 2 },
        { level = 525, mob = "Royal Squad",         remote = "SkyExp2Quest",   questId = 1 },
        { level = 550, mob = "Royal Soldier",       remote = "SkyExp2Quest",   questId = 2 },
        { level = 625, mob = "Galley Pirate",       remote = "FountainQuest",  questId = 1 },
        { level = 650, mob = "Galley Captain",      remote = "FountainQuest",  questId = 2 },
    },
    [2] = {
        { level = 700,  mob = "Raider",             remote = "Area1Quest",        questId = 1 },
        { level = 725,  mob = "Mercenary",          remote = "Area1Quest",        questId = 2 },
        { level = 775,  mob = "Swan Pirate",        remote = "Area2Quest",        questId = 1 },
        { level = 800,  mob = "Factory Staff",      remote = "Area2Quest",        questId = 2 },
        { level = 875,  mob = "Marine Lieutenant",  remote = "MarineQuest3",      questId = 1 },
        { level = 900,  mob = "Marine Captain",     remote = "MarineQuest3",      questId = 2 },
        { level = 950,  mob = "Zombie",             remote = "ZombieQuest",       questId = 1 },
        { level = 975,  mob = "Vampire",            remote = "ZombieQuest",       questId = 2 },
        { level = 1000, mob = "Snow Trooper",       remote = "SnowMountainQuest", questId = 1 },
        { level = 1050, mob = "Winter Warrior",     remote = "SnowMountainQuest", questId = 2 },
        { level = 1100, mob = "Lab Subordinate",    remote = "IceSideQuest",      questId = 1 },
        { level = 1125, mob = "Horned Warrior",     remote = "IceSideQuest",      questId = 2 },
        { level = 1175, mob = "Magma Ninja",        remote = "FireSideQuest",     questId = 1 },
        { level = 1200, mob = "Lava Pirate",        remote = "FireSideQuest",     questId = 2 },
        { level = 1250, mob = "Ship Deckhand",      remote = "ShipQuest1",        questId = 1 },
        { level = 1275, mob = "Ship Engineer",      remote = "ShipQuest1",        questId = 2 },
        { level = 1300, mob = "Ship Steward",       remote = "ShipQuest2",        questId = 1 },
        { level = 1325, mob = "Ship Officer",       remote = "ShipQuest2",        questId = 2 },
        { level = 1350, mob = "Arctic Warrior",     remote = "FrostQuest",        questId = 1 },
        { level = 1375, mob = "Snow Lurker",        remote = "FrostQuest",        questId = 2 },
        { level = 1425, mob = "Sea Soldier",        remote = "ForgottenQuest",    questId = 1 },
        { level = 1450, mob = "Water Fighter",      remote = "ForgottenQuest",    questId = 2 },
    },
    [3] = {
        { level = 1500, mob = "Pirate Millionaire",    remote = "PiratePortQuest",     questId = 1 },
        { level = 1525, mob = "Pistol Billionaire",    remote = "PiratePortQuest",     questId = 2 },
        { level = 1575, mob = "Dragon Crew Warrior",   remote = "DragonCrewQuest",     questId = 1 },
        { level = 1700, mob = "Marine Commodore",      remote = "VenomCrewQuest",      questId = 4 },
        { level = 1725, mob = "Marine Rear Admiral",   remote = "VenomCrewQuest",      questId = 5 },
        { level = 1775, mob = "Fishman Raider",        remote = "VenomCrewQuest",      questId = 7 },
        { level = 1800, mob = "Fishman Captain",       remote = "VenomCrewQuest",      questId = 8 },
        { level = 1825, mob = "Forest Pirate",         remote = "VenomCrewQuest",      questId = 9 },
        { level = 1850, mob = "Mythological Pirate",   remote = "VenomCrewQuest",      questId = 10 },
        { level = 1900, mob = "Jungle Pirate",         remote = "VenomCrewQuest",      questId = 12 },
        { level = 1925, mob = "Musketeer Pirate",      remote = "VenomCrewQuest",      questId = 13 },
        { level = 1975, mob = "Reborn Skeleton",       remote = "HauntedQuest1",       questId = 1 },
        { level = 2000, mob = "Living Zombie",         remote = "HauntedQuest1",       questId = 2 },
        { level = 2050, mob = "Posessed Mummy",        remote = "HauntedQuest2",       questId = 2 },
        { level = 2075, mob = "Peanut Scout",          remote = "NutsIslandQuest",     questId = 1 },
        { level = 2100, mob = "Peanut President",      remote = "NutsIslandQuest",     questId = 2 },
        { level = 2125, mob = "Ice Cream Chef",        remote = "IceCreamIslandQuest", questId = 1 },
        { level = 2150, mob = "Ice Cream Commander",   remote = "IceCreamIslandQuest", questId = 2 },
        { level = 2250, mob = "Baking Staff",          remote = "CakeQuest2",          questId = 1 },
        { level = 2275, mob = "Head Baker",            remote = "CakeQuest2",          questId = 2 },
        { level = 2300, mob = "Cocoa Warrior",         remote = "ChocQuest1",          questId = 1 },
        { level = 2325, mob = "Chocolate Bar Battler", remote = "ChocQuest1",          questId = 2 },
        { level = 2350, mob = "Sweet Thief",           remote = "ChocQuest2",          questId = 1 },
        { level = 2375, mob = "Candy Rebel",           remote = "ChocQuest2",          questId = 2 },
        { level = 2400, mob = "Candy Pirate",          remote = "CandyQuest1",         questId = 1 },
        { level = 2425, mob = "Snow Demon",            remote = "CandyQuest1",         questId = 2 },
        { level = 2450, mob = "Isle Outlaw",           remote = "TikiQuest1",          questId = 1 },
        { level = 2475, mob = "Island Boy",            remote = "TikiQuest1",          questId = 2 },
        { level = 2500, mob = "Sun-kissed Warrior",    remote = "TikiQuest2",          questId = 1 },
        { level = 2525, mob = "Isle Champion",         remote = "TikiQuest2",          questId = 2 },
        { level = 2550, mob = "Serpent Hunter",        remote = "TikiQuest3",          questId = 1 },
        { level = 2575, mob = "Skull Slayer",          remote = "TikiQuest3",          questId = 2 },
        { level = 2600, mob = "Reef Bandit",           remote = "SubmergedQuest1",     questId = 1 },
        { level = 2625, mob = "Coral Pirate",          remote = "SubmergedQuest1",     questId = 2 },
        { level = 2650, mob = "Sea Chanter",           remote = "SubmergedQuest2",     questId = 1 },
        { level = 2675, mob = "Ocean Prophet",         remote = "SubmergedQuest2",     questId = 2 },
        { level = 2700, mob = "Grand Devotee",         remote = "SubmergedQuest3",     questId = 2 },
    },
}

local function questListForSea()
    local sea = CURRENT_SEA or 1
    return QUESTS[sea] or QUESTS[1]
end

-- mapa nome -> nível, usado na lista de mobs (fallback quando o jogo não expõe)
for _, seaList in pairs(QUESTS) do
    for _, q in ipairs(seaList) do
        local current = MOB_LEVELS[q.mob]
        if current == nil or q.level < current then
            MOB_LEVELS[q.mob] = q.level
        end
    end
end

local function getLevel()
    local ok, lvl = pcall(function()
        local data = LP:FindFirstChild("Data")
        local level = data and data:FindFirstChild("Level")
        return level and tonumber(level.Value)
    end)
    if ok and lvl then return lvl end
    return nil
end

local function pickQuest()
    local lvl = getLevel()
    if not lvl then return nil end
    local list = questListForSea()
    local best = list[1]
    for _, q in ipairs(list) do
        if lvl >= q.level then best = q end
    end
    return best
end

local function startQuest(q)
    if not q then return false end
    local ok = fireRemote("CommF_", "StartQuest", q.remote, q.questId)
    if ok then
        State.farmTarget = q.mob
        State.farmTargetLevel = q.level
        if UI.targetLabel then
            UI.targetLabel.Text = "Alvo: " .. q.mob .. "  [Lv. " .. tostring(q.level) .. "] (quest)"
        end
    end
    return ok
end

local function questLoop()
    while State.autoQuest do
        task.wait(2)
        local ok = pcall(function()
            local q = pickQuest()
            if not q then return end
            local key = q.remote .. ":" .. tostring(q.questId)
            if key ~= State.questKey then
                State.questKey = key
                startQuest(q)
                if not State.farming then startFarm() end
                if setStatus then setStatus("Auto quest: " .. q.mob) end
            end
        end)

        if not ok then
            if trackError("quest") then
                State.autoQuest = false
                if UI.toggles.autoQuest then UI.toggles.autoQuest.set(false) end
                if setStatus then setStatus("Auto quest desligado (erros)", true) end
            end
        else
            clearErrors("quest")
        end
    end
end

--==================== RAID ====================
-- Auto Raid completo (método usado em hubs públicos, ex. Sankeurr/nyannos):
-- compra/equipa o Microchip, vai até o botão da raid, dispara os prompts e
-- limpa as ondas. Durante a raid o personagem fica pairando (BodyPosition)
-- acima do centro da ilha, alto o bastante para os mobs não acertarem, e mata
-- na hora tudo o que aparece no raio — sem precisar atacar.

local RAID_HOVER_HEIGHT = 55   -- studs acima do centro da ilha
local RAID_KILL_RADIUS = 450   -- raio de morte ao redor do centro da ilha
local RAID_WAVE_GRACE = 6      -- segundos sem mobs antes de ir para a próxima ilha

local function isRaidChip(t)
    if not t or not t:IsA("Tool") then return false end
    if t.Name:find("Microchip") then return true end
    local ok, original = pcall(function() return t:GetAttribute("OriginalName") end)
    return ok and original ~= nil and tostring(original):find("Microchip") ~= nil
end

local function findRaidChip()
    local char = getChar()
    local pools = { char, LP:FindFirstChild("Backpack") }
    for _, pool in ipairs(pools) do
        if pool then
            for _, t in ipairs(pool:GetChildren()) do
                if isRaidChip(t) then return t end
            end
        end
    end
    return nil
end

local function raidChipEquipped()
    local char = getChar()
    if not char then return false end
    for _, t in ipairs(char:GetChildren()) do
        if isRaidChip(t) then return true end
    end
    return false
end

local function equipRaidChip()
    if raidChipEquipped() then return true end
    local char = getChar()
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local chip = findRaidChip()
    if not (hum and chip) then return false end

    for _ = 1, 4 do
        pcall(function() hum:EquipTool(chip) end)
        if not raidChipEquipped() and chip.Parent ~= char then
            pcall(function() chip.Parent = char end)
        end
        task.wait(0.15)
        if raidChipEquipped() then return true end
    end
    return raidChipEquipped()
end

local function raidTimerVisible()
    local ok, visible = pcall(function()
        local main = LP.PlayerGui:FindFirstChild("Main")
        local hud = main and main:FindFirstChild("TopHUDList")
        local timer = hud and hud:FindFirstChild("RaidTimer")
        return timer and timer.Visible == true
    end)
    return ok and visible == true
end

-- Mantém o personagem parado no ar (pairando) em uma posição.
-- Usa BodyPosition para segurar o HRP, sem precisar de fly.
local function raidSetHover(pos)
    local hrp = getHRP()
    local hum = getHum()
    if not hrp or not pos then return false end

    local old = hrp:FindFirstChild("PrismaRaidHover")
    if old and old:IsA("BodyPosition") then
        old.Position = pos
        return true
    end
    if old then pcall(function() old:Destroy() end) end

    if hum then
        pcall(function()
            hum.PlatformStand = true
            hum.Sit = false
        end)
    end

    local bp = Instance.new("BodyPosition")
    bp.Name = "PrismaRaidHover"
    bp.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bp.P = 10000
    bp.D = 1000
    bp.Position = pos
    bp.Parent = hrp
    return true
end

local function raidStopHover()
    local hrp = getHRP()
    if hrp then
        local bp = hrp:FindFirstChild("PrismaRaidHover")
        if bp then pcall(function() bp:Destroy() end) end
    end
    if not State.fly then
        local hum = getHum()
        if hum then pcall(function() hum.PlatformStand = false end) end
    end
end

local function raidLocations()
    local worldOrigin = Workspace:FindFirstChild("_WorldOrigin")
    return worldOrigin and worldOrigin:FindFirstChild("Locations")
end

local function raidIslandPart(idx)
    local locations = raidLocations()
    return locations and locations:FindFirstChild("Island " .. tostring(idx))
end

-- ilha mais próxima do personagem (só para sincronizar no começo da raid)
local function raidCurrentIsland()
    local locations = raidLocations()
    local hrp = getHRP()
    if not (locations and hrp) then return nil end

    local bestIdx, bestDist = nil, math.huge
    for i = 1, 5 do
        local island = locations:FindFirstChild("Island " .. i)
        if island then
            local d = (hrp.Position - island.Position).Magnitude
            if d < bestDist then
                bestDist = d
                bestIdx = i
            end
        end
    end
    return bestIdx
end

-- mobs vivos ao redor de um ponto, ordenados por distância
local function raidMobsNear(origin, radius)
    local list = {}
    if not origin then return list end
    for _, mob in ipairs(collectEnemies()) do
        local mhrp = mob:FindFirstChild("HumanoidRootPart")
        local hum = mob:FindFirstChildOfClass("Humanoid")
        if mhrp and hum and hum.Health > 0 then
            local d = (mhrp.Position - origin).Magnitude
            if d <= (radius or RAID_KILL_RADIUS) then
                table.insert(list, { mob = mob, hum = hum, dist = d })
            end
        end
    end
    table.sort(list, function(a, b) return a.dist < b.dist end)
    return list
end

local function setRaidStatus(text, isError)
    State.raidStatus = text
    if UI.raidStatusLabel then UI.raidStatusLabel.Text = "Status: " .. text end
    if setStatus then setStatus(text, isError) end
end

local function setupRaidListener()
    if State.raidConn then return end
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local raids = remotes and remotes:FindFirstChild("Raids")
    if not raids then return end

    State.raidConn = raids.OnClientEvent:Connect(function(kind)
        if kind == "StartTimer" then
            State.raidInRaid = true
            State.raidIsland = raidCurrentIsland() or 1
            State.raidClearSince = nil
            setRaidStatus("Raid iniciada")
        elseif kind == "Finished" then
            State.raidInRaid = false
            State.raidIsland = nil
            State.raidClearSince = nil
            raidStopHover()
            setRaidStatus("Raid finalizada")
        end
    end)
end

local function raidTriggerAround(pos, radius)
    local firePrompt = fireproximityprompt or function() end
    local fireClick = fireclickdetector or function() end
    local fireTouch = firetouchinterest or function() end
    local hrp = getHRP()
    local fired = 0

    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") or d:IsA("ClickDetector") or d:IsA("TouchTransmitter") then
            local part = d:FindFirstAncestorWhichIsA("BasePart")
            if not part and d.Parent and d.Parent:IsA("BasePart") then part = d.Parent end
            if part and (part.Position - pos).Magnitude <= (radius or 60) then
                if d:IsA("ProximityPrompt") then
                    pcall(firePrompt, d)
                elseif d:IsA("ClickDetector") then
                    pcall(fireClick, d)
                elseif d:IsA("TouchTransmitter") and hrp then
                    pcall(fireTouch, part, hrp, 0)
                    task.wait(0.05)
                    pcall(fireTouch, part, hrp, 1)
                end
                fired = fired + 1
            end
        end
    end
    return fired
end

local function raidLoop()
    if State.raidRunning then return end
    State.raidRunning = true
    while State.autoRaid do
        local ok = pcall(function()
            State.instantFarm = true

            local timer = raidTimerVisible()
            if timer then
                if not State.raidInRaid then
                    State.raidIsland = raidCurrentIsland() or 1
                    State.raidClearSince = nil
                end
                State.raidInRaid = true
                State.raidNoTimerSince = nil
            elseif State.raidInRaid then
                State.raidNoTimerSince = State.raidNoTimerSince or os.clock()
                if os.clock() - State.raidNoTimerSince > 12 then
                    State.raidInRaid = false
                    State.raidNoTimerSince = nil
                    State.raidIsland = nil
                    State.raidClearSince = nil
                    raidStopHover()
                end
            end

            local inRaid = State.raidInRaid
            if inRaid then
                State.raidInRaid = true

                local idx = State.raidIsland or raidCurrentIsland() or 1
                local island = raidIslandPart(idx)
                if not island then
                    idx = 1
                    island = raidIslandPart(1)
                end
                State.raidIsland = idx

                local origin = island and island.Position or (getHRP() and getHRP().Position)
                if origin then
                    raidSetHover(origin + Vector3.new(0, RAID_HOVER_HEIGHT, 0))
                end

                -- cliente passa a simular os mobs; a morte zera a vida e replica
                local simOk = forceSimulationRadius()

                if not simOk then
                    setRaidStatus("Raid: executor sem sethiddenproperty (morte instantânea indisponível)", true)
                else
                    local mobs = raidMobsNear(origin, RAID_KILL_RADIUS)
                    local killed = 0
                    for _, entry in ipairs(mobs) do
                        local hum = entry.hum
                        if hum and hum.Parent and hum.Health > 0 then
                            pcall(function() hum.Health = 0 end)
                            killed = killed + 1
                        end
                    end

                    if #mobs > 0 then
                        State.raidClearSince = nil
                        setRaidStatus("Raid: ilha " .. tostring(idx) .. " - " .. killed .. " mobs mortos")
                    else
                        State.raidClearSince = State.raidClearSince or os.clock()
                        local waited = os.clock() - State.raidClearSince
                        if waited >= RAID_WAVE_GRACE and idx < 5 then
                            State.raidIsland = idx + 1
                            State.raidClearSince = nil
                            setRaidStatus("Raid: ilha " .. tostring(State.raidIsland) .. " (avançando)")
                        elseif idx >= 5 then
                            setRaidStatus("Raid: ilha 5 - esperando o boss/onda")
                        else
                            setRaidStatus("Raid: ilha " .. tostring(idx) .. " - esperando mobs")
                        end
                    end
                end
            else
                raidStopHover()
                State.raidIsland = nil
                State.raidClearSince = nil

                local now = os.clock()
                if now - State.raidLastStart >= 6 then
                    State.raidLastStart = now

                    local chip = findRaidChip()
                    if not chip then
                        fireRemote("CommF_", "RaidsNpc", "Select", State.raidElement)
                        task.wait(0.8)
                        chip = findRaidChip()
                    end

                    if not chip then
                        setRaidStatus("Raid: sem Microchip (compre no RaidsNpc)", true)
                    elseif not equipRaidChip() then
                        setRaidStatus("Raid: não consegui equipar o chip", true)
                    else
                        local loc = RAID_LOCATIONS[CURRENT_SEA]
                        if not loc then
                            setRaidStatus("Raid: disponível só no 2º e 3º mar", true)
                        else
                            teleport(loc.tube + Vector3.new(0, 3, 0), nil, true, function()
                                return not State.autoRaid
                            end)
                            task.wait(1.2)
                            equipRaidChip()
                            raidTriggerAround(loc.button, 60)
                            setRaidStatus("Raid: entrando (chip " .. State.raidElement .. ")")
                            task.wait(2.5)
                        end
                    end
                end
            end
        end)

        if not ok then
            if trackError("raid") then
                State.autoRaid = false
                raidStopHover()
                if UI.toggles.autoRaid then UI.toggles.autoRaid.set(false) end
                setRaidStatus("Auto Raid desligado (erros)", true)
            end
        else
            clearErrors("raid")
        end

        task.wait(0.5)
    end
    raidStopHover()
    State.raidIsland = nil
    State.raidClearSince = nil
    State.raidRunning = false
end

local function awakenLoop()
    if State.awakenRunning then return end
    State.awakenRunning = true
    while State.autoAwaken do
        fireRemote("CommF_", "Awakener", "Check")
        task.wait(0.3)
        fireRemote("CommF_", "Awakener", "Awaken")
        task.wait(2.5)
    end
    State.awakenRunning = false
end

--==================== KILL AURA ====================
-- Puxa e mata todos os inimigos dentro do raio ao redor do personagem.
-- O "instant kill" usa o mesmo método dos hubs públicos:
--   sethiddenproperty(LP, "SimulationRadius", math.huge) + Humanoid.Health = 0
-- Isso faz o cliente simular os mobs e a morte replicar no servidor.
-- Os remotes RE/RegisterAttack + RE/RegisterHit ficam como reforço/fallback.

local function getNetRemotes()
    local ok, attack, hit = pcall(function()
        local modules = ReplicatedStorage:FindFirstChild("Modules")
        local net = modules and modules:FindFirstChild("Net")
        if not net then return nil, nil end
        return net:FindFirstChild("RE/RegisterAttack"), net:FindFirstChild("RE/RegisterHit")
    end)
    if ok then return attack, hit end
    return nil, nil
end

-- Aumenta o raio de simulação do cliente para o servidor aceitar a morte dos mobs.
function forceSimulationRadius()
    local okAny = false

    local setSim = setsimulationradius or (getgenv and getgenv().setsimulationradius)
    if setSim then
        okAny = pcall(function() setSim(math.huge) end) or okAny
    end

    local sethidden = sethiddenproperty or (getgenv and getgenv().sethiddenproperty)
    if sethidden then
        okAny = pcall(function()
            sethidden(LP, "SimulationRadius", math.huge)
            sethidden(LP, "MaxSimulationRadius", math.huge)
        end) or okAny

        if not okAny then
            okAny = pcall(function()
                sethidden(LP, "SimulationRadius", 112412400000)
                sethidden(LP, "MaxSimulationRadius", 112412400000)
            end)
        end
    end

    AURA.simOk = okAny
    return okAny
end

-- Captura um hitId válido que o próprio jogo manda ao atacar (anti-cheat novo).
local function installHitIdCapture()
    if AURA.hooked then return end
    local hookFn = hookmetamethod or (getgenv and getgenv().hookmetamethod)
    local methodFn = getnamecallmethod or (getgenv and getgenv().getnamecallmethod)
    local callerFn = checkcaller or (getgenv and getgenv().checkcaller)
    local closureFn = newcclosure or (getgenv and getgenv().newcclosure)
    if not (hookFn and methodFn and callerFn and closureFn) then return end

    local _, registerHit = getNetRemotes()
    if not registerHit then return end

    local ok = pcall(function()
        local old
        old = hookFn(game, "__namecall", closureFn(function(self, ...)
            if not callerFn() and methodFn() == "FireServer" and self == registerHit then
                local args = table.pack(...)
                if args[4] ~= nil then
                    AURA.hitId = args[4]
                elseif args.n == 1 and type(args[1]) == "string" then
                    AURA.hitId = args[1]
                end
            end
            return old(self, ...)
        end))
        AURA.hooked = true
    end)

    if not ok and setStatus then
        setStatus("Kill aura: hitId não capturado, usando fallback", true)
    end
end

local function killAuraHit(targets)
    local attack, hit = getNetRemotes()
    if not attack or not hit or #targets == 0 then return false end

    AURA.combo = (AURA.combo % 4) + 1
    pcall(function() attack:FireServer(0.4, AURA.combo) end)

    local sent = false
    for _, t in ipairs(targets) do
        if t.part then
            for _ = 1, CONFIG.killAuraBurst do
                pcall(function()
                    if AURA.hitId ~= nil then
                        -- assinatura atual: (part, {}, nil, hitId)
                        hit:FireServer(t.part, {}, nil, AURA.hitId)
                    else
                        -- assinatura antiga: (part, {{model, part}})
                        hit:FireServer(t.part, { { t.mob, t.part } })
                    end
                end)
            end
            sent = true
        end
    end
    return sent
end

local function killAuraLoop()
    installHitIdCapture()
    forceSimulationRadius()

    while State.killAura do
        local ok = pcall(function()
            if not isAlive() then return end
            local hrp = getHRP()
            if not hrp then return end

            -- o SimulationRadius pode resetar; renova de tempos em tempos
            local now = os.clock()
            if now - AURA.lastSim >= 0.5 then
                AURA.lastSim = now
                forceSimulationRadius()
            end

            local radius = CONFIG.killAuraRange
            local targets = {}

            for _, mob in ipairs(collectEnemies()) do
                local mhrp = mob:FindFirstChild("HumanoidRootPart")
                local mhum = mob:FindFirstChildOfClass("Humanoid")
                if mhrp and mhum and mhum.Health > 0 then
                    local d = (mhrp.Position - hrp.Position).Magnitude
                    if d <= radius then
                        targets[#targets + 1] = {
                            mob = mob,
                            hum = mhum,
                            part = mob:FindFirstChild("Head") or mhrp,
                        }
                        boostTarget(mob)
                        pcall(function()
                            mhrp.CFrame = hrp.CFrame * CFrame.new(0, 0, -4)
                            mhrp.AssemblyLinearVelocity = Vector3.zero
                            mhrp.AssemblyAngularVelocity = Vector3.zero
                        end)
                    end
                end
            end

            if #targets > 0 then
                -- MÉTODO DOS HUBS PÚBLICOS: mata direto pelo Humanoid
                if AURA.simOk then
                    for _, t in ipairs(targets) do
                        pcall(function()
                            if t.hum and t.hum.Parent and t.hum.Health > 0 then
                                t.hum.Health = 0
                            end
                        end)
                    end
                end

                -- reforço: remotes de hit (dano de arma em todos de uma vez)
                killAuraHit(targets)

                -- último fallback: ataque normal com a arma
                if not AURA.simOk and AURA.hitId == nil and now - AURA.lastWeapon >= 0.1 then
                    AURA.lastWeapon = now
                    attackOnce()
                end
            end
        end)

        if not ok then
            if trackError("aura") then
                State.killAura = false
                if UI.toggles.killAura then UI.toggles.killAura.set(false) end
                if setStatus then setStatus("Kill aura desligado (erros)", true) end
            end
        else
            clearErrors("aura")
        end

        task.wait(CONFIG.killAuraDelay)
    end
end

--==================== AUTO STATS ====================
local STATS = { "Melee", "Defense", "Sword", "Gun", "Blox Fruit" }

local function getStatPoints()
    local ok, points = pcall(function()
        local data = LP:FindFirstChild("Data")
        local sp = data and data:FindFirstChild("StatPoints")
        return sp and sp.Value
    end)
    if ok then return tonumber(points) end
    return nil
end

local function statLoop()
    while State.autoStats do
        local ok = pcall(function()
            local points = getStatPoints()
            if points == nil then
                -- sem leitura: tenta 1 ponto por ciclo (o servidor ignora se não houver)
                fireRemote("CommF_", "AddStat", State.statTarget, 1)
            elseif points > 0 then
                fireRemote("CommF_", "AddStat", State.statTarget, 1)
            end
        end)

        if not ok then
            if trackError("stats") then
                State.autoStats = false
                if UI.toggles.autoStats then UI.toggles.autoStats.set(false) end
                if setStatus then setStatus("Auto stats desligado (erros)", true) end
            end
        else
            clearErrors("stats")
        end
        task.wait(0.35)
    end
end

--==================== SKILLS ====================
local anyCache = { time = 0, mob = nil }

local function nearestAnyEnemy()
    local now = os.clock()
    if now - anyCache.time < 0.5 and enemyIsAlive(anyCache.mob) then
        return anyCache.mob
    end

    -- prioriza o alvo do farm/boss; senão pega o inimigo vivo mais próximo
    local mob = nil
    if State.bossTarget ~= "" then
        local b = nearestEnemy(State.bossTarget)
        if b then mob = b end
    end
    if not mob and State.farmTarget ~= "" then
        local m = nearestEnemy(State.farmTarget)
        if m then mob = m end
    end

    if not mob then
        local hrp = getHRP()
        local best, bestDist = nil, math.huge
        if hrp then
            for _, candidate in ipairs(collectEnemies()) do
                local mhrp = candidate:FindFirstChild("HumanoidRootPart")
                if mhrp then
                    local d = (mhrp.Position - hrp.Position).Magnitude
                    if d < bestDist then
                        best, bestDist = candidate, d
                    end
                end
            end
        end
        mob = best
    end

    anyCache = { time = now, mob = mob }
    return mob
end

local function invokeSkill(tool, key, hrp, mhrp)
    local rf = tool:FindFirstChild("RemoteFunction")
    if rf then
        local ok = pcall(function()
            if key == "Z" then
                rf:InvokeServer("Z", CFrame.new(hrp.Position, Vector3.new(mhrp.Position.X, hrp.Position.Y, mhrp.Position.Z)))
            elseif key == "X" then
                rf:InvokeServer("X")
            else
                rf:InvokeServer("C")
            end
        end)
        if ok then return true end
    end

    -- C costuma ser tecla; fallback via VirtualInputManager
    if key == "C" then
        return pcall(function()
            local vim = game:GetService("VirtualInputManager")
            vim:SendKeyEvent(true, "C", false, game)
            task.wait(0.05)
            vim:SendKeyEvent(false, "C", false, game)
        end)
    end

    return false
end

local function skillLoop()
    local nextZ, nextX, nextC = 0, 0, 0
    while State.skillZ or State.skillX or State.skillC do
        local ok = pcall(function()
            if not isAlive() then return end
            local mob = nearestAnyEnemy()
            local hrp = getHRP()
            if not mob or not hrp then return end
            local mhrp = mob:FindFirstChild("HumanoidRootPart")
            if not mhrp then return end

            -- não gasta skill em alvo longe
            if (mhrp.Position - hrp.Position).Magnitude > 60 then return end

            local tool = equipWeapon()
            if not tool then return end

            local now = os.clock()
            if State.skillZ and now >= nextZ then
                nextZ = now + CONFIG.skills.z
                invokeSkill(tool, "Z", hrp, mhrp)
            end
            if State.skillX and now >= nextX then
                nextX = now + CONFIG.skills.x
                invokeSkill(tool, "X", hrp, mhrp)
            end
            if State.skillC and now >= nextC then
                nextC = now + CONFIG.skills.c
                invokeSkill(tool, "C", hrp, mhrp)
            end
        end)

        if not ok then
            if trackError("skills") then
                State.skillZ, State.skillX, State.skillC = false, false, false
                if UI.toggles.skillZ then UI.toggles.skillZ.set(false) end
                if UI.toggles.skillX then UI.toggles.skillX.set(false) end
                if UI.toggles.skillC then UI.toggles.skillC.set(false) end
                if setStatus then setStatus("Auto skills desligado (erros)", true) end
            end
        else
            clearErrors("skills")
        end

        task.wait(0.08)
    end
    State.skillRunning = false
end

local function syncSkills()
    if (State.skillZ or State.skillX or State.skillC) and not State.skillRunning then
        State.skillRunning = true
        task.spawn(skillLoop)
    end
end

local function toggleFastAttack(on)
    State.fastAttack = on
    if on then
        if not State.attacking then
            State.fastAttackOwnsAttack = true
            startAttack()
        end
    elseif State.fastAttackOwnsAttack then
        State.fastAttackOwnsAttack = false
        local keep = UI.toggles.autoAttack and UI.toggles.autoAttack.get()
        if not keep then stopAttack() end
    end
end

--==================== MOVIMENTO ====================
local function noclipLoop()
    while State.noclip do
        local char = getChar()
        if char then
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("BasePart") and v.CanCollide then
                    pcall(function() v.CanCollide = false end)
                end
            end
        end
        task.wait(CONFIG.noclipRefresh)
    end
end

local function applyNoclip(on)
    State.noclip = on
    if on then
        task.spawn(noclipLoop)
    else
        local char = getChar()
        if char then
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("BasePart") then
                    pcall(function() v.CanCollide = true end)
                end
            end
        end
    end
end

local flyBV = nil

local function stopFly()
    State.fly = false
    if flyBV then
        pcall(function() flyBV:Destroy() end)
        flyBV = nil
    end
    local hrp = getHRP()
    local hum = getHum()
    if hrp then pcall(function() hrp.Anchored = false end) end
    if hum then pcall(function() hum.PlatformStand = false end) end
end

local function startFly()
    local hrp = getHRP()
    local hum = getHum()
    if not hrp or not hum then return false end

    State.fly = true
    pcall(function() hum.PlatformStand = true end)

    if flyBV then pcall(function() flyBV:Destroy() end) end
    local bv = Instance.new("BodyVelocity")
    bv.Name = "HubFly"
    bv.MaxForce = Vector3.new(100000, 100000, 100000)
    bv.Velocity = Vector3.zero
    bv.Parent = hrp
    flyBV = bv

    task.spawn(function()
        while State.fly do
            local hrp2 = getHRP()
            local cam = Workspace.CurrentCamera
            if not hrp2 or not cam or not bv.Parent then break end

            local move = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0, 1, 0) end

            if move.Magnitude > 0 then
                bv.Velocity = move.Unit * CONFIG.flySpeed
            else
                bv.Velocity = Vector3.zero
            end

            task.wait()
        end

        if bv then pcall(function() bv:Destroy() end) end
        flyBV = nil
        if State.fly then State.fly = false end
    end)

    return true
end

UserInputService.JumpRequest:Connect(function()
    if not State.infiniteJump then return end
    local hum = getHum()
    if hum then
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
    end
end)

--==================== SERVIDOR ====================
local TeleportService = game:GetService("TeleportService")

local function rejoinServer()
    if State.hopping then return end
    State.hopping = true
    if setStatus then setStatus("Reconectando...") end
    pcall(function()
        TeleportService:Teleport(game.PlaceId, LP)
    end)
    task.wait(4)
    State.hopping = false
end

local function serverHop()
    if State.hopping then return end
    if not (game.HttpGet or game.HttpGetAsync) then
        if setStatus then setStatus("Executor sem HttpGet", true) end
        return
    end

    State.hopping = true
    if setStatus then setStatus("Buscando servidores...") end

    task.spawn(function()
        local ok, data = pcall(function()
            local url = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100"
            local raw
            if game.HttpGet then
                raw = game:HttpGet(url)
            else
                raw = game:HttpGetAsync(url)
            end
            return HttpService:JSONDecode(raw)
        end)

        if not ok or type(data) ~= "table" or type(data.data) ~= "table" then
            State.hopping = false
            if setStatus then setStatus("Falha ao listar servidores", true) end
            return
        end

        local chosen = nil
        for _, s in ipairs(data.data) do
            local playing = tonumber(s.playing) or 0
            local maxp = tonumber(s.maxPlayers) or 0
            if s.id and s.id ~= game.JobId and playing < maxp then
                chosen = s.id
                break
            end
        end

        if not chosen then
            State.hopping = false
            if setStatus then setStatus("Nenhum servidor com vaga", true) end
            return
        end

        if setStatus then setStatus("Teleportando para outro servidor...") end
        local ok2 = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, chosen, LP)
        end)
        if not ok2 and setStatus then setStatus("Falha no teleporte de servidor", true) end

        task.wait(5)
        State.hopping = false
    end)
end

local autoRejoinConn = nil

local function setAutoRejoin(on)
    State.autoRejoin = on

    if not on then
        if autoRejoinConn then
            autoRejoinConn:Disconnect()
            autoRejoinConn = nil
        end
        return
    end

    if autoRejoinConn then return end

    pcall(function()
        local CoreGui = game:GetService("CoreGui")
        local prompt = CoreGui:WaitForChild("RobloxPromptGui", 10)
        local overlay = prompt and prompt:WaitForChild("promptOverlay", 10)
        if not overlay then return end

        autoRejoinConn = overlay.ChildAdded:Connect(function(child)
            if not State.autoRejoin then return end
            if child.Name ~= "ErrorPrompt" then return end
            task.wait(1)

            local clicked = false
            for _, d in ipairs(child:GetDescendants()) do
                if not clicked and d:IsA("TextButton") then
                    local n = string.lower(d.Name)
                    if string.find(n, "reconnect", 1, true) or string.find(n, "rejoin", 1, true) then
                        clicked = true
                        pcall(function()
                            if firesignal then firesignal(d.MouseButton1Click) end
                        end)
                    end
                end
            end

            if not clicked then
                pcall(function()
                    TeleportService:Teleport(game.PlaceId, LP)
                end)
            end
        end)
    end)
end

--==================== ANTI-AFK ====================
local antiAfkCount = 0
local function startAntiAfk()
    if antiAfkConn then return end
    antiAfkConn = LP.Idled:Connect(function()
        antiAfkCount = antiAfkCount + 1
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end)
        if UI.antiAfkLabel then
            UI.antiAfkLabel.Text = "Anti-AFK: ativo (" .. antiAfkCount .. " ações)"
        end
    end)
end

local function stopAntiAfk()
    if antiAfkConn then
        antiAfkConn:Disconnect()
        antiAfkConn = nil
    end
end

--==================== ESPECTAR ====================
local function spectate(player)
    if not player or not player.Character then
        if setStatus then setStatus("Jogador indisponível", true) end
        return false
    end
    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    if not hum then
        if setStatus then setStatus("Jogador sem humanoid", true) end
        return false
    end

    State.spectateTarget = player
    if setStatus then setStatus("Espectando: " .. player.Name) end

    task.spawn(function()
        while State.spectateTarget == player do
            local c = player.Character
            local h = c and c:FindFirstChildOfClass("Humanoid")
            local cam = Workspace.CurrentCamera
            if h and cam then
                cam.CameraSubject = h
                cam.CameraType = Enum.CameraType.Custom
            end
            task.wait(0.5)
        end
    end)
    return true
end

local function stopSpectate()
    State.spectateTarget = nil
    local hum = getHum()
    local cam = Workspace.CurrentCamera
    if hum and cam then
        cam.CameraSubject = hum
        cam.CameraType = Enum.CameraType.Custom
    end
    if UI.toggles.spectate and UI.toggles.spectate.get() then
        UI.toggles.spectate.set(false)
    end
    if setStatus then setStatus("Espectar encerrado") end
end

--==================== KILL SWITCH ====================
local function killSwitch()
    State.attacking = false
    State.farming = false
    State.bossFarming = false
    State.skillZ = false
    State.skillX = false
    State.skillC = false
    State.fastAttack = false
    State.fastAttackOwnsAttack = false
    State.autoQuest = false
    State.autoRaid = false
    State.raidKey = nil
    State.raidStartedFarm = false
    State.raidInRaid = false
    State.raidIsland = nil
    State.raidClearSince = nil
    State.autoAwaken = false
    State.killAura = false
    State.autoStats = false
    State.fruitNotify = false
    State.fruitAutoStore = false
    State.espPlayers = false
    State.espFruits = false
    State.espChests = false
    State.espBosses = false
    State.infiniteJump = false

    stopFly()
    raidStopHover()
    applyNoclip(false)
    setAutoRejoin(false)
    clearESP()
    stopSpectate()
    stopAntiAfk()

    for _, t in pairs(UI.toggles) do
        pcall(function() t.set(false) end)
    end

    if setStatus then setStatus("Tudo desligado") end
    notify("Tudo desligado")
end

--==================== CONFIG SAVE/LOAD ====================
local CONFIG_FILE = "prisma_config.json"

local function saveConfig()
    local data = {
        version = CONFIG.version,
        farmTarget = State.farmTarget,
        attackDelay = CONFIG.attackDelay,
        farmDelay = CONFIG.farmDelay,
        farmRange = CONFIG.farmRange,
        killAuraRange = CONFIG.killAuraRange,
        instantFarm = State.instantFarm,
        flySpeed = CONFIG.flySpeed,
        statTarget = State.statTarget,
        fruitStoreCapacity = State.fruitStoreCapacity,
    }

    if not writefile then
        notify("Executor sem writefile")
        return
    end

    local ok = pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(data))
    end)
    notify(ok and "Config salva" or "Falha ao salvar")
end

local function loadConfig()
    if not (readfile and isfile and isfile(CONFIG_FILE)) then
        notify("Nenhuma config salva")
        return
    end

    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(CONFIG_FILE))
    end)

    if not ok or type(data) ~= "table" then
        notify("Config inválida")
        return
    end

    if type(data.farmTarget) == "string" then
        State.farmTarget = data.farmTarget
        State.farmTargetLevel = MOB_LEVELS[data.farmTarget]
    end
    if tonumber(data.attackDelay) and UI.sliders.attackDelay then
        UI.sliders.attackDelay.set(tonumber(data.attackDelay))
    end
    if tonumber(data.farmDelay) and UI.sliders.farmDelay then
        UI.sliders.farmDelay.set(tonumber(data.farmDelay))
    end
    if tonumber(data.farmRange) and UI.sliders.farmRange then
        UI.sliders.farmRange.set(tonumber(data.farmRange))
    end
    if tonumber(data.killAuraRange) and UI.sliders.killAuraRange then
        UI.sliders.killAuraRange.set(tonumber(data.killAuraRange))
    end
    if type(data.instantFarm) == "boolean" and UI.toggles.instantFarm then
        UI.toggles.instantFarm.set(data.instantFarm)
    end
    if tonumber(data.flySpeed) and UI.sliders.flySpeed then
        UI.sliders.flySpeed.set(tonumber(data.flySpeed))
    end
    if type(data.statTarget) == "string" then
        State.statTarget = data.statTarget
        if UI.statBtn then UI.statBtn.Text = "Atributo: " .. State.statTarget end
    end
    if tonumber(data.fruitStoreCapacity) and UI.sliders.fruitStoreCapacity then
        UI.sliders.fruitStoreCapacity.set(tonumber(data.fruitStoreCapacity))
    end

    notify("Config carregada")
end

--==================== UI ====================
local C = {
    bg = Color3.fromRGB(14, 14, 19),
    sidebar = Color3.fromRGB(10, 10, 14),
    panel = Color3.fromRGB(22, 22, 30),
    panel2 = Color3.fromRGB(30, 30, 40),
    hover = Color3.fromRGB(40, 40, 54),
    accent = Color3.fromRGB(124, 92, 255),
    accent2 = Color3.fromRGB(167, 139, 250),
    text = Color3.fromRGB(238, 238, 245),
    sub = Color3.fromRGB(150, 150, 165),
    off = Color3.fromRGB(45, 45, 58),
    danger = Color3.fromRGB(235, 80, 95),
    ok = Color3.fromRGB(80, 210, 130),
    stroke = Color3.fromRGB(38, 38, 50),
}

local function new(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    if parent then inst.Parent = parent end
    return inst
end

-- remove instâncias antigas do hub para não empilhar GUI ao reexecutar
pcall(function()
    for _, child in ipairs(GUI_PARENT:GetChildren()) do
        if child:IsA("ScreenGui") and string.find(child.Name, "^PrismaUI_") then
            child:Destroy()
        end
    end
end)

local gui = new("ScreenGui", {
    Name = "PrismaUI_" .. tostring(math.random(100000, 999999)),
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 999,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, GUI_PARENT)

local main = new("Frame", {
    Name = "Main",
    Size = UDim2.new(0, 620, 0, 470),
    Position = UDim2.new(0.5, -310, 0.5, -235),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
}, gui)
new("UICorner", { CornerRadius = UDim.new(0, 12) }, main)
new("UIStroke", { Color = C.stroke, Thickness = 1 }, main)

-- linha de acento no topo
new("Frame", {
    Size = UDim2.new(1, -24, 0, 2),
    Position = UDim2.new(0, 12, 0, 0),
    BackgroundColor3 = C.accent,
    BorderSizePixel = 0,
    ZIndex = 2,
}, main)

local titleBar = new("TextButton", {
    Name = "TitleBar",
    Size = UDim2.new(1, 0, 0, 44),
    BackgroundColor3 = C.sidebar,
    Text = "",
    AutoButtonColor = false,
    BorderSizePixel = 0,
}, main)
new("UICorner", { CornerRadius = UDim.new(0, 12) }, titleBar)

local logo = new("TextLabel", {
    Size = UDim2.new(0, 24, 0, 24),
    Position = UDim2.new(0, 14, 0.5, -12),
    BackgroundColor3 = C.accent,
    Text = "P",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    BorderSizePixel = 0,
}, titleBar)
new("UICorner", { CornerRadius = UDim.new(0, 7) }, logo)

new("TextLabel", {
    Size = UDim2.new(0, 260, 1, 0),
    Position = UDim2.new(0, 48, 0, 0),
    BackgroundTransparency = 1,
    RichText = true,
    Text = '<font color="rgb(167,139,250)"><b>PRISMA</b></font> HUB',
    TextColor3 = C.text,
    TextSize = 15,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
}, titleBar)

new("TextLabel", {
    Size = UDim2.new(0, 60, 1, 0),
    Position = UDim2.new(0, 206, 0, 0),
    BackgroundTransparency = 1,
    Text = "v" .. CONFIG.version,
    TextColor3 = C.sub,
    TextSize = 11,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
}, titleBar)

local minBtn = new("TextButton", {
    Size = UDim2.new(0, 26, 0, 26),
    Position = UDim2.new(1, -68, 0.5, -13),
    BackgroundColor3 = C.panel2,
    Text = "–",
    TextColor3 = C.text,
    TextSize = 15,
    Font = Enum.Font.GothamBold,
    BorderSizePixel = 0,
    AutoButtonColor = false,
}, titleBar)
new("UICorner", { CornerRadius = UDim.new(0, 7) }, minBtn)

local closeBtn = new("TextButton", {
    Size = UDim2.new(0, 26, 0, 26),
    Position = UDim2.new(1, -36, 0.5, -13),
    BackgroundColor3 = C.panel2,
    Text = "×",
    TextColor3 = C.text,
    TextSize = 16,
    Font = Enum.Font.GothamBold,
    BorderSizePixel = 0,
    AutoButtonColor = false,
}, titleBar)
new("UICorner", { CornerRadius = UDim.new(0, 7) }, closeBtn)

minBtn.MouseEnter:Connect(function() minBtn.BackgroundColor3 = C.hover end)
minBtn.MouseLeave:Connect(function() minBtn.BackgroundColor3 = C.panel2 end)
closeBtn.MouseEnter:Connect(function() closeBtn.BackgroundColor3 = C.danger end)
closeBtn.MouseLeave:Connect(function() closeBtn.BackgroundColor3 = C.panel2 end)

-- arrastar janela
local dragging = false
local dragStart, startPos

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- sidebar (navegação vertical)
local sidebar = new("Frame", {
    Size = UDim2.new(0, 150, 1, -74),
    Position = UDim2.new(0, 0, 0, 44),
    BackgroundColor3 = C.sidebar,
    BorderSizePixel = 0,
}, main)
new("Frame", {
    Size = UDim2.new(0, 1, 1, 0),
    Position = UDim2.new(1, -1, 0, 0),
    BackgroundColor3 = C.stroke,
    BorderSizePixel = 0,
}, sidebar)

new("TextLabel", {
    Size = UDim2.new(1, -24, 0, 16),
    Position = UDim2.new(0, 14, 0, 12),
    BackgroundTransparency = 1,
    Text = "NAVEGACAO",
    TextColor3 = C.sub,
    TextSize = 10,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
}, sidebar)

local tabBar = new("Frame", {
    Size = UDim2.new(1, -20, 1, -96),
    Position = UDim2.new(0, 10, 0, 36),
    BackgroundTransparency = 1,
}, sidebar)
new("UIListLayout", {
    FillDirection = Enum.FillDirection.Vertical,
    Padding = UDim.new(0, 4),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, tabBar)

-- área de conteúdo
local content = new("Frame", {
    Size = UDim2.new(1, -170, 1, -84),
    Position = UDim2.new(0, 158, 0, 52),
    BackgroundTransparency = 1,
}, main)

-- status
local status = new("TextLabel", {
    Size = UDim2.new(1, -170, 0, 18),
    Position = UDim2.new(0, 158, 1, -26),
    BackgroundTransparency = 1,
    Text = "Pronto",
    TextColor3 = C.sub,
    TextSize = 11,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
}, main)

setStatus = function(text, isError)
    status.Text = tostring(text)
    status.TextColor3 = isError and C.danger or C.sub
end

-- botão de pânico (rodapé da sidebar)
local panic = new("TextButton", {
    Size = UDim2.new(1, -20, 0, 36),
    Position = UDim2.new(0, 10, 1, -48),
    BackgroundColor3 = C.danger,
    Text = "PARAR TUDO",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    BorderSizePixel = 0,
    AutoButtonColor = false,
}, sidebar)
new("UICorner", { CornerRadius = UDim.new(0, 8) }, panic)
panic.MouseEnter:Connect(function() panic.BackgroundColor3 = Color3.fromRGB(255, 105, 120) end)
panic.MouseLeave:Connect(function() panic.BackgroundColor3 = C.danger end)
panic.MouseButton1Click:Connect(function()
    safeCall(killSwitch)
end)

-- botão de reabrir (fica no canto superior direito da tela)
local reopen = new("TextButton", {
    Size = UDim2.new(0, 46, 0, 46),
    Position = UDim2.new(1, -58, 0, 12),
    AnchorPoint = Vector2.new(0, 0),
    BackgroundColor3 = C.accent,
    Text = "P",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 18,
    Font = Enum.Font.GothamBold,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 50,
}, gui)
new("UICorner", { CornerRadius = UDim.new(0, 12) }, reopen)
new("UIStroke", { Color = C.stroke, Thickness = 1 }, reopen)

minBtn.MouseButton1Click:Connect(function()
    main.Visible = false
    reopen.Visible = true
end)
closeBtn.MouseButton1Click:Connect(function()
    main.Visible = false
    reopen.Visible = true
end)
reopen.MouseButton1Click:Connect(function()
    main.Visible = true
    reopen.Visible = false
end)

-- atalhos: RightShift mostra/esconde a janela; End descarrega o hub
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        main.Visible = not main.Visible
        reopen.Visible = not main.Visible
    elseif input.KeyCode == Enum.KeyCode.End then
        safeCall(killSwitch)
        pcall(function() gui:Destroy() end)
    end
end)

--==================== WIDGETS ====================
local function makeToggle(parent, text, default, callback)
    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = C.panel,
        BorderSizePixel = 0,
    }, parent)
    new("UICorner", { CornerRadius = UDim.new(0, 8) }, row)
    new("UIStroke", { Color = C.stroke, Thickness = 1 }, row)

    new("TextLabel", {
        Size = UDim2.new(1, -72, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = C.text,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)

    local btn = new("TextButton", {
        Size = UDim2.new(0, 40, 0, 20),
        Position = UDim2.new(1, -52, 0.5, -10),
        BackgroundColor3 = default and C.accent or C.off,
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
    }, row)
    new("UICorner", { CornerRadius = UDim.new(1, 0) }, btn)

    local knob = new("Frame", {
        Size = UDim2.new(0, 16, 0, 16),
        Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
    }, btn)
    new("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)

    local state = default and true or false

    local function render()
        btn.BackgroundColor3 = state and C.accent or C.off
        knob.Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    end

    local api = {}
    api.get = function() return state end
    api.set = function(v)
        state = v and true or false
        render()
        safeCall(callback, state)
    end

    btn.MouseButton1Click:Connect(function()
        api.set(not state)
    end)

    render()
    return api
end

local function makeSlider(parent, text, min, max, default, callback)
    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = C.panel,
        BorderSizePixel = 0,
    }, parent)
    new("UICorner", { CornerRadius = UDim.new(0, 8) }, row)
    new("UIStroke", { Color = C.stroke, Thickness = 1 }, row)

    local decimals = (max - min) > 10 and 0 or 2
    local fmt = decimals == 0 and "%.0f" or "%.2f"

    new("TextLabel", {
        Size = UDim2.new(1, -88, 0, 20),
        Position = UDim2.new(0, 12, 0, 6),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = C.text,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)

    local valueLabel = new("TextLabel", {
        Size = UDim2.new(0, 72, 0, 20),
        Position = UDim2.new(1, -84, 0, 6),
        BackgroundTransparency = 1,
        Text = string.format(fmt, default),
        TextColor3 = C.accent2,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, row)

    local track = new("Frame", {
        Size = UDim2.new(1, -24, 0, 5),
        Position = UDim2.new(0, 12, 0, 38),
        BackgroundColor3 = C.off,
        BorderSizePixel = 0,
    }, row)
    new("UICorner", { CornerRadius = UDim.new(1, 0) }, track)

    local fill = new("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = C.accent,
        BorderSizePixel = 0,
    }, track)
    new("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)

    local knob = new("Frame", {
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new(0, 0, 0.5, -7),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
    }, track)
    new("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)

    local hit = new("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 3,
    }, track)

    local value = default

    local function render()
        local alpha = (value - min) / (max - min)
        alpha = math.clamp(alpha, 0, 1)
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        knob.Position = UDim2.new(alpha, -7, 0.5, -7)
        valueLabel.Text = string.format(fmt, value)
    end

    local function updateFromInput(input)
        local absX = track.AbsolutePosition.X
        local width = track.AbsoluteSize.X
        if width <= 0 then return end
        local alpha = math.clamp((input.Position.X - absX) / width, 0, 1)
        value = min + (max - min) * alpha
        render()
    end

    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            updateFromInput(input)
            local moveConn
            local endConn

            moveConn = UserInputService.InputChanged:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
                    updateFromInput(inp)
                end
            end)

            endConn = UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                    if moveConn then moveConn:Disconnect() end
                    if endConn then endConn:Disconnect() end
                    safeCall(callback, value)
                end
            end)
        end
    end)

    local api = {}
    api.get = function() return value end
    api.set = function(v)
        value = math.clamp(tonumber(v) or default, min, max)
        render()
        safeCall(callback, value)
    end

    render()
    return api
end

local function makeButton(parent, text, callback, color)
    local base = color or C.panel2
    local btn = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = base,
        Text = text,
        TextColor3 = C.text,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        BorderSizePixel = 0,
        AutoButtonColor = false,
    }, parent)
    new("UICorner", { CornerRadius = UDim.new(0, 8) }, btn)
    new("UIStroke", { Color = C.stroke, Thickness = 1 }, btn)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = C.hover end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = base end)
    btn.MouseButton1Click:Connect(function()
        safeCall(callback)
    end)
    return btn
end

local function makeTextbox(parent, placeholder, callback)
    local box = new("TextBox", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = C.panel2,
        Text = "",
        PlaceholderText = placeholder,
        PlaceholderColor3 = C.sub,
        TextColor3 = C.text,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, parent)
    new("UICorner", { CornerRadius = UDim.new(0, 8) }, box)
    new("UIStroke", { Color = C.stroke, Thickness = 1 }, box)
    new("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
    }, box)
    box.FocusLost:Connect(function(enter)
        if enter then
            safeCall(callback, box.Text)
        end
    end)
    return box
end

local function makeLabel(parent, text, wrapped)
    return new("TextLabel", {
        Size = UDim2.new(1, 0, 0, wrapped and 30 or 20),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = C.sub,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = wrapped or false,
        TextTruncate = wrapped and Enum.TextTruncate.None or Enum.TextTruncate.AtEnd,
    }, parent)
end

-- cabeçalho de seção, no estilo dos hubs genéricos
local function makeSection(parent, text)
    local holder = new("Frame", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
    }, parent)
    new("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = string.upper(tostring(text)),
        TextColor3 = C.accent2,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, holder)
    return holder
end

local function makeScrollList(parent, height)
    local sf = new("ScrollingFrame", {
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = C.panel,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = C.accent,
        ScrollingDirection = Enum.ScrollingDirection.Y,
    }, parent)
    new("UICorner", { CornerRadius = UDim.new(0, 8) }, sf)
    new("UIStroke", { Color = C.stroke, Thickness = 1 }, sf)
    new("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, sf)
    new("UIPadding", {
        PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
    }, sf)
    return sf
end

local function clearList(sf)
    for _, child in ipairs(sf:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end
end

local function addListButton(sf, text, callback, color)
    local base = color or C.panel2
    local b = new("TextButton", {
        Size = UDim2.new(1, -12, 0, 30),
        BackgroundColor3 = base,
        Text = "  " .. tostring(text),
        TextColor3 = C.text,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, sf)
    new("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
    b.MouseEnter:Connect(function() b.BackgroundColor3 = C.hover end)
    b.MouseLeave:Connect(function() b.BackgroundColor3 = base end)
    b.MouseButton1Click:Connect(function()
        safeCall(callback)
    end)
    return b
end

--==================== ABAS ====================
local tabs = {}
local activeTab = nil

local function makeTab(name, order)
    local btn = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = C.panel,
        BackgroundTransparency = 1,
        Text = "  " .. name,
        TextColor3 = C.sub,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        BorderSizePixel = 0,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false,
        LayoutOrder = order,
    }, tabBar)
    new("UICorner", { CornerRadius = UDim.new(0, 8) }, btn)

    local frame = new("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = false,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = C.accent,
        ScrollingDirection = Enum.ScrollingDirection.Y,
    }, content)
    new("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, frame)
    new("UIPadding", {
        PaddingTop = UDim.new(0, 2),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 2),
        PaddingRight = UDim.new(0, 2),
    }, frame)

    tabs[name] = { btn = btn, frame = frame }

    btn.MouseEnter:Connect(function()
        if activeTab ~= name then
            btn.BackgroundTransparency = 0.85
            btn.BackgroundColor3 = C.panel
            btn.TextColor3 = C.text
        end
    end)
    btn.MouseLeave:Connect(function()
        if activeTab ~= name then
            btn.BackgroundTransparency = 1
            btn.TextColor3 = C.sub
        end
    end)

    btn.MouseButton1Click:Connect(function()
        activeTab = name
        for n, t in pairs(tabs) do
            local active = (n == name)
            t.frame.Visible = active
            t.btn.BackgroundTransparency = active and 0 or 1
            t.btn.BackgroundColor3 = active and C.accent or C.panel
            t.btn.TextColor3 = active and Color3.fromRGB(255, 255, 255) or C.sub
        end
        if name == "Farm" and UI.refreshMobs then safeCall(UI.refreshMobs) end
        if name == "Boss" and UI.refreshBosses then safeCall(UI.refreshBosses) end
        if name == "Util" and UI.refreshPlayers then safeCall(UI.refreshPlayers) end
        if name == "ESP" and UI.refreshFruits then safeCall(UI.refreshFruits) end
    end)
    return frame
end

--==================== ABA FARM ====================
local farmTab = makeTab("Farm", 1)

makeLabel(farmTab, "Mobs matáveis do servidor (Workspace.Enemies), com nível. Clique para escolher o mob do Auto Farm.", true)
local seaNamesFarm = { [1] = "1º mar", [2] = "2º mar", [3] = "3º mar" }
makeLabel(farmTab, "Mar detectado: " .. (seaNamesFarm[CURRENT_SEA or 1] or "desconhecido"))

makeSection(farmTab, "Progressão")

UI.toggles.autoQuest = makeToggle(farmTab, "Auto Quest (todos os mares)", false, function(on)
    State.autoQuest = on
    if on then
        if UI.toggles.autoRaid and UI.toggles.autoRaid.get() then
            UI.toggles.autoRaid.set(false)
        end
        local q = pickQuest()
        if not q then
            setStatus("Auto quest: não foi possível ler o nível (Player.Data)", true)
            if UI.toggles.autoQuest then UI.toggles.autoQuest.set(false) end
            return
        end

        State.questKey = q.remote .. ":" .. tostring(q.questId)
        startQuest(q)

        if UI.toggles.autoFarm and not UI.toggles.autoFarm.get() then
            State.questStartedFarm = true
            UI.toggles.autoFarm.set(true)
        else
            startFarm()
        end

        setStatus("Auto quest (mar " .. tostring(CURRENT_SEA or 1) .. "): " .. q.mob .. " [Lv. " .. tostring(q.level) .. "] (seu nível " .. tostring(getLevel()) .. ")")
        task.spawn(questLoop)
    else
        if State.questStartedFarm then
            State.questStartedFarm = false
            if UI.toggles.autoFarm and UI.toggles.autoFarm.get() then
                UI.toggles.autoFarm.set(false)
            end
        end
        setStatus("Auto quest desligado")
    end
end)

makeButton(farmTab, "Tentar entregar quest", function()
    fireRemote("CommF_", "CompleteQuest")
    setStatus("Pedido de entrega enviado (fale com o NPC se não completar)")
end)

makeLabel(farmTab, "Auto Quest detecta o mar pelo PlaceId e usa a tabela do 1º, 2º ou 3º mar. A entrega ainda é manual.", true)


makeSection(farmTab, "Mobs e farm")

makeLabel(farmTab, "Auto Farm usa o mob selecionado. Sem seleção, escolhe o mob mais forte que o seu nível permite.", true)

makeButton(farmTab, "Atualizar lista de mobs", function()
    if UI.refreshMobs then UI.refreshMobs() end
end)

local mobList = makeScrollList(farmTab, 160)
UI.lists.mobs = mobList

local function mobText(name, level, count)
    local lv = level and ("Lv. " .. tostring(level)) or "Lv. ?"
    local suffix = count and ("  (" .. count .. ")") or ""
    return name .. "  [" .. lv .. "]" .. suffix
end

local function setFarmTarget(name, level, count)
    State.farmTarget = name
    State.farmTargetLevel = level
    if UI.targetLabel then
        UI.targetLabel.Text = "Alvo: " .. mobText(name, level, count)
    end
end

UI.targetLabel = makeLabel(farmTab, "Alvo: nenhum")

makeButton(farmTab, "TP para mob selecionado", function()
    if State.farmTarget == "" then
        setStatus("Selecione um mob primeiro", true)
        return
    end
    local mob = nearestEnemy(State.farmTarget)
    if not mob then
        setStatus("Mob não encontrado no servidor", true)
        return
    end
    local hrp = mob:FindFirstChild("HumanoidRootPart")
    if not hrp then
        setStatus("Mob sem HumanoidRootPart", true)
        return
    end
    boostTarget(mob)
    teleport(hrp.Position + Vector3.new(0, 3, -3), State.farmTarget)
end)

UI.toggles.instantFarm = makeToggle(farmTab, "Farm instantâneo (mata na hora)", true, function(on)
    State.instantFarm = on
    if on then
        forceSimulationRadius()
        setStatus("Farm instantâneo ligado (SimulationRadius + Health = 0)")
    else
        setStatus("Farm instantâneo desligado (volta ao ataque normal)")
    end
end)

UI.toggles.autoFarm = makeToggle(farmTab, "Auto Farm", false, function(on)
    if on then
        if State.farmTarget == "" then
            local list = listEnemies(false)
            if #list > 0 then
                local pick = bestMobForLevel(list)
                setFarmTarget(pick.name, pick.level, pick.count)
            else
                setStatus("Nenhum mob matável encontrado no servidor", true)
                if UI.toggles.autoFarm then UI.toggles.autoFarm.set(false) end
                return
            end
        end
        startFarm()
        local lvl = State.farmTargetLevel or MOB_LEVELS[State.farmTarget]
        setStatus("Auto farm ligado: " .. State.farmTarget .. (lvl and (" [Lv. " .. lvl .. "]") or ""))
    else
        stopFarm()
        setStatus("Auto farm desligado")
    end
end)

UI.sliders.farmDelay = makeSlider(farmTab, "Delay do farm (s)", 0.1, 1.0, CONFIG.farmDelay, function(v)
    CONFIG.farmDelay = v
end)

UI.sliders.farmRange = makeSlider(farmTab, "Distância de farm (studs)", 5, 60, CONFIG.farmRange, function(v)
    CONFIG.farmRange = v
end)

UI.refreshMobs = function()
    clearList(mobList)
    setStatus("Escaneando mobs matáveis...")
    task.wait()

    local list = listEnemies(false)
    if #list == 0 then
        addListButton(mobList, "Nenhum mob matável encontrado", function() end, C.panel)
        setStatus("Nenhum mob matável. A pasta Workspace.Enemies existe?", true)
        return
    end

    local total = 0
    for _, entry in ipairs(list) do
        total = total + entry.count
        addListButton(mobList, mobText(entry.name, entry.level, entry.count), function()
            setFarmTarget(entry.name, entry.level, entry.count)
            setStatus("Alvo selecionado: " .. mobText(entry.name, entry.level))
        end)
    end

    setStatus("Mobs: " .. #list .. " tipos, " .. total .. " no servidor")
end

--==================== ABA RAID ====================
local raidTab = makeTab("Raid", 2)

makeLabel(raidTab, "Auto Raid completo: compra/equipa o Microchip, entra na raid, fica pairando alto sobre cada ilha e mata os mobs na hora.", true)

makeSection(raidTab, "Auto Raid")

UI.raidStatusLabel = makeLabel(raidTab, "Status: ocioso", true)

UI.raidChipBtn = makeButton(raidTab, "Chip: " .. State.raidElement, function()
    local idx = table.find(RAID_ELEMENTS, State.raidElement) or 1
    idx = (idx % #RAID_ELEMENTS) + 1
    State.raidElement = RAID_ELEMENTS[idx]
    UI.raidChipBtn.Text = "Chip: " .. State.raidElement
    setStatus("Chip da raid: " .. State.raidElement)
end)

makeButton(raidTab, "Comprar chip no NPC", function()
    fireRemote("CommF_", "RaidsNpc", "Select", State.raidElement)
    setStatus("Pedido de chip enviado: " .. State.raidElement)
end)

makeButton(raidTab, "Checar raid", function()
    local c = getRemote("CommF_")
    if not c then
        setStatus("Remote CommF_ não encontrado", true)
        return
    end
    local ok, res = pcall(function() return c:InvokeServer("RaidsNpc", "Check") end)
    setStatus("Raid check: " .. tostring(ok and res or "falhou"))
end)

UI.toggles.autoRaid = makeToggle(raidTab, "Auto Raid", false, function(on)
    State.autoRaid = on
    if on then
        if UI.toggles.autoFarm and UI.toggles.autoFarm.get() then
            UI.toggles.autoFarm.set(false)
        end
        if UI.toggles.autoQuest and UI.toggles.autoQuest.get() then
            UI.toggles.autoQuest.set(false)
        end
        -- fly usa BodyVelocity e brigaria com o hover da raid
        if State.fly then
            if UI.toggles.fly and UI.toggles.fly.get() then
                UI.toggles.fly.set(false)
            else
                stopFly()
            end
        end
        if UI.toggles.instantFarm and not UI.toggles.instantFarm.get() then
            UI.toggles.instantFarm.set(true)
        else
            State.instantFarm = true
            forceSimulationRadius()
        end
        State.raidLastStart = 0
        State.raidIsland = nil
        State.raidClearSince = nil
        setupRaidListener()
        task.spawn(raidLoop)
        setRaidStatus("Auto Raid ligado (chip " .. State.raidElement .. ")")
    else
        State.raidInRaid = false
        State.raidIsland = nil
        State.raidClearSince = nil
        raidStopHover()
        setRaidStatus("Auto Raid desligado")
    end
end)

makeLabel(raidTab, "Sem chip, o Auto Raid tenta comprar no RaidsNpc. Funciona no 2º e 3º mar; no 1º mar a raid não existe.", true)

makeSection(raidTab, "Awakening")

UI.toggles.autoAwaken = makeToggle(raidTab, "Auto Awakening", false, function(on)
    State.autoAwaken = on
    if on then
        task.spawn(awakenLoop)
        setStatus("Auto Awakening ligado")
    else
        setStatus("Auto Awakening desligado")
    end
end)

makeLabel(raidTab, "Awakening usa CommF_ Awakener Check/Awaken a cada 2.5s.", true)

makeSection(raidTab, "Ilhas da raid")

makeLabel(raidTab, "O Auto Raid fica pairando ~55 studs acima do centro da ilha, mata tudo no raio e só avança quando a ilha está limpa.", true)

--==================== ABA BOSS ====================
local bossTab = makeTab("Boss", 3)

makeLabel(bossTab, "Bosses vivos no servidor. Clique para selecionar e ligue o Auto Boss.", true)

makeSection(bossTab, "Bosses")

makeButton(bossTab, "Atualizar lista de bosses", function()
    if UI.refreshBosses then UI.refreshBosses() end
end)

local bossList = makeScrollList(bossTab, 160)
UI.lists.bosses = bossList

UI.bossLabel = makeLabel(bossTab, "Boss: nenhum")

makeButton(bossTab, "TP para boss selecionado", function()
    if State.bossTarget == "" then
        setStatus("Selecione um boss primeiro", true)
        return
    end
    local mob = nearestEnemy(State.bossTarget)
    if not mob then
        setStatus("Boss não encontrado no servidor", true)
        return
    end
    local hrp = mob:FindFirstChild("HumanoidRootPart")
    if not hrp then
        setStatus("Boss sem HumanoidRootPart", true)
        return
    end
    boostTarget(mob)
    teleport(hrp.Position + Vector3.new(0, 3, -3), State.bossTarget)
end)

UI.toggles.autoBoss = makeToggle(bossTab, "Auto Boss", false, function(on)
    if on then
        if State.bossTarget == "" then
            local list = listEnemies(true)
            if #list > 0 then
                State.bossTarget = list[1].name
                if UI.bossLabel then
                    UI.bossLabel.Text = "Boss: " .. mobText(list[1].name, list[1].level, list[1].count)
                end
            else
                setStatus("Nenhum boss vivo no servidor", true)
                if UI.toggles.autoBoss then UI.toggles.autoBoss.set(false) end
                return
            end
        end
        startBoss()
        setStatus("Auto boss ligado: " .. State.bossTarget)
    else
        stopBoss()
        setStatus("Auto boss desligado")
    end
end)

makeButton(bossTab, "Reequipar arma", function()
    local tool = equipWeapon()
    if tool then
        setStatus("Arma equipada: " .. tool.Name)
    else
        setStatus("Nenhuma arma na mochila", true)
    end
end)

makeLabel(bossTab, "O boss precisa estar vivo e na pasta Enemies.", true)

UI.refreshBosses = function()
    clearList(bossList)
    setStatus("Escaneando bosses...")
    task.wait()

    local list = listEnemies(true)
    if #list == 0 then
        addListButton(bossList, "Nenhum boss vivo agora", function() end, C.panel)
        setStatus("Nenhum boss vivo no servidor", true)
        return
    end

    local total = 0
    for _, entry in ipairs(list) do
        total = total + entry.count
        addListButton(bossList, mobText(entry.name, entry.level, entry.count), function()
            State.bossTarget = entry.name
            if UI.bossLabel then
                UI.bossLabel.Text = "Boss: " .. mobText(entry.name, entry.level, entry.count)
            end
            setStatus("Boss selecionado: " .. mobText(entry.name, entry.level))
        end)
    end

    setStatus("Bosses: " .. #list .. " tipos, " .. total .. " no servidor")
end

--==================== ABA COMBAT ====================
local combatTab = makeTab("Combat", 4)

makeLabel(combatTab, "Skills usam o RemoteFunction da arma equipada (Z/X/C). Precisa de alvo vivo perto.", true)

makeSection(combatTab, "Skills")

UI.toggles.skillZ = makeToggle(combatTab, "Auto Skill Z", false, function(on)
    State.skillZ = on
    syncSkills()
end)

UI.toggles.skillX = makeToggle(combatTab, "Auto Skill X", false, function(on)
    State.skillX = on
    syncSkills()
end)

UI.toggles.skillC = makeToggle(combatTab, "Auto Skill C", false, function(on)
    State.skillC = on
    syncSkills()
end)

UI.toggles.fastAttack = makeToggle(combatTab, "Ataque rápido", false, function(on)
    toggleFastAttack(on)
end)

makeSection(combatTab, "Ataque")

UI.toggles.autoAttack = makeToggle(combatTab, "Auto Ataque", false, function(on)
    if on then
        startAttack()
        setStatus("Auto ataque ligado")
    else
        stopAttack()
        setStatus("Auto ataque desligado")
    end
end)

makeButton(combatTab, "Reequipar arma", function()
    local tool = equipWeapon()
    if tool then
        setStatus("Arma equipada: " .. tool.Name)
    else
        setStatus("Nenhuma arma na mochila", true)
    end
end)

UI.sliders.attackDelay = makeSlider(combatTab, "Delay do ataque (s)", 0.05, 0.5, CONFIG.attackDelay, function(v)
    CONFIG.attackDelay = v
end)

makeLabel(combatTab, "Ataque rápido reduz o delay para ~0.03s. Mais DPS, mais detectável.", true)

makeSection(combatTab, "Kill Aura")

UI.toggles.killAura = makeToggle(combatTab, "Kill Aura instantâneo", false, function(on)
    State.killAura = on
    if on then
        installHitIdCapture()
        forceSimulationRadius()
        task.spawn(killAuraLoop)
        local modo = AURA.simOk and "morte direta" or "remotes de hit"
        setStatus("Kill aura instantâneo ligado (" .. modo .. ", raio " .. CONFIG.killAuraRange .. " studs)")
    else
        setStatus("Kill aura desligado")
    end
end)

UI.sliders.killAuraRange = makeSlider(combatTab, "Raio do Kill Aura (studs)", 10, 100, CONFIG.killAuraRange, function(v)
    CONFIG.killAuraRange = v
end)

makeLabel(combatTab, "Kill Aura instantâneo usa sethiddenproperty(SimulationRadius) + Humanoid.Health = 0, o mesmo método dos hubs públicos. Não afeta jogadores.", true)

makeSection(combatTab, "Auto stats")

UI.toggles.autoStats = makeToggle(combatTab, "Auto Stats", false, function(on)
    State.autoStats = on
    if on then
        task.spawn(statLoop)
        setStatus("Auto stats: " .. State.statTarget)
    else
        setStatus("Auto stats desligado")
    end
end)

local statBtn
statBtn = makeButton(combatTab, "Atributo: " .. State.statTarget, function()
    local idx = 1
    for i, s in ipairs(STATS) do
        if s == State.statTarget then
            idx = i
            break
        end
    end
    idx = (idx % #STATS) + 1
    State.statTarget = STATS[idx]
    if statBtn then statBtn.Text = "Atributo: " .. State.statTarget end
    setStatus("Atributo escolhido: " .. State.statTarget)
end)
UI.statBtn = statBtn

makeLabel(combatTab, "Auto Stats gasta os pontos via CommF_ AddStat, 1 por ciclo.", true)

--==================== ABA ESP ====================
local espTab = makeTab("ESP", 5)

makeLabel(espTab, "Destaques no mundo. Desligue se o FPS cair.", true)

makeSection(espTab, "Destaques")

UI.toggles.espPlayers = makeToggle(espTab, "ESP jogadores", false, function(on)
    State.espPlayers = on
    syncESP()
end)

UI.toggles.espBosses = makeToggle(espTab, "ESP bosses", false, function(on)
    State.espBosses = on
    syncESP()
end)

UI.toggles.espFruits = makeToggle(espTab, "ESP frutas", false, function(on)
    State.espFruits = on
    syncESP()
end)

UI.toggles.espChests = makeToggle(espTab, "ESP baús", false, function(on)
    State.espChests = on
    syncESP()
end)

UI.toggles.fruitNotify = makeToggle(espTab, "Notificador de frutas", false, function(on)
    State.fruitNotify = on
    if on then
        State.seenFruits = {}
        State.fruitNotifyStarted = false
        setupFruitRadar()
        updateFruitSpawnLabel()
        task.spawn(fruitNotifyLoop)
        setStatus("Notificador de frutas ligado")
    else
        if UI.fruitSpawnLabel then
            UI.fruitSpawnLabel.Text = "Spawn: ligue o notificador para medir"
        end
        setStatus("Notificador de frutas desligado")
    end
end)

makeSection(espTab, "Frutas")

UI.fruitSpawnLabel = makeLabel(espTab, "Spawn: ligue o notificador para medir", true)

makeButton(espTab, "Resetar timer de spawn", function()
    State.fruitSpawnLast = nil
    State.fruitSpawnIntervals = {}
    State.fruitSpawnEstimate = nil
    State.fruitSpawnApprox = false
    updateFruitSpawnLabel()
    setStatus("Timer de spawn resetado")
end)

makeLabel(espTab, "Spawn natural: ~60 min (45 min no fim de semana) e a fruta some em 20 min. O timer é estimado pelos spawns detectados.", true)

makeSection(espTab, "Guardar frutas")

UI.toggles.fruitAutoStore = makeToggle(espTab, "Guardar fruta automaticamente", false, function(on)
    State.fruitAutoStore = on
    State.fruitStoreWarned = {}
    if on then
        task.spawn(fruitStoreLoop)
        setStatus("Auto guardar fruta ligado (" .. State.fruitStoreCapacity .. " slot(s) por fruta)")
    else
        setStatus("Auto guardar fruta desligado")
    end
end)

UI.sliders.fruitStoreCapacity = makeSlider(espTab, "Espaço por fruta (slots)", 1, 50, 1, function(v)
    State.fruitStoreCapacity = math.max(1, math.floor(tonumber(v) or 1))
    State.fruitStoreWarned = {}
end)

makeButton(espTab, "Guardar frutas da mochila agora", function()
    local stored, skipped, failed = fruitStorePass(true)
    if stored == 0 and skipped == 0 and failed == 0 then
        setStatus("Nenhuma fruta na mochila")
    end
end)

makeLabel(espTab, "O jogo não informa o espaço no cliente. Ajuste os slots por fruta (padrão 1; +1 por Fruit Storage). O hub conta o que já está guardado via getInventoryFruits e só guarda se houver vaga.", true)

makeButton(espTab, "Atualizar lista de frutas", function()
    if UI.refreshFruits then UI.refreshFruits() end
end)

local fruitList = makeScrollList(espTab, 140)
UI.lists.fruits = fruitList
UI.fruitLabel = makeLabel(espTab, "Fruta: nenhuma")

makeButton(espTab, "TP para fruta selecionada", function()
    if not State.fruitTarget or not State.fruitTarget.Parent then
        setStatus("Selecione uma fruta na lista", true)
        return
    end
    local pos = fruitPosition(State.fruitTarget)
    if pos then
        teleport(pos + Vector3.new(0, 3, 0), State.fruitTarget.Name)
    else
        setStatus("Fruta sem posição", true)
    end
end)

makeButton(espTab, "Puxar fruta selecionada (grab)", function()
    if not State.fruitTarget or not State.fruitTarget.Parent then
        setStatus("Selecione uma fruta na lista", true)
        return
    end
    -- revalida: garante que o alvo ainda é fruta (e não uma ilha/modelo grande)
    if not isFruitTool(State.fruitTarget) then
        State.fruitTarget = nil
        setStatus("Alvo não é fruta (lista desatualizada)", true)
        return
    end
    local handle = State.fruitTarget:FindFirstChild("Handle")
    local hrp = getHRP()
    if handle and handle:IsA("BasePart") and hrp then
        pcall(function() handle.CFrame = hrp.CFrame end)
        setStatus("Fruta puxada: " .. State.fruitTarget.Name)
    else
        setStatus("Fruta sem Handle", true)
    end
end)

makeButton(espTab, "Limpar ESP", function()
    State.espPlayers = false
    State.espFruits = false
    State.espChests = false
    State.espBosses = false
    if UI.toggles.espPlayers then UI.toggles.espPlayers.set(false) end
    if UI.toggles.espFruits then UI.toggles.espFruits.set(false) end
    if UI.toggles.espChests then UI.toggles.espChests.set(false) end
    if UI.toggles.espBosses then UI.toggles.espBosses.set(false) end
    clearESP()
    setStatus("ESP limpo")
end)

UI.refreshFruits = function()
    clearList(fruitList)
    setStatus("Escaneando frutas...")
    task.wait()

    local list = collectFruits()
    if #list == 0 then
        addListButton(fruitList, "Nenhuma fruta no chão", function() end, C.panel)
        setStatus("Nenhuma fruta encontrada")
        return
    end

    for _, fruit in ipairs(list) do
        addListButton(fruitList, fruit.Name, function()
            State.fruitTarget = fruit
            if UI.fruitLabel then UI.fruitLabel.Text = "Fruta: " .. fruit.Name end
            setStatus("Fruta selecionada: " .. fruit.Name)
        end)
    end

    setStatus("Frutas no chão: " .. #list)
end

--==================== ABA UTIL ====================
local utilTab = makeTab("Util", 6)

makeLabel(utilTab, "Clique em um jogador para selecionar. Use o toggle para TP ou espectar.", true)

makeSection(utilTab, "Jogadores")

makeButton(utilTab, "Atualizar lista de jogadores", function()
    if UI.refreshPlayers then UI.refreshPlayers() end
end)

local playerList = makeScrollList(utilTab, 170)
UI.lists.players = playerList

UI.playerLabel = makeLabel(utilTab, "Selecionado: nenhum")

makeButton(utilTab, "TP para jogador selecionado", function()
    if not State.selectedPlayer then
        setStatus("Clique em um jogador na lista primeiro", true)
        return
    end
    local p = State.selectedPlayer
    if p and p.Character then
        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            teleport(hrp.Position + Vector3.new(0, 3, 0), p.Name)
        else
            setStatus("Jogador sem personagem", true)
        end
    else
        setStatus("Jogador sem personagem", true)
    end
end)

UI.toggles.spectate = makeToggle(utilTab, "Espectar jogador selecionado", false, function(on)
    if on then
        local p = State.selectedPlayer
        if not p then
            setStatus("Clique em um jogador na lista primeiro", true)
            if UI.toggles.spectate then UI.toggles.spectate.set(false) end
            return
        end
        if not spectate(p) then
            if UI.toggles.spectate then UI.toggles.spectate.set(false) end
        end
    else
        stopSpectate()
    end
end)

UI.toggles.antiAfk = makeToggle(utilTab, "Anti-AFK", true, function(on)
    if on then
        startAntiAfk()
        if UI.antiAfkLabel then UI.antiAfkLabel.Text = "Anti-AFK: ativo" end
    else
        stopAntiAfk()
        if UI.antiAfkLabel then UI.antiAfkLabel.Text = "Anti-AFK: desligado" end
    end
end)

UI.antiAfkLabel = makeLabel(utilTab, "Anti-AFK: ativo")

local coordBox = makeTextbox(utilTab, "Coordenadas: x,y,z", function() end)

makeButton(utilTab, "TP para coordenadas", function()
    local x, y, z = coordBox.Text:match("([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)")
    if x and y and z then
        teleport(Vector3.new(tonumber(x), tonumber(y), tonumber(z)), "coordenadas")
    else
        setStatus("Formato inválido. Use x,y,z", true)
    end
end)

makeSection(utilTab, "Movimento")

UI.toggles.fly = makeToggle(utilTab, "Fly (WASD + Space/Ctrl)", false, function(on)
    if on then
        if not startFly() then
            setStatus("Fly: sem personagem", true)
            if UI.toggles.fly then UI.toggles.fly.set(false) end
        else
            setStatus("Fly ligado")
        end
    else
        stopFly()
        setStatus("Fly desligado")
    end
end)

UI.toggles.noclip = makeToggle(utilTab, "Noclip", false, function(on)
    applyNoclip(on)
    setStatus(on and "Noclip ligado" or "Noclip desligado")
end)

UI.toggles.infiniteJump = makeToggle(utilTab, "Pulo infinito", false, function(on)
    State.infiniteJump = on
    setStatus(on and "Pulo infinito ligado" or "Pulo infinito desligado")
end)

UI.sliders.flySpeed = makeSlider(utilTab, "Velocidade do voo", 20, 200, CONFIG.flySpeed, function(v)
    CONFIG.flySpeed = v
end)

makeSection(utilTab, "Servidor")

UI.toggles.autoRejoin = makeToggle(utilTab, "Auto rejoin", false, function(on)
    setAutoRejoin(on)
    setStatus(on and "Auto rejoin ligado" or "Auto rejoin desligado")
end)

makeButton(utilTab, "Server hop (trocar servidor)", function()
    serverHop()
end)

makeButton(utilTab, "Reconectar neste servidor", function()
    rejoinServer()
end)

UI.refreshPlayers = function()
    clearList(playerList)
    local count = 0
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            count = count + 1
            addListButton(playerList, p.Name, function()
                State.selectedPlayer = p
                if UI.playerLabel then
                    UI.playerLabel.Text = "Selecionado: " .. p.Name
                end
                if UI.toggles.spectate and UI.toggles.spectate.get() then
                    spectate(p)
                end
                setStatus("Jogador selecionado: " .. p.Name)
            end)
        end
    end
    if count == 0 then
        addListButton(playerList, "Nenhum outro jogador", function() end, C.panel)
    end
end

--==================== ABA ILHAS ====================
local islandsTab = makeTab("Ilhas", 7)

local function goIsland(island)
    if island.entrance then
        if fireRemote("CommF_", "requestEntrance", island.entrance) then
            setStatus("Entrando: " .. island.name)
        else
            setStatus("Falha ao entrar: " .. island.name, true)
        end
        return
    end
    teleport(island.pos, island.name)
end

local function buildIslands()
    for _, child in ipairs(islandsTab:GetChildren()) do
        if child:IsA("GuiObject") then child:Destroy() end
    end

    makeLabel(islandsTab, "Viajar de mar (usa o teleporte do jogo):", true)
    for _, w in ipairs(WORLD_TRAVEL) do
        makeButton(islandsTab, "Ir para o " .. w.name, function()
            if fireRemote("CommF_", w.remote) then
                setStatus("Viajando para o " .. w.name .. "...")
            else
                setStatus("Falha ao viajar. Remote CommF_ não encontrado.", true)
            end
        end)
    end

    local sea = CURRENT_SEA or 1
    local seaNames = { [1] = "Primeiro Mar", [2] = "Segundo Mar", [3] = "Terceiro Mar" }
    makeLabel(islandsTab, "Ilhas do " .. (seaNames[sea] or "Primeiro Mar") .. ":", true)

    for _, island in ipairs(ISLANDS[sea] or ISLANDS[1]) do
        makeButton(islandsTab, island.name, function()
            goIsland(island)
        end)
    end
end

buildIslands()

--==================== ABA CONFIG ====================
local configTab = makeTab("Config", 8)

makeLabel(configTab, "Config: " .. CONFIG.version)
makeLabel(configTab, "PC · sem key · anti-detecção ativa")

makeSection(configTab, "Geral")

makeButton(configTab, "Salvar config", function()
    saveConfig()
end)

makeButton(configTab, "Carregar config", function()
    loadConfig()
end)

makeLabel(configTab, "Atalhos: RightShift mostra/esconde a janela · End descarrega o hub.", true)

makeButton(configTab, "Descarregar hub (parar tudo e fechar)", function()
    killSwitch()
    pcall(function() gui:Destroy() end)
end, C.danger)

makeButton(configTab, "TP para o spawn", function()
    local sp = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
    local pos = sp and sp.Position or State.spawnPos
    if pos then
        teleport(pos + Vector3.new(0, 3, 0), "spawn")
    else
        setStatus("Spawn não encontrado", true)
    end
end)

makeButton(configTab, "Teste de TP (15 studs)", function()
    local hrp = getHRP()
    if not hrp then
        setStatus("Sem personagem", true)
        return
    end
    local target = hrp.Position + hrp.CFrame.LookVector * 15
    teleport(target, "teste")
end)

makeButton(configTab, "Reconectar remotes", function()
    remoteCache = {}
    setStatus("Cache de remotes limpo")
end)

makeLabel(configTab, "Anti-detecção: jitter nos delays, rate limit de remote, pcall em tudo, auto-pausa em erro, sem prints.", true)

--==================== BOOT ====================
activeTab = "Farm"
for n, t in pairs(tabs) do
    local active = (n == activeTab)
    t.frame.Visible = active
    t.btn.BackgroundTransparency = active and 0 or 1
    t.btn.BackgroundColor3 = active and C.accent or C.panel
    t.btn.TextColor3 = active and Color3.fromRGB(255, 255, 255) or C.sub
end

local bootHRP = getHRP()
if bootHRP then State.spawnPos = bootHRP.Position end
local bootHum = getHum()
if bootHum and bootHum.WalkSpeed > 0 then State.baseWalkSpeed = bootHum.WalkSpeed end
watchTools(getChar())

startAntiAfk()
if UI.toggles.antiAfk then UI.toggles.antiAfk.set(true) end

task.spawn(function()
    task.wait(1)
    safeCall(UI.refreshMobs)
    safeCall(UI.refreshBosses)
    safeCall(UI.refreshPlayers)
    safeCall(UI.refreshFruits)
end)

Players.PlayerAdded:Connect(function()
    if UI.refreshPlayers then safeCall(UI.refreshPlayers) end
end)
Players.PlayerRemoving:Connect(function()
    if UI.refreshPlayers then safeCall(UI.refreshPlayers) end
end)

LP.CharacterAdded:Connect(function(char)
    task.wait(1)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp and not State.spawnPos then State.spawnPos = hrp.Position end
    local h = char:FindFirstChildOfClass("Humanoid")
    if h and h.WalkSpeed > 0 then State.baseWalkSpeed = h.WalkSpeed end
    watchTools(char)
    if State.spectateTarget then stopSpectate() end
    if State.fly then stopFly() end
    if UI.toggles.fly and UI.toggles.fly.get() then UI.toggles.fly.set(false) end
end)

notify("Hub carregado · " .. CONFIG.version)
setStatus("Pronto")

end)

if not bootOk then
    local sg = Instance.new("ScreenGui")
    sg.Name = "ERR_" .. tostring(math.random(100000, 999999))
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 1000
    if GUI_PARENT then sg.Parent = GUI_PARENT end

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 640, 0, 240)
    lbl.Position = UDim2.new(0.5, -320, 0.5, -120)
    lbl.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
    lbl.BorderSizePixel = 0
    lbl.TextColor3 = Color3.fromRGB(255, 90, 90)
    lbl.TextSize = 14
    lbl.Font = Enum.Font.Code
    lbl.TextWrapped = true
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextYAlignment = Enum.TextYAlignment.Top
    lbl.Text = "  HUB ERRO:\n\n" .. tostring(bootErr)
    lbl.Parent = sg

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 12)
    pad.PaddingLeft = UDim.new(0, 12)
    pad.PaddingRight = UDim.new(0, 12)
    pad.Parent = lbl

    warn("[Hub] " .. tostring(bootErr))
end
