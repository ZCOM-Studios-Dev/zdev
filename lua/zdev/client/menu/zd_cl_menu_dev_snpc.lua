local _f = 'zdev/client/vgui/zd_cl_menu_dev_snpc.lua'
--[[■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
	ZDEV - SNPC Development Menu
----------------------------------------------------------
	Comprehensive VGUI system for creating and editing SNPCs
	By ZCOM Studios
	Copyright (c) 2020-2025 by ZCOM Studios, All rights reserved.
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■]]

if ZDEV.FILE.Loaded( _f ) then return end
ZDEV.FILE.SetLoaded( _f )

if not ZDEV.SNPC then ZDEV.SNPC = {} end
if not ZDEV.SNPC.Editor then ZDEV.SNPC.Editor = {} end

local EDITOR = ZDEV.SNPC.Editor

-- Editor state
EDITOR.CurrentNPC = nil
EDITOR.SelectedTemplate = 'zdev_snpc_base'
EDITOR.PreviewEnt = nil
EDITOR.TestingMode = false

-- SNPC Templates
EDITOR.Templates = {
	['zdev_snpc_base'] = {
		name = 'Base SNPC',
		description = 'Basic scripted NPC foundation',
		category = 'Base Classes',
		spawnable = false
	},
	['zdev_snpc_soldier'] = {
		name = 'Combat Soldier',
		description = 'Military combat NPC with tactical AI',
		category = 'Combat',
		spawnable = true
	},
	['zdev_snpc_civilian'] = {
		name = 'Civilian',
		description = 'Peaceful civilian with social behaviors',
		category = 'Civilian',
		spawnable = true
	}
}

-- Model categories for easy selection
EDITOR.ModelCategories = {
	['Humans'] = {
		'models/humans/group01/male_01.mdl',
		'models/humans/group01/male_02.mdl',
		'models/humans/group01/female_01.mdl',
		'models/humans/group01/female_02.mdl'
	},
	['Military'] = {
		'models/combine_soldier.mdl',
		'models/combine_soldier_prisonguard.mdl',
		'models/police.mdl'
	},
	['Resistance'] = {
		'models/humans/group03/male_01.mdl',
		'models/humans/group03/male_02.mdl',
		'models/humans/group03/female_01.mdl'
	}
}

-- Animation presets
EDITOR.AnimationPresets = {
	['Default'] = {
		idle = 'ACT_IDLE',
		walk = 'ACT_WALK',
		run = 'ACT_RUN',
		attack = 'ACT_RANGE_ATTACK1'
	},
	['Military'] = {
		idle = 'ACT_IDLE',
		walk = 'ACT_WALK_AIM',
		run = 'ACT_RUN_AIM',
		attack = 'ACT_RANGE_ATTACK1'
	},
	['Civilian'] = {
		idle = 'ACT_IDLE',
		walk = 'ACT_WALK',
		run = 'ACT_RUN_SCARED',
		attack = 'ACT_GESTURE_WAVE'
	}
}

-- Weapon categories
EDITOR.WeaponCategories = {
	['None'] = {},
	['Pistols'] = {'weapon_pistol', 'weapon_357'},
	['SMGs'] = {'weapon_smg1', 'weapon_mp7'},
	['Rifles'] = {'weapon_ar2', 'weapon_crossbow'},
	['Shotguns'] = {'weapon_shotgun'},
	['Explosives'] = {'weapon_rpg', 'weapon_frag'}
}

function ZDEV.SNPC.OpenEditor()
	if IsValid(EDITOR.Frame) then
		EDITOR.Frame:Remove()
	end
	
	EDITOR:CreateMainInterface()
end

function EDITOR:CreateMainInterface()
	local SW, SH = ScrW(), ScrH()
	
	-- Make frame more compact
	self.Frame = ZDEV.VGUI.CreateFrame(SW * 0.95, SH * 0.95, 'ZDEV SNPC Development System')
	self.Frame:Center()
	self.Frame:MakePopup()
	
	-- Create menu bar
	self:CreateMenuBar()
	
	-- Create compact main panels
	self:CreateCompactMainPanels()
	
	-- Load default template
	self:LoadTemplate(self.SelectedTemplate)
end

function EDITOR:CreateMenuBar()
	local menuBar = vgui.Create('DMenuBar', self.Frame)
	menuBar:Dock(TOP)
	menuBar:SetTall(24)
	
	-- File menu
	local fileMenu = menuBar:AddMenu('File')
	fileMenu:AddOption('New SNPC', function() EDITOR:NewSNPC() end):SetIcon('icon16/page_add.png')
	fileMenu:AddOption('Load Template', function() EDITOR:ShowTemplateSelector() end):SetIcon('icon16/folder_page.png')
	fileMenu:AddOption('Save SNPC', function() EDITOR:SaveSNPC() end):SetIcon('icon16/disk.png')
	fileMenu:AddOption('Export to File', function() EDITOR:ExportSNPC() end):SetIcon('icon16/page_go.png')
	fileMenu:AddSpacer()
	fileMenu:AddOption('Close', function() EDITOR.Frame:Close() end):SetIcon('icon16/cross.png')
	
	-- Edit menu
	local editMenu = menuBar:AddMenu('Edit')
	editMenu:AddOption('Reset to Default', function() EDITOR:ResetToDefault() end):SetIcon('icon16/arrow_refresh.png')
	editMenu:AddOption('Duplicate SNPC', function() EDITOR:DuplicateSNPC() end):SetIcon('icon16/page_copy.png')
	editMenu:AddOption('Validate SNPC', function() EDITOR:ValidateSNPC() end):SetIcon('icon16/tick.png')
	
	-- Tools menu
	local toolsMenu = menuBar:AddMenu('Tools')
	toolsMenu:AddOption('Spawn Test NPC', function() EDITOR:SpawnTestNPC() end):SetIcon('icon16/user_add.png')
	toolsMenu:AddOption('Remove Test NPCs', function() EDITOR:RemoveTestNPCs() end):SetIcon('icon16/user_delete.png')
	toolsMenu:AddOption('Quick Spawn Menu', function() EDITOR:ShowQuickSpawnMenu() end):SetIcon('icon16/lightning.png')
	
	-- Help menu
	local helpMenu = menuBar:AddMenu('Help')
	helpMenu:AddOption('Documentation', function() EDITOR:ShowDocumentation() end):SetIcon('icon16/help.png')
	helpMenu:AddOption('Examples', function() EDITOR:ShowExamples() end):SetIcon('icon16/lightbulb.png')
	helpMenu:AddOption('About', function() EDITOR:ShowAbout() end):SetIcon('icon16/information.png')
end

function EDITOR:NewSNPC()
	zdev.log('N', 'Creating new SNPC')
	
	-- Reset all fields to defaults
	if IsValid(self.NPCName) then self.NPCName:SetValue('') end
	if IsValid(self.NPCClass) then self.NPCClass:SetValue('') end
	if IsValid(self.NPCHealth) then self.NPCHealth:SetValue(100) end
	if IsValid(self.NPCWalkSpeed) then self.NPCWalkSpeed:SetValue(150) end
	if IsValid(self.NPCAdminOnly) then self.NPCAdminOnly:SetChecked(false) end
	if IsValid(self.ModelPath) then self.ModelPath:SetValue('models/player.mdl') end
	if IsValid(self.NPCSkin) then self.NPCSkin:SetValue(0) end
	if IsValid(self.NPCScale) then self.NPCScale:SetValue(1.0) end
	if IsValid(self.AlertRadius) then self.AlertRadius:SetValue(300) end
	if IsValid(self.CombatRadius) then self.CombatRadius:SetValue(150) end
	if IsValid(self.DeathSound) then self.DeathSound:SetValue('') end
	if IsValid(self.PainSound) then self.PainSound:SetValue('') end
	if IsValid(self.AlertSound) then self.AlertSound:SetValue('') end
	if IsValid(self.SquadName) then self.SquadName:SetValue('') end
	if IsValid(self.UseCitizenModel) then self.UseCitizenModel:SetChecked(false) end
	if IsValid(self.CanDrop) then self.CanDrop:SetChecked(false) end
	if IsValid(self.RelationshipPanel) then self.RelationshipPanel:Clear() end
	
	-- Update preview
	if IsValid(self.PreviewPanel) then
		self.PreviewPanel:SetModel('models/player.mdl')
	end
	
	Derma_Message('New SNPC created. All fields reset to defaults.', 'New SNPC', 'OK')
end

function EDITOR:ShowTemplateSelector()
	zdev.log('N', 'Opening template selector')
	
	local frame = vgui.Create('DFrame')
	frame:SetSize(400, 300)
	frame:SetTitle('Load Template')
	frame:Center()
	frame:MakePopup()
	
	local panel = vgui.Create('DPanel', frame)
	panel:Dock(FILL)
	panel:DockMargin(10, 10, 10, 10)
	
	local label = vgui.Create('DLabel', panel)
	label:SetText('Select a template to load:')
	label:SetFont('DermaDefaultBold')
	label:Dock(TOP)
	label:DockMargin(0, 0, 0, 10)
	
	local templateList = vgui.Create('DListView', panel)
	templateList:AddColumn('Template')
	templateList:AddColumn('Description')
	templateList:Dock(FILL)
	templateList:DockMargin(0, 0, 0, 50)
	
	-- Populate templates
	for className, data in pairs(self.Templates) do
		templateList:AddLine(data.name, data.description)
	end
	
	-- Buttons
	local btnPanel = vgui.Create('DPanel', panel)
	btnPanel:SetTall(35)
	btnPanel:Dock(BOTTOM)
	btnPanel.Paint = function() end
	
	local loadBtn = vgui.Create('DButton', btnPanel)
	loadBtn:SetText('Load Template')
	loadBtn:SetWide(100)
	loadBtn:Dock(RIGHT)
	loadBtn:DockMargin(5, 0, 0, 0)
	loadBtn.DoClick = function()
		local selectedID = templateList:GetSelectedLine()
		if selectedID then
			local selectedLine = templateList:GetLine(selectedID)
			if selectedLine then
				local templateName = selectedLine:GetColumnText(1)
				self:LoadTemplateByName(templateName)
				frame:Close()
			end
		else
			Derma_Message('Please select a template first.', 'No Selection', 'OK')
		end
	end
	
	local cancelBtn = vgui.Create('DButton', btnPanel)
	cancelBtn:SetText('Cancel')
	cancelBtn:SetWide(80)
	cancelBtn:Dock(RIGHT)
	cancelBtn.DoClick = function()
		frame:Close()
	end
