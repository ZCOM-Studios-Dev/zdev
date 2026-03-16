local _f = 'zdev/client/vgui/zd_cl_menu_npcs.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
--
if ZDEV.FILE.Loaded( _f ) then return end


local player = player
local ents = ents
local util = util
local math = math
local string = string
local bit = bit
local gamemode = gamemode
local hook = hook
local Vector = Vector
local VectorRand = VectorRand
local Angle = Angle
local AngleRand = AngleRand
local Entity = Entity
local Color = Color
local FrameTime = FrameTime
local RealTime = RealTime
local CurTime = CurTime
local SysTime = SysTime
local EyePos = EyePos
local EyeAngles = EyeAngles
local pairs = pairs
local ipairs = ipairs
local tostring = tostring
local tonumber = tonumber

local Lerp = Lerp
local type = type
local TEAM_SPY = TEAM_SPY
local TEAM_MERC = TEAM_MERC

--ZDEV = ZDEV or {}
-- print('')

local cli = LocalPlayer()
local SW, SH = ScrW(), ScrH()

local _NPC = {
	Selected = {},

}
  --[[=============================================================
    ZDEV Test VGUI Mwnu
  ==================================================================]]
-- ZDEV_UID: ZDEV_FUNC_14BB66A2 | Path: ZDEV.VGUI.NPCMenu
function ZDEV.VGUI.NPCMenu( ply, cmd, arg )
	
	cli = cli or LocalPlayer()
	--if not cli or not IsValid(cli) or cli ~= LocalPlayer() then return end

	local frame = ZDEV.VGUI.CreateFrame( 600, 400, "NPCs" )

	local npcList = vgui.Create("DListView")
	npcList:AddColumn("Index")
	npcList:AddColumn("Classname")
	npcList:AddColumn("BaseClass")
	npcList:AddColumn("Type")
	npcList:SetMultiSelect(false)
	frame:AddToContent(npcList)

	for _, n in ipairs(ents.GetAll()) do
		if n:IsNPC() or n:IsScripted() then
			local class = n:GetClass()
			local base = baseclass.Get(class) and baseclass.Get(class).Base or "?"
			local typ = n.Type or "?"
			npcList:AddLine(n:EntIndex(), class, base, typ)
		end
	end

	local nnPanel = vgui.Create("DPanel")
	nnPanel:SetTall(220)
	nnPanel.Paint = function(s, w, h)
		draw.RoundedBox(4, 0, 0, w, h, Color(60, 60, 80, 220))
		draw.SimpleText("Neural Network Visualization", "DermaDefaultBold", 8, 8, Color(200,255,200), TEXT_ALIGN_LEFT)
		draw.SimpleText("Select an NPC to view its neural network.", "DermaDefault", 8, 32, Color(180,180,180), TEXT_ALIGN_LEFT)
	end
	frame:AddToContent(nnPanel)

	-- Use ui3d2d for 3D2D neural network visualization
	local function drawNNGraph3D(nn, pos, ang, scale)
		if not nn or not nn.weights1 or not nn.weights2 then return end
		ui3d2d.Start(pos, ang, scale)
		local w, h = 320, 220
		local leftX, rightX = 60, w - 60
		local topY, botY = 60, h - 60
		local inputN = #nn.weights1
		local hiddenN = #nn.weights1[1]
		local outputN = #nn.weights2[1]
		local nodeR = 12
		local spacingY = (botY - topY) / math.max(inputN, hiddenN, outputN)
		local nodes = {input={},hidden={},output={}}
		ui3d2d.DrawPanel(0, 0, w, h, Color(40,40,60,220))
		-- Draw input nodes
		for i=1,inputN do
			local y = topY + (i-1)*spacingY
			draw.RoundedBox(nodeR, leftX, y, nodeR, nodeR, Color(100,200,255))
			ui3d2d.DrawText("I"..i, "DermaDefault", leftX+nodeR+2, y+nodeR/2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			nodes.input[i] = {x=leftX+nodeR/2, y=y+nodeR/2}
		end
		-- Draw hidden nodes
		for i=1,hiddenN do
			local y = topY + (i-1)*spacingY
			draw.RoundedBox(nodeR, w/2, y, nodeR, nodeR, Color(200,200,100))
			ui3d2d.DrawText("H"..i, "DermaDefault", w/2+nodeR+2, y+nodeR/2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			nodes.hidden[i] = {x=w/2+nodeR/2, y=y+nodeR/2}
		end
		-- Draw output nodes
		for i=1,outputN do
			local y = topY + (i-1)*spacingY
			draw.RoundedBox(nodeR, rightX, y, nodeR, nodeR, Color(255,100,100))
			ui3d2d.DrawText("O"..i, "DermaDefault", rightX+nodeR+2, y+nodeR/2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			nodes.output[i] = {x=rightX+nodeR/2, y=y+nodeR/2}
		end
		-- Draw weights (input->hidden)
		for i=1,inputN do
			for j=1,hiddenN do
				local wgt = nn.weights1[i][j]
				surface.SetDrawColor(100,200,255,math.Clamp(math.abs(wgt)*255,50,255))
				surface.DrawLine(nodes.input[i].x, nodes.input[i].y, nodes.hidden[j].x, nodes.hidden[j].y)
			end
		end
		-- Draw weights (hidden->output)
		for i=1,hiddenN do
			for j=1,outputN do
				local wgt = nn.weights2[i][j]
				surface.SetDrawColor(255,100,100,math.Clamp(math.abs(wgt)*255,50,255))
				surface.DrawLine(nodes.hidden[i].x, nodes.hidden[i].y, nodes.output[j].x, nodes.output[j].y)
			end
		end
		ui3d2d.End()
	end

	npcList.OnRowSelected = function(lst, index, pnl)
		local entIdx = tonumber(pnl:GetColumnText(1))
		local npc = Entity(entIdx)
		if IsValid(npc) and (npc.Type == "ai" or npc.Type == "nextbot") and npc.nn then
			nnPanel.Paint = function(s, w, h)
				draw.RoundedBox(4, 0, 0, w, h, Color(60, 60, 80, 220))
				draw.SimpleText("Neural Network Weights (Live)", "DermaDefaultBold", 8, 8, Color(200,255,200), TEXT_ALIGN_LEFT)
				-- 2D fallback
				-- drawNNGraph(npc.nn, w, h)
			end
			-- 3D2D overlay using ui3d2d
			hook.Add("PostDrawOpaqueRenderables", "ZDEV_NNGraph3D2D", function()
				if not IsValid(npc) then hook.Remove("PostDrawOpaqueRenderables", "ZDEV_NNGraph3D2D") return end
				local pos = npc:GetPos() + Vector(0,0,90)
				local ang = Angle(0, LocalPlayer():EyeAngles().y-90, 90)
				drawNNGraph3D(npc.nn, pos, ang, 0.2)
			end)
		else
			nnPanel.Paint = function(s, w, h)
				draw.RoundedBox(4, 0, 0, w, h, Color(60, 60, 80, 220))
				draw.SimpleText("No neural network data for this NPC.", "DermaDefaultBold", 8, 8, Color(255,200,200), TEXT_ALIGN_LEFT)
			end
			hook.Remove("PostDrawOpaqueRenderables", "ZDEV_NNGraph3D2D")
		end
		nnPanel:InvalidateLayout(true)
	end
end
concommand.Add( "zd_menu_npcs", ZDEV.VGUI.NPCMenu )
ZDEV.VGUI.AddToMainMenu( "zd_menu_npcs" )

ZDEV.FILE.SetLoaded( _f )
