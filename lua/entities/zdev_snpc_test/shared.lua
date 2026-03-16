local _f = 'entities/zdev_snpc_test/shared.lua'
--[[■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
	ZDEV - Test NPC (Shared)
----------------------------------------------------------
	A Citizen NPC that searches for chairs to sit in
	By ZCOM Studios
	Copyright (c) 2020-2025 by ZCOM Studios, All rights reserved.
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■]]

ENT.Base = 'base_ai'
ENT.Type = 'ai'

ENT.PrintName = 'Test NPC (Chair Seeker)'
ENT.Author = 'ZCOM Studios'
ENT.Category = 'ZDEV NPCs'
ENT.Purpose = 'Searches for chairs to sit in'
ENT.Instructions = 'Spawn near chairs to watch it find and sit in them'

ENT.Spawnable = true
ENT.AdminOnly = false
ENT.AutomaticFrameAdvance = true

-- Model configuration - Citizen models
ENT.CitizenModels = {
	'models/humans/group01/male_01.mdl',
	'models/humans/group01/male_02.mdl',
	'models/humans/group01/male_03.mdl',
	'models/humans/group01/male_04.mdl',
	'models/humans/group01/female_01.mdl',
	'models/humans/group01/female_02.mdl',
	'models/humans/group01/female_03.mdl',
}

-- Health settings
ENT.StartHealth = 100
ENT.MaxHealthValue = 100

-- Behavior settings
ENT.SearchRadius = 1500       -- How far to search for chairs
ENT.SitDuration = 20          -- How long to sit before standing
ENT.WanderRadius = 500        -- How far to wander when searching
ENT.LookAroundTime = 3        -- Time spent looking around

-- Chair model patterns to detect
ENT.ChairPatterns = {
	'chair', 'seat', 'bench', 'stool', 'sofa', 'couch', 'furniture'
}

-- NPC States
ENT.STATE_IDLE = 0
ENT.STATE_SEARCHING = 1
ENT.STATE_WALKING_TO_CHAIR = 2
ENT.STATE_SITTING = 3
ENT.STATE_WANDERING = 4
ENT.STATE_LOOKING_AROUND = 5

-- Sounds
ENT.Sounds = {
	Idle = 'vo/npc/male01/hi01.wav',
	FoundChair = 'vo/npc/male01/yeah02.wav',
	Sitting = 'vo/npc/male01/nice.wav',
	Searching = 'vo/npc/male01/question05.wav',
}

function ENT:SetupDataTables()
	self:NetworkVar('Int', 0, 'BehaviorState')
	self:NetworkVar('Bool', 0, 'IsSitting')
	self:NetworkVar('Entity', 0, 'TargetChair')
end

function ENT:GetStateName()
	local state = self:GetBehaviorState()
	local names = {
		[self.STATE_IDLE] = 'Idle',
		[self.STATE_SEARCHING] = 'Searching',
		[self.STATE_WALKING_TO_CHAIR] = 'Walking to Chair',
		[self.STATE_SITTING] = 'Sitting',
		[self.STATE_WANDERING] = 'Wandering',
		[self.STATE_LOOKING_AROUND] = 'Looking Around',
	}
	return names[state] or 'Unknown'
end