end

function EDITOR:SaveSNPC()
	zdev.log('N', 'Saving SNPC configuration')
	
	-- Get current settings
	local npcData = self:GetCurrentSettings()
	
	-- Validate required fields
	if not npcData.name or npcData.name == '' then
		Derma_Message('Please enter an NPC name before saving.', 'Save Failed', 'OK')
		return
	end
	
	if not npcData.class or npcData.class == '' then
		Derma_Message('Please enter an NPC class before saving.', 'Save Failed', 'OK')
		return
	end
	
	-- Save to file
	local fileName = string.gsub(npcData.class, '[^%w_]', '_') .. '.json'
	local filePath = 'data/zdev/snpc_configs/' .. fileName
	
	-- Create directory if it doesn't exist
	if not file.Exists('data/zdev', 'GAME') then
		file.CreateDir('data/zdev')
	end
	if not file.Exists('data/zdev/snpc_configs', 'GAME') then
		file.CreateDir('data/zdev/snpc_configs')
	end
	
	-- Write data
	file.Write(filePath, util.TableToJSON(npcData, true))
	
	Derma_Message('SNPC configuration saved as:\n' .. filePath, 'Save Complete', 'OK')
end

function EDITOR:ExportSNPC()
	zdev.log('N', 'Exporting SNPC to Lua files')
	
	local npcData = self:GetCurrentSettings()
	
	-- Validate required fields
	if not npcData.name or npcData.name == '' then
		Derma_Message('Please enter an NPC name before exporting.', 'Export Failed', 'OK')
		return
	end
	
	if not npcData.class or npcData.class == '' then
		Derma_Message('Please enter an NPC class before exporting.', 'Export Failed', 'OK')
		return
	end
	
	-- Generate Lua code
	local luaCode = self:GenerateSNPCLua(npcData)
	
	-- Save to file
	local fileName = npcData.class .. '.lua'
	local filePath = 'data/zdev/exported_snpcs/' .. fileName
	
	-- Create directory if it doesn't exist
	if not file.Exists('data/zdev', 'GAME') then
		file.CreateDir('data/zdev')
	end
	if not file.Exists('data/zdev/exported_snpcs', 'GAME') then
		file.CreateDir('data/zdev/exported_snpcs')
	end
	
	-- Write Lua file
	file.Write(filePath, luaCode)
	
	Derma_Message('SNPC exported as Lua file:\n' .. filePath .. '\n\nCopy this file to your addon\'s lua/entities/ folder.', 'Export Complete', 'OK')
end

function EDITOR:ResetToDefault()
	zdev.log('N', 'Resetting to default template')
	
	Derma_Query(
		'This will reset all current settings to the default template. Are you sure?',
		'Reset to Default',
		'Yes', function() self:LoadTemplate('zdev_snpc_base') end,
		'No', function() end
	)
end

function EDITOR:DuplicateSNPC()
	zdev.log('N', 'Duplicating current SNPC')
	
	local npcData = self:GetCurrentSettings()
	
	if not npcData.name or npcData.name == '' then
		Derma_Message('Please enter an NPC name before duplicating.', 'Duplicate Failed', 'OK')
		return
	end
	
	-- Create duplicate with modified name and class
	npcData.name = npcData.name .. ' Copy'
	npcData.class = npcData.class .. '_copy'
	
	-- Apply the duplicated data
	self:ApplySettings(npcData)
	
	Derma_Message('SNPC duplicated. Remember to change the class name to avoid conflicts.', 'Duplicate Complete', 'OK')
end

function EDITOR:ValidateSNPC()
	zdev.log('N', 'Validating SNPC configuration')
	
	local errors = {}
	local warnings = {}
	
	-- Get current settings
	local npcData = self:GetCurrentSettings()
	
	-- Validate required fields
	if not npcData.name or npcData.name == '' then
		table.insert(errors, '• NPC name is required')
	end
	
	if not npcData.class or npcData.class == '' then
		table.insert(errors, '• NPC class is required')
	elseif not string.match(npcData.class, '^[%w_]+$') then
		table.insert(errors, '• NPC class contains invalid characters (use only letters, numbers, and underscores)')
	end
	
	if not npcData.model or npcData.model == '' then
		table.insert(errors, '• Model path is required')
	elseif not string.match(npcData.model, '%.mdl$') then
		table.insert(warnings, '• Model path should end with .mdl')
	end
	
	if npcData.health <= 0 then
		table.insert(errors, '• Health must be greater than 0')
	end
	
	if npcData.walkSpeed <= 0 then
		table.insert(errors, '• Walk speed must be greater than 0')
	end
	
	if npcData.alertRadius < 0 then
		table.insert(errors, '• Alert radius cannot be negative')
	end
	
	if npcData.combatRadius < 0 then
		table.insert(errors, '• Combat radius cannot be negative')
	end
	
	-- Check for warnings
	if npcData.health > 1000 then
		table.insert(warnings, '• Health is very high (>1000)')
	end
	
	if npcData.walkSpeed > 500 then
		table.insert(warnings, '• Walk speed is very high (>500)')
	end
	
	-- Display results
	local result = ''
	if #errors > 0 then
		result = result .. 'ERRORS:\n' .. table.concat(errors, '\n') .. '\n\n'
	end
	if #warnings > 0 then
		result = result .. 'WARNINGS:\n' .. table.concat(warnings, '\n') .. '\n\n'
	end
	
	if #errors == 0 and #warnings == 0 then
		result = 'SNPC configuration is valid! ✓'
	elseif #errors == 0 then
		result = result .. 'SNPC configuration is valid but has warnings. ⚠'
	else
		result = result .. 'SNPC configuration has errors that must be fixed. ✗'
	end
	
	Derma_Message(result, 'Validation Results', 'OK')
end

