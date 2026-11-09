-- Teste mínimo de GUI.
-- Rode isto no executor. Se aparecer o quadrado azul "GUI OK",
-- o ambiente aceita criar GUI e o problema está no hub.
-- Se não aparecer, o executor bloqueia a criação de GUI.

local parent
if gethui then
    local ok, hui = pcall(gethui)
    if ok then parent = hui end
end

if not parent then
    local ok, pg = pcall(function()
        return game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui", 5)
    end)
    if ok then parent = pg end
end

if not parent then
    local ok, cg = pcall(function()
        return game:GetService("CoreGui")
    end)
    if ok then parent = cg end
end

if not parent then
    warn("[teste] nenhum parent de GUI disponível")
    return
end

local sg = Instance.new("ScreenGui")
sg.Name = "TESTE_" .. tostring(math.random(1000, 9999))
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.DisplayOrder = 9999
sg.Parent = parent

local f = Instance.new("Frame")
f.Size = UDim2.new(0, 300, 0, 120)
f.Position = UDim2.new(0.5, -150, 0.5, -60)
f.BackgroundColor3 = Color3.fromRGB(88, 140, 255)
f.BorderSizePixel = 0
f.Parent = sg

local c = Instance.new("UICorner")
c.CornerRadius = UDim.new(0, 10)
c.Parent = f

local t = Instance.new("TextLabel")
t.Size = UDim2.new(1, 0, 1, 0)
t.BackgroundTransparency = 1
t.Text = "GUI OK"
t.TextColor3 = Color3.new(1, 1, 1)
t.TextSize = 24
t.Font = Enum.Font.GothamBold
t.Parent = f

warn("[teste] parent usado: " .. tostring(parent))
