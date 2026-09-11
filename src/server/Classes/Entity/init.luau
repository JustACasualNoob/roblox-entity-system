local Entity = {}
Entity.__index = Entity

local Players = game:GetService("Players")

type entityData = {
    Damage: number,
    AttackCd: number,
    DefaultWalkspeed: number,
    DetectionRange: number,
    BreakoffRange: number,
    AttackRange: number
}

export type Entity = typeof(setmetatable({} :: {
	Model: Model,
    Data: entityData,
    Root: Part,
    Humanoid: Humanoid,
    StateToFunction: {[string]: (Entity) -> ()},
    NextAllowedAttack: number,
    Active: boolean,
    Target: Model?,
    LastState: string,
    StunTask: thread?,
}, Entity))

local STATES = {
	["Idle"] = "Idle",
	["Chasing"] = "Chasing",
	["Attacking"] = "Attacking",
	["Stunned"] = "Stunned",
}

local STUN_TIME = 2
local ENTITY_TAG = "EXAMPLE_TAG"

function Entity.new(data: {model: Model, entityData: entityData, position: Vector3}): Entity
	local self = setmetatable({}, Entity)

	self.Model = data.model
	self.Data = data.entityData

	self.Root = self.Model:WaitForChild("HumanoidRootPart")
	self.Humanoid = self.Model:WaitForChild("Humanoid")

	--[[ Optionally hook animations:
        self.Animator = AnimationWrapper.new(self.Model, {
            ["Idle"] = {
                Id = "rbxassetid://someNumber",
                Looped = true,
                Group = "Movement",
                Priority = Enum.AnimationPriority.Idle
            },

            ["Walk"] = {
                Id = "rbxassetid://someNumber",
                Looped = true,
                Group = "Movement",
                Priority = Enum.AnimationPriority.Movement
            }
        })

        self.StateToAnim = {
            ["Idle"] = "Idle",
            ["Chasing"] = "Walk"
	    }
    ]]

	self.Model.Parent = workspace.Enemies
	self.Model:AddTag(ENTITY_TAG)

	self.StateToFunction = {
		["Idle"] = self.ProcessIdle,
		["Chasing"] = self.ProcessChase,
		["Attacking"] = self.ProcessAttack,
		["Stunned"] = self.ProcessStunned,
	}

	self.NextAllowedAttack = 0
	self.Active = true

	self.Target = nil

	self.LastState = STATES.Idle
	self:SetState(STATES.Idle)
    self:SetCF(CFrame.new(data.position))

	return self
end

function Entity:SetCF(cf: CFrame)
	self.Model:PivotTo(cf)
end

function Entity:SetState(new: typeof(STATES))
	self.LastState = self.State
	self.State = new

	--[[
        local anim = self.StateToAnim[new]
        if anim then
            self.Animator:Play(anim)
        end
    ]]
end

function Entity:Update()
	if not self.Active then
		return
	end

	local func = self.StateToFunction[self.State]
	if not func then
		warn(self.State, "is an invalid state!")
		return
	end

	func(self)
end

function Entity.ProcessAttack(self: Entity)
	if not self.Target then
		self:SetState(STATES.Idle)
		return
	end

	if os.clock() < self.NextAllowedAttack then
		self.Humanoid:Move(Vector3.zero)
		return
	end
	self.NextAllowedAttack = os.clock() + self.Data.AttackCd

	-- check if still in attack range
	local targetRoot = self.Target:FindFirstChild("HumanoidRootPart")
    local targetHumanoid = self.Target:FindFirstChild("Humanoid") :: Humanoid
	if targetRoot then
		local vec = (self.Root.Position - targetRoot.Position)
		local distSq = vec:Dot(vec)
        local attackRangeSq = self.Data.AttackRange*self.Data.AttackRange

		if distSq > attackRangeSq then
			self:SetState(STATES.Chasing)
		else
			self.NextAllowedAttack = os.clock() + self.Data.AttackCd
			self.Humanoid:Move(Vector3.zero)
			targetHumanoid:TakeDamage(self.Data.Damage)
		end
	else
		self.Target = nil
		self:SetState(STATES.Idle)
	end
end

function Entity.ProcessIdle(self: Entity)
	if not self.Active then
		self.Active = true
	end

	if self.Humanoid.WalkSpeed == 0 then
		self.Humanoid.WalkSpeed = self.Data.DefaultWalkspeed
	end

	if self.Humanoid.MoveDirection.Magnitude > 0 then
		self.Humanoid:Move(Vector3.zero)
	end

	-- search for targets
	local nearestDist = math.huge
	local nearestTarget = nil

	for _, player: Player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char then
			local root = char:FindFirstChild("HumanoidRootPart")
			if root then
				local vec = (self.Root.Position - root.Position)
				local distSq = vec:Dot(vec)
                local detectionRangeSq = self.Data.DetectionRange*self.Data.DetectionRange

				if distSq < detectionRangeSq and distSq < nearestDist then
					nearestDist = distSq
					nearestTarget = char
				end
			end
		end
	end

	self.Target = nearestTarget
	if self.Target then
		self:SetState(STATES.Chasing)
	end
end

function Entity.ProcessChase(self: Entity)
	if not self.Target then
		self:SetState(STATES.Idle)
		return
	end

	local targetRoot = self.Target:FindFirstChild("HumanoidRootPart")
	if targetRoot then
		local vec = (targetRoot.Position - self.Root.Position)
		self.Humanoid:Move(vec)

		local distSq = vec:Dot(vec)
        local breakoffRangeSq = self.Data.BreakoffRange*self.Data.BreakoffRange
        local attackRangeSq = self.Data.AttackRange*self.Data.AttackRange

		if distSq > breakoffRangeSq then
			self.Target = nil
			self:SetState(STATES.Idle)
		elseif distSq < attackRangeSq then
			self:SetState(STATES.Attacking)
		end
	else
		self.Target = nil
		self:SetState(STATES.Idle)
	end
end

function Entity.ProcessStunned(self: Entity)
	if self.Active then
		self.Active = false
	end

	self.Humanoid.WalkSpeed = 0
	if self.StunTask then
		task.cancel(self.StunTask)
	end

	self.StunTask = task.delay(STUN_TIME, function()
		self:SetState(STATES.Idle)
	end)
end

return Entity