function EDITOR:SpawnTestNPC()
	zdev.log('N', 'Spawn Test NPC clicked')
	local npcData = self:GetCurrentSettings()
	
	-- Get spawn position (player's aim position or in front of player)
	local ply = LocalPlayer()
	local pos = ply:GetEyeTrace().HitPos
	if not pos or pos:Distance(ply:GetPos()) > 2000 then
		-- If trace is too far or invalid, spawn in front of player
		pos = ply:GetPos() + ply:GetForward() * 200
	end
	
	-- Write spawn request to file for server to pick up
	local spawnData = {
		action = 'spawn',
		class = npcData.class or 'zdev_snpc_base',
		pos = {x = pos.x, y = pos.y, z = pos.z},
		playerID = ply:SteamID(),
		timestamp = os.time()
	}
	
	local jsonData = util.TableToJSON(spawnData)
	if not file.Exists('zdev', 'DATA') then
		file.CreateDir('zdev')
	end
	file.Write('zdev/snpc_spawn_request.json', jsonData)
end

function EDITOR:RemoveTestNPCs()
	zdev.log('N', 'Remove Test NPCs clicked')
	local ply = LocalPlayer()
	
	-- Write removal request to file for server to pick up
	local removeData = {
		action = 'remove',
		playerID = ply:SteamID(),
		timestamp = os.time()
	}
	
	local jsonData = util.TableToJSON(removeData)
	if not file.Exists('zdev', 'DATA') then
		file.CreateDir('zdev')
	end
	file.Write('zdev/snpc_remove_request.json', jsonData)
end

function EDITOR:ShowQuickSpawnMenu()
	zdev.log('N', 'Opening quick spawn menu')
	
	local frame = vgui.Create('DFrame')
	frame:SetSize(300, 200)
	frame:SetTitle('Quick Spawn')
	frame:Center()
	frame:MakePopup()
	
	local panel = vgui.Create('DPanel', frame)
	panel:Dock(FILL)
	panel:DockMargin(10, 10, 10, 10)
	
	local label = vgui.Create('DLabel', panel)
	label:SetText('Quick spawn current SNPC:')
	label:SetFont('DermaDefaultBold')
	label:Dock(TOP)
	label:DockMargin(0, 0, 0, 10)
	
	local countLabel = vgui.Create('DLabel', panel)
	countLabel:SetText('Number to spawn:')
	countLabel:Dock(TOP)
	countLabel:DockMargin(0, 0, 0, 5)
	
	local countSlider = vgui.Create('DNumSlider', panel)
	countSlider:SetText('')
	countSlider:SetMin(1)
	countSlider:SetMax(10)
	countSlider:SetValue(1)
	countSlider:SetDecimals(0)
	countSlider:Dock(TOP)
	countSlider:DockMargin(0, 0, 0, 20)
	
	-- Buttons
	local btnPanel = vgui.Create('DPanel', panel)
	btnPanel:SetTall(35)
	btnPanel:Dock(BOTTOM)
	btnPanel.Paint = function() end
	
	local spawnBtn = vgui.Create('DButton', btnPanel)
	spawnBtn:SetText('Spawn')
	spawnBtn:SetWide(80)
	spawnBtn:Dock(RIGHT)
	spawnBtn:DockMargin(5, 0, 0, 0)
	spawnBtn.DoClick = function()
		local count = math.floor(countSlider:GetValue())
		for i = 1, count do
			self:SpawnTestNPC()
		end
		frame:Close()
	end
	
	local cancelBtn = vgui.Create('DButton', btnPanel)
	cancelBtn:SetText('Cancel')
	cancelBtn:SetWide(80)
	cancelBtn:Dock(RIGHT)
	cancelBtn.DoClick = function()
		frame:Close()
	end
end

function EDITOR:ShowDocumentation()
	zdev.log('N', 'Opening documentation')
	
	local frame = vgui.Create('DFrame')
	frame:SetSize(600, 500)
	frame:SetTitle('SNPC Editor Documentation')
	frame:Center()
	frame:MakePopup()
	
	local panel = vgui.Create('DScrollPanel', frame)
	panel:Dock(FILL)
	panel:DockMargin(10, 10, 10, 10)
	
	local docText = [[
ZDEV SNPC Editor Documentation

BASIC PROPERTIES:
• Display Name: The name shown in spawn menus
• Class Name: Unique identifier (use letters, numbers, underscore only)
• Health: NPC's maximum health points
• Walk Speed: How fast the NPC moves
• Admin Only: Whether only admins can spawn this NPC

APPEARANCE:
• Model Path: 3D model file (.mdl) for the NPC
• Skin: Model skin/texture variant (usually 0-3)
• Scale: Size multiplier (1.0 = normal size)

COMBAT:
• Alert Radius: Distance at which NPC notices enemies
• Combat Radius: Distance at which NPC engages in combat

RELATIONSHIPS:
• Define how this NPC reacts to other entities
• D_LI = Like (friendly), D_HT = Hate (hostile)
• D_FR = Fear (runs away), D_NU = Neutral (ignores)

SOUNDS:
• Death Sound: Played when NPC dies
• Pain Sound: Played when NPC takes damage
• Alert Sound: Played when NPC spots an enemy

ADVANCED:
• Squad Name: NPCs with same squad work together
• Citizen Model: Use random citizen appearance
• Can Drop Weapons: Whether NPC drops weapons on death

WORKFLOW:
1. Start with a template or create new
2. Modify properties as needed
3. Use "Browse..." to select models
4. Test spawn to see your NPC in game
5. Validate configuration for errors
6. Save configuration or export as Lua file

KEYBOARD SHORTCUTS:
• Ctrl+N: New SNPC
• Ctrl+S: Save SNPC
• Ctrl+E: Export SNPC
• F5: Validate SNPC
	]]
	
	local richText = vgui.Create('RichText', panel)
	richText:Dock(FILL)
	richText:SetText(docText)
	-- RichText doesn't have SetFont method, use default
end

function EDITOR:ShowExamples()
	zdev.log('N', 'Opening examples')
	
	local frame = vgui.Create('DFrame')
	frame:SetSize(500, 400)
	frame:SetTitle('SNPC Examples')
	frame:Center()
	frame:MakePopup()
	
	local panel = vgui.Create('DPanel', frame)
	panel:Dock(FILL)
	panel:DockMargin(10, 10, 10, 10)
	
	local label = vgui.Create('DLabel', panel)
	label:SetText('Example SNPC Configurations:')
	label:SetFont('DermaDefaultBold')
	label:Dock(TOP)
	label:DockMargin(0, 0, 0, 10)
	
	local exampleList = vgui.Create('DListView', panel)
	exampleList:AddColumn('Example')
	exampleList:AddColumn('Description')
	exampleList:Dock(FILL)
	exampleList:DockMargin(0, 0, 0, 50)
	
	-- Add examples
	local examples = {
		{'Basic Guard', 'Simple security guard with moderate health and alert radius'},
		{'Heavy Soldier', 'High health combat unit with long range detection'},
		{'Civilian Worker', 'Low health, non-combat NPC that runs from danger'},
		{'Elite Commander', 'High-tier enemy with advanced capabilities'},
		{'Friendly Medic', 'Healing NPC that assists players'}
	}
	
	for _, example in ipairs(examples) do
		exampleList:AddLine(example[1], example[2])
	end
	
	-- Buttons
	local btnPanel = vgui.Create('DPanel', panel)
	btnPanel:SetTall(35)
	btnPanel:Dock(BOTTOM)
	btnPanel.Paint = function() end
	
	local loadBtn = vgui.Create('DButton', btnPanel)
	loadBtn:SetText('Load Example')
	loadBtn:SetWide(100)
	loadBtn:Dock(RIGHT)
	loadBtn:DockMargin(5, 0, 0, 0)
	loadBtn.DoClick = function()
		local selectedID = exampleList:GetSelectedLine()
		if selectedID then
			local selectedLine = exampleList:GetLine(selectedID)
			if selectedLine then
				local exampleName = selectedLine:GetColumnText(1)
				self:LoadExampleConfiguration(exampleName)
				frame:Close()
			end
		else
			Derma_Message('Please select an example first.', 'No Selection', 'OK')
		end
	end
	
	local cancelBtn = vgui.Create('DButton', btnPanel)
	cancelBtn:SetText('Close')
	cancelBtn:SetWide(80)
	cancelBtn:Dock(RIGHT)
	cancelBtn.DoClick = function()
		frame:Close()
	end
end

function EDITOR:ShowAbout()
	zdev.log('N', 'Opening about dialog')
	
	local frame = vgui.Create('DFrame')
	frame:SetSize(400, 300)
	frame:SetTitle('About ZDEV SNPC Editor')
	frame:Center()
	frame:MakePopup()
	
	local panel = vgui.Create('DPanel', frame)
	panel:Dock(FILL)
	panel:DockMargin(20, 20, 20, 20)
	
	local logoLabel = vgui.Create('DLabel', panel)
	logoLabel:SetText('ZDEV SNPC Editor')
	logoLabel:SetFont('DermaLarge')
	logoLabel:SetContentAlignment(5)
	logoLabel:Dock(TOP)
	logoLabel:SetTall(30)
	logoLabel:DockMargin(0, 0, 0, 10)
	
	local versionLabel = vgui.Create('DLabel', panel)
	versionLabel:SetText('Version 1.0')
	versionLabel:SetContentAlignment(5)
	versionLabel:Dock(TOP)
	versionLabel:SetTall(20)
	versionLabel:DockMargin(0, 0, 0, 15)
	
	local infoText = [[
A comprehensive SNPC creation and editing tool for Garry's Mod.

Features:
• Visual SNPC configuration
• Model browser with preview
• Real-time validation
• Export to Lua files
• Template system
• Relationship management

Created by ZCOM Studios
Copyright © 2025

Thank you for using ZDEV!
	]]
	
	local infoLabel = vgui.Create('DLabel', panel)
	infoLabel:SetText(infoText)
	infoLabel:SetContentAlignment(7) -- Top-left
	infoLabel:SetWrap(true)
	infoLabel:Dock(FILL)
	infoLabel:DockMargin(0, 0, 0, 10)
	
	local closeBtn = vgui.Create('DButton', panel)
	closeBtn:SetText('Close')
	closeBtn:SetTall(30)
	closeBtn:Dock(BOTTOM)
	closeBtn.DoClick = function()
		frame:Close()
	end
end

function EDITOR:CreateCompactMainPanels()
	-- Create three-column layout: Templates | Properties | Preview
	local mainContainer = vgui.Create('DPanel', self.Frame)
	mainContainer:Dock(FILL)
	
	-- Left panel for templates (narrower)
	local leftPanel = vgui.Create('DPanel', mainContainer)
	leftPanel:SetWide(180)
	leftPanel:Dock(LEFT)
	leftPanel:DockMargin(0, 0, 2, 0)
	
	local templateLabel = vgui.Create('DLabel', leftPanel)
	templateLabel:SetText('Templates')
	templateLabel:SetFont('DermaDefaultBold')
	templateLabel:Dock(TOP)
	templateLabel:SetTall(20)
	
	local templateList = vgui.Create('DListView', leftPanel)
	templateList:Dock(FILL)
	templateList:AddColumn('SNPC Templates')
	templateList:SetHeaderHeight(0)
	
	for className, data in pairs(self.Templates) do
		templateList:AddLine(data.name)
	end
	
	-- Right panel for preview (narrower)
	local rightPanel = vgui.Create('DPanel', mainContainer)
	rightPanel:SetWide(200)
	rightPanel:Dock(RIGHT)
	rightPanel:DockMargin(2, 0, 0, 0)
	
	local previewLabel = vgui.Create('DLabel', rightPanel)
	previewLabel:SetText('Preview')
	previewLabel:SetFont('DermaDefaultBold')
	previewLabel:Dock(TOP)
	previewLabel:SetTall(20)
	
	self.PreviewPanel = vgui.Create('DModelPanel', rightPanel)
	self.PreviewPanel:Dock(FILL)
	self.PreviewPanel:SetModel('models/player.mdl')
	
	-- Center panel for all properties (scrollable)
	local centerPanel = vgui.Create('DPanel', mainContainer)
	centerPanel:Dock(FILL)
	centerPanel:DockMargin(2, 0, 2, 0)
	
	local propsLabel = vgui.Create('DLabel', centerPanel)
	propsLabel:SetText('Properties')
	propsLabel:SetFont('DermaDefaultBold')
	propsLabel:Dock(TOP)
	propsLabel:SetTall(20)
	
	-- Single scrollable panel for all properties
	self.PropertiesPanel = vgui.Create('DScrollPanel', centerPanel)
	self.PropertiesPanel:Dock(FILL)
	
	-- Create all property sections in one scrollable area
	self:CreateCompactPropertySections()
end

function EDITOR:CreateCompactPropertySections()
	local function CreateSection(title)
		local category = vgui.Create('DCollapsibleCategory', self.PropertiesPanel)
		category:SetLabel(title)
		category:SetExpanded(true)
		category:Dock(TOP)
		category:DockMargin(3, 2, 3, 2)
		category:SetHeaderHeight(22)
		
		local panel = vgui.Create('DPanel', category)
		panel:SetTall(140) -- Slightly taller for better readability
		category:SetContents(panel)
		
		-- Add subtle background color for better readability
		panel.Paint = function(pnl, w, h)
			draw.RoundedBox(4, 0, 0, w, h, Color(245, 245, 245, 255))
		end
		
		return panel
	end
	
	local function AddCompactControl(parent, label, control, height)
		height = height or 22
		
		local container = vgui.Create('DPanel', parent)
		container:SetTall(height + 4)
		container:Dock(TOP)
		container:DockMargin(5, 2, 5, 2)
		container.Paint = function() end -- Transparent
		
		local lbl = vgui.Create('DLabel', container)
		lbl:SetText(label)
		lbl:SetWide(90)
		lbl:Dock(LEFT)
		lbl:SetFont('DermaDefaultBold')
		lbl:SetTextColor(Color(60, 60, 60))
		
		control:SetParent(container)
		control:Dock(FILL)
		control:DockMargin(5, 0, 0, 0)
		
		return container
	end
	
	local function AddCheckboxControl(parent, label, checkbox)
		local container = vgui.Create('DPanel', parent)
		container:SetTall(26)
		container:Dock(TOP)
		container:DockMargin(5, 2, 5, 2)
		container.Paint = function() end
		
		checkbox:SetParent(container)
		checkbox:SetWide(20)
		checkbox:Dock(LEFT)
		
		local lbl = vgui.Create('DLabel', container)
		lbl:SetText(label)
		lbl:Dock(LEFT)
		lbl:DockMargin(8, 0, 0, 0)
		lbl:SetFont('DermaDefaultBold')
		lbl:SetTextColor(Color(60, 60, 60))
		
		return container
	end
	
	-- Basic Properties (improved readability)
	local basicPanel = CreateSection('Basic Properties')
	
	self.NPCName = vgui.Create('DTextEntry')
	self.NPCName:SetPlaceholderText('Enter display name...')
	AddCompactControl(basicPanel, 'Display Name:', self.NPCName)
	
	self.NPCClass = vgui.Create('DTextEntry')
	self.NPCClass:SetPlaceholderText('npc_mysnpc')
	AddCompactControl(basicPanel, 'Class Name:', self.NPCClass)
	
	-- Health and Speed row with better spacing
	local row1 = vgui.Create('DPanel', basicPanel)
	row1:SetTall(26)
	row1:Dock(TOP)
	row1:DockMargin(5, 2, 5, 2)
	row1.Paint = function() end
	
	local hlbl = vgui.Create('DLabel', row1)
	hlbl:SetText('Health:')
	hlbl:SetWide(50)
	hlbl:Dock(LEFT)
	hlbl:SetFont('DermaDefaultBold')
	hlbl:SetTextColor(Color(60, 60, 60))
	
	self.NPCHealth = vgui.Create('DNumberWang', row1)
	self.NPCHealth:SetValue(100)
	self.NPCHealth:SetWide(70)
	self.NPCHealth:Dock(LEFT)
	self.NPCHealth:DockMargin(5, 0, 15, 0)
	
	local slbl = vgui.Create('DLabel', row1)
	slbl:SetText('Walk Speed:')
	slbl:SetWide(70)
	slbl:Dock(LEFT)
	slbl:SetFont('DermaDefaultBold')
	slbl:SetTextColor(Color(60, 60, 60))
	
	self.NPCWalkSpeed = vgui.Create('DNumberWang', row1)
	self.NPCWalkSpeed:SetValue(150)
	self.NPCWalkSpeed:SetWide(70)
	self.NPCWalkSpeed:Dock(LEFT)
	self.NPCWalkSpeed:DockMargin(5, 0, 0, 0)
	
	-- Fixed Admin Only checkbox
	self.NPCAdminOnly = vgui.Create('DCheckBox')
	AddCheckboxControl(basicPanel, 'Admin Only NPC', self.NPCAdminOnly)
	
	local function AddModelControl(parent, label)
		local container = vgui.Create('DPanel', parent)
		container:SetTall(26)
		container:Dock(TOP)
		container:DockMargin(5, 2, 5, 2)
		container.Paint = function() end
		
		local lbl = vgui.Create('DLabel', container)
		lbl:SetText(label)
		lbl:SetWide(90)
		lbl:Dock(LEFT)
		lbl:SetFont('DermaDefaultBold')
		lbl:SetTextColor(Color(60, 60, 60))
		
		self.ModelPath = vgui.Create('DTextEntry', container)
		self.ModelPath:SetPlaceholderText('models/player.mdl')
		self.ModelPath:SetValue('models/player.mdl')
		self.ModelPath:Dock(FILL)
		self.ModelPath:DockMargin(5, 0, 5, 0)
		
		-- Browse button
		local browseBtn = vgui.Create('DButton', container)
		browseBtn:SetText('Browse...')
		browseBtn:SetWide(70)
		browseBtn:Dock(RIGHT)
		browseBtn.DoClick = function()
			self:ShowModelBrowser()
		end
		
		-- Update preview when model changes
		self.ModelPath.OnEnter = function()
			if IsValid(self.PreviewPanel) then
				self.PreviewPanel:SetModel(self.ModelPath:GetValue())
			end
		end
		
		return container
	end
	
	-- Appearance (improved readability)
	local appearancePanel = CreateSection('Appearance')
	
	AddModelControl(appearancePanel, 'Model Path:')
	
	-- Skin and Scale row
	local row2 = vgui.Create('DPanel', appearancePanel)
	row2:SetTall(26)
	row2:Dock(TOP)
	row2:DockMargin(5, 2, 5, 2)
	row2.Paint = function() end
	
	local skinlbl = vgui.Create('DLabel', row2)
	skinlbl:SetText('Skin:')
	skinlbl:SetWide(50)
	skinlbl:Dock(LEFT)
	skinlbl:SetFont('DermaDefaultBold')
	skinlbl:SetTextColor(Color(60, 60, 60))
	
	self.NPCSkin = vgui.Create('DNumberWang', row2)
	self.NPCSkin:SetValue(0)
	self.NPCSkin:SetWide(60)
	self.NPCSkin:Dock(LEFT)
	self.NPCSkin:DockMargin(5, 0, 15, 0)
	
	local scalelbl = vgui.Create('DLabel', row2)
	scalelbl:SetText('Scale:')
	scalelbl:SetWide(50)
	scalelbl:Dock(LEFT)
	scalelbl:SetFont('DermaDefaultBold')
	scalelbl:SetTextColor(Color(60, 60, 60))
	
	self.NPCScale = vgui.Create('DNumberWang', row2)
	self.NPCScale:SetValue(1.0)
	self.NPCScale:SetDecimals(2)
	self.NPCScale:SetWide(70)
	self.NPCScale:Dock(LEFT)
	self.NPCScale:DockMargin(5, 0, 0, 0)
	
	-- Combat (improved readability)
	local combatPanel = CreateSection('Combat')
	
	local row3 = vgui.Create('DPanel', combatPanel)
	row3:SetTall(26)
	row3:Dock(TOP)
	row3:DockMargin(5, 2, 5, 2)
	row3.Paint = function() end
	
	local alertlbl = vgui.Create('DLabel', row3)
	alertlbl:SetText('Alert Radius:')
	alertlbl:SetWide(80)
	alertlbl:Dock(LEFT)
	alertlbl:SetFont('DermaDefaultBold')
	alertlbl:SetTextColor(Color(60, 60, 60))
	
	self.AlertRadius = vgui.Create('DNumberWang', row3)
	self.AlertRadius:SetValue(300)
	self.AlertRadius:SetWide(70)
	self.AlertRadius:Dock(LEFT)
	self.AlertRadius:DockMargin(5, 0, 15, 0)
	
	local combatlbl = vgui.Create('DLabel', row3)
	combatlbl:SetText('Combat Radius:')
	combatlbl:SetWide(90)
	combatlbl:Dock(LEFT)
	combatlbl:SetFont('DermaDefaultBold')
	combatlbl:SetTextColor(Color(60, 60, 60))
	
	self.CombatRadius = vgui.Create('DNumberWang', row3)
	self.CombatRadius:SetValue(150)
	self.CombatRadius:SetWide(70)
	self.CombatRadius:Dock(LEFT)
	self.CombatRadius:DockMargin(5, 0, 0, 0)
	
	-- Relationships (improved readability)
	local relationPanel = CreateSection('Relationships')
	
	self.RelationshipPanel = vgui.Create('DListView', relationPanel)
	self.RelationshipPanel:AddColumn('Entity Class')
	self.RelationshipPanel:AddColumn('Disposition')
	self.RelationshipPanel:Dock(FILL)
	self.RelationshipPanel:DockMargin(5, 5, 5, 30)
	
	local addRelBtn = vgui.Create('DButton', relationPanel)
	addRelBtn:SetText('+ Add Relationship')
	addRelBtn:SetTall(22)
	addRelBtn:Dock(BOTTOM)
	addRelBtn:DockMargin(5, 2, 5, 5)
	addRelBtn.DoClick = function()
		self:ShowRelationshipDialog()
	end
	
	-- Sounds (improved readability)
	local soundPanel = CreateSection('Sounds')
	
	self.DeathSound = vgui.Create('DTextEntry')
	self.DeathSound:SetPlaceholderText('npc/combine_soldier/die1.wav')
	AddCompactControl(soundPanel, 'Death Sound:', self.DeathSound)
	
	self.PainSound = vgui.Create('DTextEntry')
	self.PainSound:SetPlaceholderText('npc/combine_soldier/pain1.wav')
	AddCompactControl(soundPanel, 'Pain Sound:', self.PainSound)
	
	self.AlertSound = vgui.Create('DTextEntry')
	self.AlertSound:SetPlaceholderText('npc/combine_soldier/vo/alert1.wav')
	AddCompactControl(soundPanel, 'Alert Sound:', self.AlertSound)
	
	-- Advanced (improved readability)
	local advPanel = CreateSection('Advanced')
	
	self.SquadName = vgui.Create('DTextEntry')
	self.SquadName:SetPlaceholderText('squad_soldiers')
	AddCompactControl(advPanel, 'Squad Name:', self.SquadName)
	
	-- Checkbox row with better layout
	local row4 = vgui.Create('DPanel', advPanel)
	row4:SetTall(30)
	row4:Dock(TOP)
	row4:DockMargin(5, 2, 5, 2)
	row4.Paint = function() end
	
	self.UseCitizenModel = vgui.Create('DCheckBox', row4)
	self.UseCitizenModel:SetWide(20)
	self.UseCitizenModel:Dock(LEFT)
	
	local citlbl = vgui.Create('DLabel', row4)
	citlbl:SetText('Use Citizen Model')
	citlbl:SetWide(120)
	citlbl:Dock(LEFT)
	citlbl:DockMargin(8, 0, 20, 0)
	citlbl:SetFont('DermaDefaultBold')
	citlbl:SetTextColor(Color(60, 60, 60))
	
	self.CanDrop = vgui.Create('DCheckBox', row4)
	self.CanDrop:SetWide(20)
	self.CanDrop:Dock(LEFT)
	
	local droplbl = vgui.Create('DLabel', row4)
	droplbl:SetText('Can Drop Weapons')
	droplbl:Dock(LEFT)
	droplbl:DockMargin(8, 0, 0, 0)
	droplbl:SetFont('DermaDefaultBold')
	droplbl:SetTextColor(Color(60, 60, 60))
end

function EDITOR:CreatePropertySheets()
	-- This function is now correctly named and will populate the property sheet
	self:CreateBasicPropertiesPanel()
	self:CreateAppearancePanel()
	self:CreateBehaviorPanel()
	self:CreateCombatPanel()
	self:CreateSoundsPanel()
	self:CreateAdvancedPanel()
	self:CreatePreviewPanel()
end

function EDITOR:CreateBasicPropertiesPanel()
	local panel = vgui.Create('DScrollPanel')
	self.PropertySheet:AddSheet('Basic', panel, 'icon16/user.png')

	local function AddControl(label, control)
		local lbl = vgui.Create("DLabel", panel)
		lbl:SetText(label)
		lbl:Dock(TOP)
		lbl:DockMargin(5, 10, 5, 2)
		lbl:SetDark(true)

		control:SetParent(panel)
		control:Dock(TOP)
		control:DockMargin(5, 0, 5, 5)
	end

	-- Name and class
	self.NPCName = vgui.Create('DTextEntry')
	self.NPCName:SetValue('My Custom SNPC')
	AddControl('NPC Name', self.NPCName)

	self.NPCClass = vgui.Create('DTextEntry')
	self.NPCClass:SetValue('zdev_snpc_custom')
	AddControl('Class Name', self.NPCClass)

	self.NPCDescription = vgui.Create('DTextEntry')
	self.NPCDescription:SetValue('Custom SNPC created with ZDEV')
	AddControl('Description', self.NPCDescription)

	-- Category and spawnable
	self.NPCCategory = vgui.Create('DComboBox')
	self.NPCCategory:AddChoice('ZDEV SNPCs')
	self.NPCCategory:AddChoice('Custom NPCs')
	self.NPCCategory:AddChoice('Combat NPCs')
	self.NPCCategory:AddChoice('Civilian NPCs')
	self.NPCCategory:SetValue('ZDEV SNPCs')
	AddControl('Category', self.NPCCategory)

	self.NPCSpawnable = vgui.Create('DCheckBoxLabel')
	self.NPCSpawnable:SetText('Spawnable')
	self.NPCSpawnable:SetValue(1)
	self.NPCSpawnable:Dock(TOP)
	self.NPCSpawnable:DockMargin(5, 10, 5, 5)
	self.NPCSpawnable:SetParent(panel)

	self.NPCAdminOnly = vgui.Create('DCheckBoxLabel')
	self.NPCAdminOnly:SetText('Admin Only')
	self.NPCAdminOnly:SetValue(0)
	self.NPCAdminOnly:Dock(TOP)
	self.NPCAdminOnly:DockMargin(5, 5, 5, 5)
	self.NPCAdminOnly:SetParent(panel)

	-- Health and basic stats
	self.NPCHealth = vgui.Create("DNumberWang", panel)
	self.NPCHealth:SetMinMax(1, 10000)
	self.NPCHealth:SetDecimals(0)
	self.NPCHealth:SetValue(100)
	AddControl('Max Health', self.NPCHealth)

	self.NPCWalkSpeed = vgui.Create("DNumberWang", panel)
	self.NPCWalkSpeed:SetMinMax(1, 500)
	self.NPCWalkSpeed:SetDecimals(0)
	self.NPCWalkSpeed:SetValue(80)
	AddControl('Walk Speed', self.NPCWalkSpeed)

	self.NPCRunSpeed = vgui.Create("DNumberWang", panel)
	self.NPCRunSpeed:SetMinMax(1, 1000)
	self.NPCRunSpeed:SetDecimals(0)
	self.NPCRunSpeed:SetValue(200)
	AddControl('Run Speed', self.NPCRunSpeed)
end

function EDITOR:CreateAppearancePanel()
	local panel = vgui.Create('DScrollPanel')
	self.PropertySheet:AddSheet('Appearance', panel, 'icon16/image.png')

	local function AddControl(label, control)
		local lbl = vgui.Create("DLabel", panel)
		lbl:SetText(label)
		lbl:Dock(TOP)
		lbl:DockMargin(5, 10, 5, 2)
		lbl:SetDark(true)

		control:SetParent(panel)
		control:Dock(TOP)
		control:DockMargin(5, 0, 5, 5)
	end

	-- Model selection
	self.ModelCategory = vgui.Create('DComboBox')
	for category, _ in pairs(self.ModelCategories) do
		self.ModelCategory:AddChoice(category)
	end
	self.ModelCategory:SetValue('Humans')
	AddControl('Model Category', self.ModelCategory)

	self.ModelPath = vgui.Create('DComboBox')
	self:PopulateModels('Humans')
	AddControl('Model', self.ModelPath)

	self.ModelCategory.OnSelect = function(pnl, index, value)
		self:PopulateModels(value)
	end

	-- Appearance properties
	self.NPCSkin = vgui.Create("DNumberWang", panel)
	self.NPCSkin:SetMinMax(0, 10)
	self.NPCSkin:SetDecimals(0)
	self.NPCSkin:SetValue(0)
	AddControl('Skin', self.NPCSkin)

	self.NPCScale = vgui.Create("DNumberWang", panel)
	self.NPCScale:SetMinMax(0.1, 5.0)
	self.NPCScale:SetDecimals(2)
	self.NPCScale:SetValue(1.0)
	AddControl('Scale', self.NPCScale)

	self.NPCMaterial = vgui.Create('DTextEntry')
	AddControl('Material Override', self.NPCMaterial)

	-- Color picker
	local colorLabel = vgui.Create('DLabel', panel)
	colorLabel:SetText('Color:')
	colorLabel:Dock(TOP)
	colorLabel:DockMargin(5, 10, 5, 2)
	colorLabel:SetDark(true)

	self.ColorPicker = vgui.Create('DColorMixer', panel)
	self.ColorPicker:Dock(TOP)
	self.ColorPicker:SetPalette(false)
	self.ColorPicker:SetAlphaBar(true)
	self.ColorPicker:SetWangs(true)
	self.ColorPicker:SetColor(Color(255, 255, 255, 255))
	self.ColorPicker:SetTall(150)
	self.ColorPicker:DockMargin(5, 0, 5, 5)
end

function EDITOR:CreateBehaviorPanel()
	local panel = vgui.Create('DScrollPanel')
	self.PropertySheet:AddSheet('Behavior', panel, 'icon16/cog.png')

	local function AddControl(label, control)
		local lbl = vgui.Create("DLabel", panel)
		lbl:SetText(label)
		lbl:Dock(TOP)
		lbl:DockMargin(5, 10, 5, 2)
		lbl:SetDark(true)

		control:SetParent(panel)
		control:Dock(TOP)
		control:DockMargin(5, 0, 5, 5)
	end

	-- Detection ranges
	self.AlertRadius = vgui.Create("DNumberWang", panel)
	self.AlertRadius:SetMinMax(100, 5000)
	self.AlertRadius:SetDecimals(0)
	self.AlertRadius:SetValue(1000)
	AddControl('Alert Radius', self.AlertRadius)

	self.CombatRadius = vgui.Create("DNumberWang", panel)
	self.CombatRadius:SetMinMax(100, 5000)
	self.CombatRadius:SetDecimals(0)
	self.CombatRadius:SetValue(1500)
	AddControl('Combat Radius', self.CombatRadius)

	self.HearingRadius = vgui.Create("DNumberWang", panel)
	self.HearingRadius:SetMinMax(100, 3000)
	self.HearingRadius:SetDecimals(0)
	self.HearingRadius:SetValue(800)
	AddControl('Hearing Radius', self.HearingRadius)

	-- Personality traits
	self.Aggressiveness = vgui.Create("DNumberWang", panel)
	self.Aggressiveness:SetMinMax(0, 1)
	self.Aggressiveness:SetDecimals(2)
	self.Aggressiveness:SetValue(0.5)
	AddControl('Aggressiveness', self.Aggressiveness)

	self.Courage = vgui.Create("DNumberWang", panel)
	self.Courage:SetMinMax(0, 1)
	self.Courage:SetDecimals(2)
	self.Courage:SetValue(0.5)
	AddControl('Courage', self.Courage)

	self.Alertness = vgui.Create("DNumberWang", panel)
	self.Alertness:SetMinMax(0, 1)
	self.Alertness:SetDecimals(2)
	self.Alertness:SetValue(0.7)
	AddControl('Alertness', self.Alertness)

	-- Squad settings
	self.SquadName = vgui.Create('DTextEntry')
	self.SquadName:SetValue('default_squad')
	AddControl('Squad Name', self.SquadName)

	self.SquadSlots = vgui.Create("DNumberWang", panel)
	self.SquadSlots:SetMinMax(1, 20)
	self.SquadSlots:SetDecimals(0)
	self.SquadSlots:SetValue(4)
	AddControl('Squad Slots', self.SquadSlots)

	-- Relationships
	local relLabel = vgui.Create('DLabel', panel)
	relLabel:SetText('Relationships')
	relLabel:Dock(TOP)
	relLabel:DockMargin(5, 10, 5, 2)
	relLabel:SetDark(true)

	self.RelationshipPanel = vgui.Create('DListView', panel)
	self.RelationshipPanel:SetTall(150)
	self.RelationshipPanel:AddColumn('Entity Class')
	self.RelationshipPanel:AddColumn('Disposition')
	self.RelationshipPanel:Dock(TOP)
	self.RelationshipPanel:DockMargin(5, 0, 5, 5)

	-- Add relationship button
	local addRelBtn = ZDEV.VGUI.CreateButton(panel, 100, 25, 'Add Relationship', 'DermaDefault', Color(100, 255, 100), function()
		self:ShowRelationshipDialog()
	end)
	addRelBtn:Dock(TOP)
	addRelBtn:DockMargin(5, 5, 5, 5)
end

function EDITOR:CreateCombatPanel()
	local panel = vgui.Create('DScrollPanel')
	self.PropertySheet:AddSheet('Combat', panel, 'icon16/gun.png')

	local function AddControl(label, control)
		local lbl = vgui.Create("DLabel", panel)
		lbl:SetText(label)
		lbl:Dock(TOP)
		lbl:DockMargin(5, 10, 5, 2)
		lbl:SetDark(true)

		control:SetParent(panel)
		control:Dock(TOP)
		control:DockMargin(5, 0, 5, 5)
	end

	-- Weapon selection
	self.PrimaryWeaponCategory = vgui.Create('DComboBox')
	for category, _ in pairs(self.WeaponCategories) do
		self.PrimaryWeaponCategory:AddChoice(category)
	end
	self.PrimaryWeaponCategory:SetValue('None')
	AddControl('Primary Weapon Category', self.PrimaryWeaponCategory)

	self.PrimaryWeapon = vgui.Create('DComboBox')
	AddControl('Primary Weapon', self.PrimaryWeapon)

	self.SecondaryWeapon = vgui.Create('DComboBox')
	AddControl('Secondary Weapon', self.SecondaryWeapon)

	self.PrimaryWeaponCategory.OnSelect = function(pnl, index, value)
		self:PopulateWeapons(self.PrimaryWeapon, value)
	end

	-- Combat stats
	self.WeaponProficiency = vgui.Create('DComboBox')
	self.WeaponProficiency:AddChoice('WEAPON_PROFICIENCY_POOR')
	self.WeaponProficiency:AddChoice('WEAPON_PROFICIENCY_AVERAGE')
	self.WeaponProficiency:AddChoice('WEAPON_PROFICIENCY_GOOD')
	self.WeaponProficiency:AddChoice('WEAPON_PROFICIENCY_VERY_GOOD')
	self.WeaponProficiency:AddChoice('WEAPON_PROFICIENCY_PERFECT')
	self.WeaponProficiency:SetValue('WEAPON_PROFICIENCY_AVERAGE')
	AddControl('Weapon Proficiency', self.WeaponProficiency)

	self.FireRate = vgui.Create("DNumberWang", panel)
	self.FireRate:SetMinMax(0.1, 5.0)
	self.FireRate:SetDecimals(2)
	self.FireRate:SetValue(1.0)
	AddControl('Fire Rate', self.FireRate)

	self.Accuracy = vgui.Create("DNumberWang", panel)
	self.Accuracy:SetMinMax(0, 1)
	self.Accuracy:SetDecimals(2)
	self.Accuracy:SetValue(0.7)
	AddControl('Accuracy (0-1)', self.Accuracy)

	self.BurstLength = vgui.Create("DNumberWang", panel)
	self.BurstLength:SetMinMax(1, 20)
	self.BurstLength:SetDecimals(0)
	self.BurstLength:SetValue(3)
	AddControl('Burst Length', self.BurstLength)

	-- Drop weapons
	self.DropWeapons = vgui.Create('DCheckBoxLabel')
	self.DropWeapons:SetText('Drop Weapons on Death')
	self.DropWeapons:SetValue(1)
	self.DropWeapons:Dock(TOP)
	self.DropWeapons:DockMargin(5, 10, 5, 5)
	self.DropWeapons:SetParent(panel)
end

function EDITOR:CreateSoundsPanel()
	local panel = vgui.Create('DScrollPanel')
	self.PropertySheet:AddSheet('Sounds', panel, 'icon16/sound.png')

	local soundTypes = {'pain', 'death', 'alert', 'attack', 'idle'}

	for _, soundType in ipairs(soundTypes) do
		local lbl = vgui.Create("DLabel", panel)
		lbl:SetText(string.upper(soundType:sub(1, 1)) .. soundType:sub(2) .. ' Sounds')
		lbl:Dock(TOP)
		lbl:DockMargin(5, 10, 5, 2)
		lbl:SetDark(true)

		local soundList = vgui.Create('DListView', panel)
		soundList:SetTall(100)
		soundList:AddColumn('Sound Path')
		soundList:AddColumn('Actions')
		soundList:Dock(TOP)
		soundList:DockMargin(5, 0, 5, 5)

		self['SoundList_' .. soundType] = soundList

		local addSoundBtn = ZDEV.VGUI.CreateButton(panel, 120, 25, 'Add ' .. soundType:upper(), 'DermaDefault', Color(100, 200, 255), function()
			self:ShowSoundDialog(soundType)
		end)
		addSoundBtn:Dock(TOP)
		addSoundBtn:DockMargin(5, 5, 5, 5)
	end
end

function EDITOR:CreateAdvancedPanel()
	local panel = vgui.Create('DScrollPanel')
	self.PropertySheet:AddSheet('Advanced', panel, 'icon16/wrench.png')

	local function AddControl(label, control)
		local lbl = vgui.Create("DLabel", panel)
		lbl:SetText(label)
		lbl:Dock(TOP)
		lbl:DockMargin(5, 10, 5, 2)
		lbl:SetDark(true)

		control:SetParent(panel)
		control:Dock(TOP)
		control:DockMargin(5, 0, 5, 5)
	end

	-- Capabilities
	local capLabel = vgui.Create('DLabel', panel)
	capLabel:SetText('Capabilities')
	capLabel:Dock(TOP)
	capLabel:DockMargin(5, 10, 5, 2)
	capLabel:SetDark(true)

	local capPanel = vgui.Create('DPanel', panel)
	capPanel:SetTall(200)
	capPanel:Dock(TOP)
	capPanel:DockMargin(5, 0, 5, 5)

	-- Create capability checkboxes
	local capabilities = {
		'CAP_MOVE_GROUND', 'CAP_MOVE_JUMP', 'CAP_MOVE_CLIMB',
		'CAP_OPEN_DOORS', 'CAP_AUTO_DOORS', 'CAP_USE',
		'CAP_WEAPON_RANGE_ATTACK1', 'CAP_WEAPON_MELEE_ATTACK1',
		'CAP_DUCK', 'CAP_SQUAD', 'CAP_USE_SHOT_REGULATOR', 'CAP_AIM_GUN'
	}

	self.CapabilityChecks = {}
	local x, y = 0, 0
	for _, cap in ipairs(capabilities) do
		local check = vgui.Create('DCheckBoxLabel', capPanel)
		check:SetText(cap)
		check:SetPos(x, y)
		check:SetSize(200, 20)
		self.CapabilityChecks[cap] = check

		y = y + 25
		if y > 150 then
			y = 0
			x = x + 210
		end
	end

	-- Animation overrides
	self.AnimationPreset = vgui.Create('DComboBox')
	for preset, _ in pairs(self.AnimationPresets) do
		self.AnimationPreset:AddChoice(preset)
	end
	self.AnimationPreset:SetValue('Default')
	AddControl('Animation Preset', self.AnimationPreset)

	self.AnimationPreset.OnSelect = function(pnl, index, value)
		self:LoadAnimationPreset(value)
	end

	-- Custom animation entries
	self.IdleAnimation = vgui.Create('DTextEntry')
	self.IdleAnimation:SetValue('ACT_IDLE')
	AddControl('Idle Animation', self.IdleAnimation)

	self.WalkAnimation = vgui.Create('DTextEntry')
	self.WalkAnimation:SetValue('ACT_WALK')
	AddControl('Walk Animation', self.WalkAnimation)

	self.RunAnimation = vgui.Create('DTextEntry')
	self.RunAnimation:SetValue('ACT_RUN')
	AddControl('Run Animation', self.RunAnimation)

	self.AttackAnimation = vgui.Create('DTextEntry')
	self.AttackAnimation:SetValue('ACT_RANGE_ATTACK1')
	AddControl('Attack Animation', self.AttackAnimation)
end

function EDITOR:CreatePreviewPanel()
	local panel = vgui.Create('DPanel')
	self.PropertySheet:AddSheet('Preview', panel, 'icon16/eye.png')
	
	-- 3D model preview
	self.ModelPreview = vgui.Create('DModelPanel', panel)
	self.ModelPreview:Dock(FILL)
	self.ModelPreview:DockMargin(5, 5, 5, 35)
	self.ModelPreview:SetModel('models/humans/group01/male_01.mdl')
	
	-- Preview controls
	local controlPanel = vgui.Create('DPanel', panel)
	controlPanel:Dock(BOTTOM)
	controlPanel:SetTall(30)
	
	local updateBtn = ZDEV.VGUI.CreateButton(controlPanel, 100, 25, 'Update Preview', 'DermaDefault', Color(100, 255, 100), function()
		self:UpdatePreview()
	end)
	updateBtn:Dock(LEFT)
	updateBtn:DockMargin(5, 2, 5, 2)
	
	local animBtn = ZDEV.VGUI.CreateButton(controlPanel, 100, 25, 'Test Animation', 'DermaDefault', Color(255, 255, 100), function()
		self:TestAnimation()
	end)
	animBtn:Dock(LEFT)
	animBtn:DockMargin(5, 2, 5, 2)
end

-- Utility functions
function EDITOR:PopulateModels(category)
	self.ModelPath:Clear()
	
	if self.ModelCategories[category] then
		for _, model in ipairs(self.ModelCategories[category]) do
			self.ModelPath:AddChoice(model)
		end
	end
end

function EDITOR:PopulateWeapons(comboBox, category)
	comboBox:Clear()
	
	if self.WeaponCategories[category] then
		for _, weapon in ipairs(self.WeaponCategories[category]) do
			comboBox:AddChoice(weapon)
		end
	end
end

function EDITOR:LoadTemplate(className)
	self.SelectedTemplate = className
	
	-- Reset form values to template defaults
	-- This would populate all the form fields with the template's values
	-- Implementation would involve reading the entity's configuration tables
	
	if ZDEV and ZDEV.LOG then
		zdev.log('N', 'Loaded SNPC template: ' .. className)
	end
end

function EDITOR:UpdatePreview()
	if IsValid(self.ModelPreview) then
		local model = self.ModelPath:GetSelected() or 'models/humans/group01/male_01.mdl'
		self.ModelPreview:SetModel(model)
		
		-- Apply color if set
		if IsValid(self.ColorPicker) then
			local color = self.ColorPicker:GetColor()
			self.ModelPreview:SetColor(color)
		end
	end
end

-- Supporting Functions
function EDITOR:GetCurrentSettings()
	local settings = {
		name = IsValid(self.NPCName) and self.NPCName:GetValue() or '',
		class = IsValid(self.NPCClass) and self.NPCClass:GetValue() or '',
		model = IsValid(self.ModelPath) and self.ModelPath:GetValue() or 'models/player.mdl',
		health = IsValid(self.NPCHealth) and self.NPCHealth:GetValue() or 100,
		walkSpeed = IsValid(self.NPCWalkSpeed) and self.NPCWalkSpeed:GetValue() or 150,
		adminOnly = IsValid(self.NPCAdminOnly) and self.NPCAdminOnly:GetChecked() or false,
		skin = IsValid(self.NPCSkin) and self.NPCSkin:GetValue() or 0,
		scale = IsValid(self.NPCScale) and self.NPCScale:GetValue() or 1.0,
		alertRadius = IsValid(self.AlertRadius) and self.AlertRadius:GetValue() or 300,
		combatRadius = IsValid(self.CombatRadius) and self.CombatRadius:GetValue() or 150,
		deathSound = IsValid(self.DeathSound) and self.DeathSound:GetValue() or '',
		painSound = IsValid(self.PainSound) and self.PainSound:GetValue() or '',
		alertSound = IsValid(self.AlertSound) and self.AlertSound:GetValue() or '',
		squadName = IsValid(self.SquadName) and self.SquadName:GetValue() or '',
		useCitizenModel = IsValid(self.UseCitizenModel) and self.UseCitizenModel:GetChecked() or false,
		canDrop = IsValid(self.CanDrop) and self.CanDrop:GetChecked() or false,
		relationships = {}
	}
	
	-- Get relationships
	if IsValid(self.RelationshipPanel) then
		-- Use Lines table instead of GetLineCount method
		local lines = self.RelationshipPanel.Lines or {}
		for i = 1, #lines do
			local line = lines[i]
			if line then
				table.insert(settings.relationships, {
					class = line:GetColumnText(1),
					disposition = line:GetColumnText(2)
				})
			end
		end
	end
	
	return settings
end

function EDITOR:ApplySettings(settings)
	if not settings then return end
	
	if IsValid(self.NPCName) then self.NPCName:SetValue(settings.name or '') end
	if IsValid(self.NPCClass) then self.NPCClass:SetValue(settings.class or '') end
	if IsValid(self.ModelPath) then self.ModelPath:SetValue(settings.model or 'models/player.mdl') end
	if IsValid(self.NPCHealth) then self.NPCHealth:SetValue(settings.health or 100) end
	if IsValid(self.NPCWalkSpeed) then self.NPCWalkSpeed:SetValue(settings.walkSpeed or 150) end
	if IsValid(self.NPCAdminOnly) then self.NPCAdminOnly:SetChecked(settings.adminOnly or false) end
	if IsValid(self.NPCSkin) then self.NPCSkin:SetValue(settings.skin or 0) end
	if IsValid(self.NPCScale) then self.NPCScale:SetValue(settings.scale or 1.0) end
	if IsValid(self.AlertRadius) then self.AlertRadius:SetValue(settings.alertRadius or 300) end
	if IsValid(self.CombatRadius) then self.CombatRadius:SetValue(settings.combatRadius or 150) end
	if IsValid(self.DeathSound) then self.DeathSound:SetValue(settings.deathSound or '') end
	if IsValid(self.PainSound) then self.PainSound:SetValue(settings.painSound or '') end
	if IsValid(self.AlertSound) then self.AlertSound:SetValue(settings.alertSound or '') end
	if IsValid(self.SquadName) then self.SquadName:SetValue(settings.squadName or '') end
	if IsValid(self.UseCitizenModel) then self.UseCitizenModel:SetChecked(settings.useCitizenModel or false) end
	if IsValid(self.CanDrop) then self.CanDrop:SetChecked(settings.canDrop or false) end
	
	-- Apply relationships
	if IsValid(self.RelationshipPanel) and settings.relationships then
		self.RelationshipPanel:Clear()
		for _, rel in ipairs(settings.relationships) do
			self.RelationshipPanel:AddLine(rel.class, rel.disposition)
		end
	end
	
	-- Update preview
	if IsValid(self.PreviewPanel) and settings.model then
		self.PreviewPanel:SetModel(settings.model)
	end
end

function EDITOR:LoadTemplateByName(templateName)
	for className, data in pairs(self.Templates) do
		if data.name == templateName then
			self:LoadTemplate(className)
			return
		end
	end
	
	Derma_Message('Template not found: ' .. templateName, 'Load Error', 'OK')
end

function EDITOR:GenerateSNPCLua(npcData)
	local lua = string.format([[
AddCSLuaFile()

ENT.Base = "base_nextbot"
ENT.Type = "nextbot"

ENT.PrintName = "%s"
ENT.Category = "ZDEV SNPCs"
ENT.Spawnable = true
ENT.AdminOnly = %s

function ENT:Initialize()
	self:SetModel("%s")
	self:SetHealth(%d)
	self:SetMaxHealth(%d)
	
	if SERVER then
		self:SetSkin(%d)
		self:SetModelScale(%g)
		
		-- Set squad
		if "%s" ~= "" then
			self:SetKeyValue("squadname", "%s")
		end
		
		-- Set relationships
%s
	end
end

function ENT:RunBehaviour()
	while true do
		-- Basic AI behavior
		local target = self:GetNearestPlayer()
		if IsValid(target) and self:GetRangeTo(target) < %d then
			self:StartActivity(ACT_IDLE_ANGRY)
			if self:GetRangeTo(target) < %d then
				-- Combat behavior
				self:StartActivity(ACT_MELEE_ATTACK1)
			else
				-- Approach target
				self:MoveToPos(target:GetPos())
			end
		else
			-- Idle behavior
			self:StartActivity(ACT_IDLE)
		end
		
		coroutine.wait(1)
	end
end

function ENT:OnTakeDamage(dmg)
	if "%s" ~= "" then
		self:EmitSound("%s")
	end
	
	return self:GetHealth() <= 0
end

function ENT:OnKilled(dmg)
	if "%s" ~= "" then
		self:EmitSound("%s")
	end
	
	-- Drop weapons if enabled
	if %s then
		-- Add weapon drop logic here
	end
end

function ENT:GetNearestPlayer()
	local nearest = nil
	local nearestDist = math.huge
	
	for _, ply in ipairs(player.GetAll()) do
		if ply:Alive() then
			local dist = self:GetRangeTo(ply)
			if dist < nearestDist then
				nearest = ply
				nearestDist = dist
			end
		end
	end
	
	return nearest
end
]], 
	npcData.name,
	npcData.adminOnly and "true" or "false",
	npcData.model,
	npcData.health,
	npcData.health,
	npcData.skin,
	npcData.scale,
	npcData.squadName,
	npcData.squadName,
	self:GenerateRelationshipCode(npcData.relationships),
	npcData.alertRadius,
	npcData.combatRadius,
	npcData.painSound,
	npcData.painSound,
	npcData.deathSound,
	npcData.deathSound,
	npcData.canDrop and "true" or "false"
	)
	
	return lua
end

function EDITOR:GenerateRelationshipCode(relationships)
	if not relationships or #relationships == 0 then
		return "\t\t-- No custom relationships"
	end
	
	local code = {}
	for _, rel in ipairs(relationships) do
		local disp = "D_NU"
		if string.find(rel.disposition, "Like") then
			disp = "D_LI"
		elseif string.find(rel.disposition, "Hate") then
			disp = "D_HT"
		elseif string.find(rel.disposition, "Fear") then
			disp = "D_FR"
		end
		
		table.insert(code, string.format('\t\tself:AddEntityRelationship("%s", %s, 99)', rel.class, disp))
	end
	
	return table.concat(code, '\n')
end

function EDITOR:LoadExampleConfiguration(exampleName)
	local examples = {
		['Basic Guard'] = {
			name = 'Security Guard',
			class = 'npc_security_guard',
			model = 'models/humans/group01/male_02.mdl',
			health = 150,
			walkSpeed = 120,
			alertRadius = 400,
			combatRadius = 200,
			squadName = 'security_team'
		},
		['Heavy Soldier'] = {
			name = 'Heavy Combat Soldier',
			class = 'npc_heavy_soldier',
			model = 'models/combine_soldier.mdl',
			health = 300,
			walkSpeed = 100,
			alertRadius = 600,
			combatRadius = 300,
			squadName = 'combat_unit',
			adminOnly = true
		},
		['Civilian Worker'] = {
			name = 'Civilian Worker',
			class = 'npc_civilian_worker',
			model = 'models/humans/group01/male_01.mdl',
			health = 50,
			walkSpeed = 80,
			alertRadius = 200,
			combatRadius = 0,
			useCitizenModel = true
		},
		['Elite Commander'] = {
			name = 'Elite Commander',
			class = 'npc_elite_commander',
			model = 'models/combine_soldier.mdl',
			health = 500,
			walkSpeed = 140,
			alertRadius = 800,
			combatRadius = 400,
			squadName = 'elite_unit',
			adminOnly = true,
			skin = 1,
			scale = 1.2
		},
		['Friendly Medic'] = {
			name = 'Medical Personnel',
			class = 'npc_medic',
			model = 'models/humans/group01/female_01.mdl',
			health = 100,
			walkSpeed = 110,
			alertRadius = 300,
			combatRadius = 0,
			squadName = 'medical_team'
		}
	}
	
	local config = examples[exampleName]
	if config then
		self:ApplySettings(config)
		Derma_Message('Example "' .. exampleName .. '" loaded successfully!', 'Example Loaded', 'OK')
	else
		Derma_Message('Example not found: ' .. exampleName, 'Load Error', 'OK')
	end
end

function EDITOR:ShowRelationshipDialog()
	local frame = vgui.Create('DFrame')
	frame:SetSize(400, 200)
	frame:SetTitle('Add Relationship')
	frame:Center()
	frame:MakePopup()
	
	local panel = vgui.Create('DPanel', frame)
	panel:Dock(FILL)
	panel:DockMargin(10, 10, 10, 10)
	
	-- Entity class input
	local classLabel = vgui.Create('DLabel', panel)
	classLabel:SetText('Entity Class:')
	classLabel:Dock(TOP)
	classLabel:DockMargin(0, 0, 0, 5)
	
	local classEntry = vgui.Create('DTextEntry', panel)
	classEntry:SetPlaceholderText('e.g., npc_citizen')
	classEntry:Dock(TOP)
	classEntry:DockMargin(0, 0, 0, 10)
	
	-- Disposition dropdown
	local dispLabel = vgui.Create('DLabel', panel)
	dispLabel:SetText('Disposition:')
	dispLabel:Dock(TOP)
	dispLabel:DockMargin(0, 0, 0, 5)
	
	local dispCombo = vgui.Create('DComboBox', panel)
	dispCombo:AddChoice('D_LI - Like')
	dispCombo:AddChoice('D_HT - Hate')
	dispCombo:AddChoice('D_FR - Fear')
	dispCombo:AddChoice('D_NU - Neutral')
	dispCombo:Dock(TOP)
	dispCombo:DockMargin(0, 0, 0, 10)
	
	-- Buttons
	local btnPanel = vgui.Create('DPanel', panel)
	btnPanel:SetTall(30)
	btnPanel:Dock(BOTTOM)
	
	local addBtn = vgui.Create('DButton', btnPanel)
	addBtn:SetText('Add')
	addBtn:SetWide(80)
	addBtn:Dock(RIGHT)
	addBtn:DockMargin(5, 0, 0, 0)
	addBtn.DoClick = function()
		local class = classEntry:GetValue()
		local disp = dispCombo:GetSelected()
		if class ~= '' and disp then
			self.RelationshipPanel:AddLine(class, disp)
			frame:Close()
		end
	end
	
	local cancelBtn = vgui.Create('DButton', btnPanel)
	cancelBtn:SetText('Cancel')
	cancelBtn:SetWide(80)
	cancelBtn:Dock(RIGHT)
	cancelBtn.DoClick = function()
		frame:Close()
	end
end

function EDITOR:ShowModelBrowser()
	local frame = vgui.Create('DFrame')
	frame:SetSize(600, 500)
	frame:SetTitle('Model Browser')
	frame:Center()
	frame:MakePopup()
	
	local panel = vgui.Create('DPanel', frame)
	panel:Dock(FILL)
	panel:DockMargin(10, 10, 10, 10)
	
	-- Search box
	local searchLabel = vgui.Create('DLabel', panel)
	searchLabel:SetText('Search Models:')
	searchLabel:SetFont('DermaDefaultBold')
	searchLabel:Dock(TOP)
	searchLabel:DockMargin(0, 0, 0, 5)
	
	local searchBox = vgui.Create('DTextEntry', panel)
	searchBox:SetPlaceholderText('Type to filter models...')
	searchBox:Dock(TOP)
	searchBox:DockMargin(0, 0, 0, 10)
	
	-- Model categories
	local catPanel = vgui.Create('DPanel', panel)
	catPanel:SetTall(35)
	catPanel:Dock(TOP)
	catPanel:DockMargin(0, 0, 0, 5)
	catPanel.Paint = function() end
	
	local catLabel = vgui.Create('DLabel', catPanel)
	catLabel:SetText('Category:')
	catLabel:SetWide(60)
	catLabel:Dock(LEFT)
	catLabel:SetFont('DermaDefaultBold')
	
	local categoryCombo = vgui.Create('DComboBox', catPanel)
	categoryCombo:AddChoice('Players', 'models/player/')
	categoryCombo:AddChoice('NPCs', 'models/humans/')
	categoryCombo:AddChoice('Combine', 'models/combine_soldier/')
	categoryCombo:AddChoice('Citizens', 'models/humans/group01/')
	categoryCombo:AddChoice('Zombies', 'models/zombie/')
	categoryCombo:AddChoice('Antlions', 'models/antlion/')
	categoryCombo:AddChoice('All Models', 'models/')
	categoryCombo:SetValue('Players')
	categoryCombo:Dock(FILL)
	categoryCombo:DockMargin(5, 0, 0, 0)
	
	-- Model list
	local modelList = vgui.Create('DListView', panel)
	modelList:AddColumn('Model Path')
	modelList:Dock(FILL)
	modelList:DockMargin(0, 0, 0, 50)
	
	-- Preview panel
	local previewPanel = vgui.Create('DModelPanel', panel)
	previewPanel:SetTall(150)
	previewPanel:Dock(RIGHT)
	previewPanel:SetWide(200)
	previewPanel:DockMargin(10, 0, 0, 50)
	previewPanel:SetModel('models/player.mdl')
	
	-- Populate models function
	local function PopulateModels(searchTerm, categoryPath)
		modelList:Clear()
		
		-- Common model paths to search
		local modelPaths = {
			'models/player.mdl',
			'models/humans/group01/male_01.mdl',
			'models/humans/group01/male_02.mdl',
			'models/humans/group01/male_03.mdl',
			'models/humans/group01/male_04.mdl',
			'models/humans/group01/male_05.mdl',
			'models/humans/group01/male_06.mdl',
			'models/humans/group01/male_07.mdl',
			'models/humans/group01/male_08.mdl',
			'models/humans/group01/male_09.mdl',
			'models/humans/group01/female_01.mdl',
			'models/humans/group01/female_02.mdl',
			'models/humans/group01/female_03.mdl',
			'models/humans/group01/female_04.mdl',
			'models/humans/group01/female_05.mdl',
			'models/humans/group01/female_06.mdl',
			'models/combine_soldier.mdl',
			'models/police.mdl',
			'models/zombie/classic.mdl',
			'models/zombie/poison.mdl',
			'models/zombie/fast.mdl',
			'models/antlion.mdl',
			'models/antlion_guard.mdl',
			'models/headcrab.mdl',
			'models/headcrabblack.mdl',
			'models/headcrabfast.mdl'
		}
		
		for _, modelPath in ipairs(modelPaths) do
			local shouldAdd = true
			
			-- Filter by category
			if categoryPath and categoryPath ~= 'models/' then
				shouldAdd = string.find(modelPath, categoryPath, 1, true) ~= nil
			end
			
			-- Filter by search term
			if searchTerm and searchTerm ~= '' then
				shouldAdd = shouldAdd and (string.find(string.lower(modelPath), string.lower(searchTerm), 1, true) ~= nil)
			end
			
			if shouldAdd then
				local line = modelList:AddLine(modelPath)
				line.modelPath = modelPath
			end
		end
	end
	
	-- Initial population
	PopulateModels('', 'models/player/')
	
	-- Search functionality
	searchBox.OnEnter = function()
		local _, categoryPath = categoryCombo:GetSelected()
		PopulateModels(searchBox:GetValue(), categoryPath)
	end
	
	-- Category change
	categoryCombo.OnSelect = function(combo, index, value, data)
		PopulateModels(searchBox:GetValue(), data)
	end
	
	-- Model selection
	modelList.OnRowSelected = function(list, lineID, line)
		if line.modelPath then
			previewPanel:SetModel(line.modelPath)
		end
	end
	
	-- Buttons
	local btnPanel = vgui.Create('DPanel', panel)
	btnPanel:SetTall(35)
	btnPanel:Dock(BOTTOM)
	btnPanel.Paint = function() end
	
	local selectBtn = vgui.Create('DButton', btnPanel)
	selectBtn:SetText('Select Model')
	selectBtn:SetWide(100)
	selectBtn:Dock(RIGHT)
	selectBtn:DockMargin(5, 0, 0, 0)
	selectBtn.DoClick = function()
		local lineID = modelList:GetSelectedLine()
		if lineID then
			local line = modelList:GetLine(lineID)
			if line and line.modelPath then
				self.ModelPath:SetValue(line.modelPath)
				if IsValid(self.PreviewPanel) then
					self.PreviewPanel:SetModel(line.modelPath)
				end
				frame:Close()
			else
				Derma_Message('Selected model has no path.', 'Invalid Selection', 'OK')
			end
		else
			Derma_Message('Please select a model first.', 'No Selection', 'OK')
		end
	end
	
	local cancelBtn2 = vgui.Create('DButton', btnPanel)
	cancelBtn2:SetText('Cancel')
	cancelBtn2:SetWide(80)
	cancelBtn2:Dock(RIGHT)
	cancelBtn2.DoClick = function()
		frame:Close()
	end
end

-- Console command to open the editor
concommand.Add('zdev_snpc_editor', function()
	ZDEV.SNPC.OpenEditor()
end)

-- Add to main menu
ZDEV.VGUI.AddToMainMenu('zdev_snpc_editor')
