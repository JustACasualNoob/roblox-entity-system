local RunService = game:GetService("RunService")

local Entity = require(script.Entity)

local ExampleData = {
	Damage = 5,
	AttackCd = 1,
	DefaultWalkspeed = 10,
	DetectionRange = 50,
	BreakoffRange = 100,
	AttackRange = 5,
}

-- Making a dummy model
local ExampleModel = Instance.new("Model")
local Root = Instance.new("Part")
Root.Parent = ExampleModel
Root.Name = "HumanoidRootPart"

local Humanoid = Instance.new("Humanoid")
Humanoid.Parent = ExampleModel

local POS = {
	Min = -100,
	Max = 100,
}

local entities = {} :: {[Model]: Entity.Entity}

-- Spawns 10 entities randomly
for _i = 1, 10 do
	local model = ExampleModel:clone()
	local pos = Vector3.new(math.random(POS.Min, POS.Max), 5, math.random(POS.Min, POS.Max))
	entities[model] = Entity.new({ model = model, entityData = ExampleData, position = pos })
end

-- Main loop
RunService.Heartbeat:Connect(function()
    for _, entity in pairs(entities) do
        entity:Update()
    end
end)
