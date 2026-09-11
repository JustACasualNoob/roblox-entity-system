# Roblox Entity System
A reusable entity system originally developed for a Roblox combat game.
> This repository is a standalone extraction of an entity system originally built for a larger Roblox combat project. Project-specific dependencies and assets were removed for clarity.

## Purpose
The project needed a consistent way to create, track, update, and destroy gameplay entities without tightly coupling systems together.

## Architecture

- **Data-driven configuration** — combat values such as damage, range, cooldowns, and movement are passed into each entity rather than hardcoded.
- **Class-based lifecycle** — entity creation, updates, state changes, and cleanup are contained within the `Entity` class.
- **State machine** — entities switch between states such as Idle, Chasing, Attacking, and Stunned.
- **Behavior dispatch** — states map directly to processing functions through `StateToFunction`, keeping state logic modular.
- **Centralized update flow** — each entity exposes a single `Update()` entry point for processing its current behavior.
- **Typed Luau** — entity data and runtime fields are explicitly typed.

## What I worked on
I designed and implemented the entity architecture, state handling, and update flow.

## Example

```lua
local RunService = game:GetService("RunService")
local Entity = require(path.to.Entity)

local entity = Entity.new({
	model = enemyModel,
	entityData = {
		Damage = 15,
		AttackCd = 1.2,
		DefaultWalkspeed = 16,
		DetectionRange = 50,
		BreakoffRange = 70,
		AttackRange = 5,
	},
	position = Vector3.new(0, 5, 0),
})

-- example behavior
entity:SetState("Chasing")
RunService.Heartbeat:Connect(function()
  entity:Update()
end)
```
