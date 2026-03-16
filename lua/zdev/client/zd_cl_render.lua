local _f = 'zdev/client/zd_cl_render.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
--
if ZDEV.FILE.Loaded( _f ) then return end

local LP = LocalPlayer()

local mat_ring = Material( "hud/circle/zedit_brush_cir01.png" )
local function RenderGroundBrush( tr, radius, color )

	local hitpos = tr.HitPos
	local ang = ( CurTime() * 50 ) % 360
	local normal = tr.HitNormal
	local pos = hitpos + normal

	render.SetMaterial( mat_ring )
	for i = 1, 31 do
		
		if i > 1 then
			pos = pos + Vector(0,0,(i*3))
			local ts = TimedSin( 5 ^ i, 30, 3, 3)
			pos = pos + VectorRand() * i / ts
			color.a = ( ts * i ) / i*10
		end
		color.a = ( color.a / 10 ^ i) or 50
		render.DrawQuadEasy( pos, normal, radius*2, radius*2, color, ang )
		render.DrawWireframeSphere( pos, radius, 24, 24, color )
	end
end

local function RenderHelperLines( )

	local trace = LocalPlayer():GetEyeTrace()
	local angle = trace.HitNormal:Angle()

	render.DrawLine( trace.HitPos, trace.HitPos + 8 * angle:Forward(), Color( 255, 0, 0 ), true )
	render.DrawLine( trace.HitPos, trace.HitPos + 8 * -angle:Right(), Color( 0, 255, 0 ), true )
	render.DrawLine( trace.HitPos, trace.HitPos + 8 * angle:Up(), Color( 0, 0, 255 ), true )

end

local function draw_circle( x, y, radius, color, percent )
    percent = percent or 1

    render.SetScissorRect( x - radius, y - radius + radius * 2 * ( 1 - percent ), x + radius, y + radius * 2, true )
        draw.RoundedBox( radius, x - radius, y - radius, radius * 2, radius * 2, color or color_white )
    render.SetScissorRect( 0, 0, 0, 0, false )
end

hook.Add( "HUDPaint", "GMod:Wiki", function()
    local w, h = ScrW() * 0.15, ScrH() * 0.33
	local radius = h * 0.1

	-- Filled circle
 --   draw_circle( w / 2, h * 0.25, radius, Color( 255, 0, 0 ), 1 )

	-- Filled circle + quarter circle
	--draw_circle( w / 2, h / 2, radius, Color( 255, 0, 0 ), 1 )
	--draw_circle( w / 2, h / 2, radius, Color( 0, 255, 0 ), LocalPlayer():Health()/100 )

	-- Half circle
	--draw_circle( w / 2, h * 0.75, radius, Color( 0, 0, 255 ), 0.5 )



end )

-- ZDEV_UID: ZDEV_FUNC_F3487FBD | Path: ZDEV.REND.EnvironmentEditor
function ZDEV.REND.EnvironmentEditor()

	if !GetConVar( "zedit_env_toggle" ):GetBool() then return end

	local trace = LocalPlayer():GetEyeTrace()
	local angle = trace.HitNormal:Angle()
	local radius = GetConVarNumber("zedit_env_brush_radius")

	render.DrawLine( trace.HitPos, trace.HitPos + 8 * angle:Forward(), Color( 255, 0, 0 ), true )
	render.DrawLine( trace.HitPos, trace.HitPos + 8 * -angle:Right(), Color( 0, 255, 0 ), true )
	render.DrawLine( trace.HitPos, trace.HitPos + 8 * angle:Up(), Color( 0, 0, 255 ), true )
	
	RenderGroundBrush( trace, radius, Color(100, 255, 100) )

	cam.Start3D2D( trace.HitPos, angle, 1 )
		surface.SetDrawColor( 255, 165, 0, 255 )
		surface.DrawRect( 0, 0, 8, 8 )
		render.DrawLine( Vector( 0, 0, 0 ), Vector( 8, 8, 8 ), Color( 100, 149, 237, 255 ), true )
	cam.End3D2D()


end
hook.Add("PostDrawOpaqueRenderables", "ZDEV.REND.EnvironmentEditor", ZDEV.REND.EnvironmentEditor )

--[[
local e_ges, e_act, e_seq, t_seqinfo, e_sact, e_samame, e_pos, e_anim, t_seqs, e_mbmin, e_mbmax
hook.Add("PostDrawOpaqueRenderables", "example", function()
	--if GetConVarNumber( "zd_debug_render_entinfo" ) ~= 1 then return end
	local angle = EyeAngles()
	angle = Angle( 0, angle.y, 0 )
	angle:RotateAroundAxis( angle:Up(), -90 )
	angle:RotateAroundAxis( angle:Forward(), 90 )
	local trace = LocalPlayer():GetEyeTrace()
	local pos = trace.HitPos
	pos = pos + Vector( 0, 0, math.cos( CurTime() / 2 ) + 20 )
	cam.Start3D2D( pos, angle, 0.1 )
		-- Get the size of the text we are about to draw
		local text = "Testing"
		text = tostring( LocalPlayer():GetEyeTrace().Entity )
		surface.SetFont( "Default" )
		local tW, tH = surface.GetTextSize( text )

		-- This defines amount of padding for the box around the text
		local pad = 5

		-- Draw a rectable. This has to be done before drawing the text, to prevent overlapping
		-- Notice how we start drawing in negative coordinates
		-- This is to make sure the 3d2d display rotates around our position by its center, not left corner
		surface.SetDrawColor( 0, 0, 0, 255 )
		surface.DrawRect( -tW / 2 - pad, -pad, tW + pad * 2, tH + pad * 2 )

		-- Draw some text
		draw.SimpleText( text, "Default", -tW / 2, 0, color_white )
	cam.End3D2D()

	for k, e in ipairs( ents.GetAll() ) do

		if IsValid(e) then
			e_class = e:GetClass()

			if e:IsNPC() or string.find(e_class, "npc", 1, false ) then

				e_pos = e:GetPos()
				e_ang = e:GetAngles()
				e_mins, e_maxs = e:OBBMins(), e:OBBMaxs()
				e_mbmin, e_mbmax = e:GetModelBounds()
				--t_seqs = e:GetSequenceList()
				e_seq = e:GetSequence()
				e_sact = e:GetSequenceActivity( e_seq )
				e_saname = e:GetSequenceActivityName(e_seq)
				t_seqinfo = e:GetSequenceInfo( e_seq )
				t_seqs = {
					e_seq,
					e_sact,
					e_saname,
				}
				render.DrawBox(e_pos, e_ang, e_mins, e_maxs, Color(255,150,0,30), true )
				render.DrawWireframeBox(e_pos, e_ang, e_mins, e_maxs, Color(255,150,0,255), true )
				render.DrawWireframeBox(e_pos, e_ang, e_mbmin, e_mbmax, Color(0,255,0,255), true )
				surface.SetFont( "Default" )
				surface.SetTextColor( 255, 255, 255 )
				surface.SetTextPos( 128, 128 ) 
				surface.DrawText( "Hello World" )

				
				-- Notice the scale is small, so text looks crispier
				cam.Start3D2D( e_pos + Vector(0,0,e_mbmax.z) + e:GetForward()*16, angle, 0.05 )
					surface.SetMaterial( Material( "dev/wireframe"))
									-- Get the size of the text we are about to draw
					local text = e_class .. "\n" .. tostring(e.IsAgro) .. "\n"
					surface.SetFont( "BudgetLabel" )
					local tW, tH = surface.GetTextSize( text )

					-- This defines amount of padding for the box around the text
					local pad = 5

					-- Draw a rectable. This has to be done before drawing the text, to prevent overlapping
					-- Notice how we start drawing in negative coordinates
					-- This is to make sure the 3d2d display rotates around our position by its center, not left corner
					---surface.SetDrawColor( 0, 0, 0, 255 )
				   -- surface.DrawRect( -tW / 2 - pad, -pad, tW + pad * 2, tH + pad * 2 )

					for j, s in pairs( t_seqinfo ) do
						text = text .. "["..j.."] - "..tostring(s).."\n"
					end
					-- Draw some text


					draw.DrawText( text, "BudgetLabel", -tW / 2, 0, color_white )

				cam.End3D2D()


			end

		end

	end

end )
]]

local mat_sprite = CreateMaterial( "phaz_impact_noz4", "Refract", {
	--["$basetexture"] = "effects/phaz_impact",
	["$ignorez"] = "1",
	["$translucent"] = "1",
	["$additive"] = "1",
	["$refract"] = "1",
	["$refracttint"] = "[0.50 1 1]",
	["$refractamount"] = "0.04",
	["$bluramount"] = "0.01",
	["$refracttexture"] = "_rt_waterrefraction",
	["$vertexcolor"] = "1",
	["$vertexalpha"] = "1",
	["$nofog"] = "1",
	["$forcerefract"] = "1",
	["$modulate"] = "1"
})

local function ColorizeString( str )

	local r, g, b, a = -1, -1, -1, -1
	local t_color = string.Explode( " ", str )
	--for k, c in ipairs( t_color ) do
	--	print( k, c )
	--end
	r, g, b, a = t_color[1], t_color[2], t_color[3], t_color[4]
	local color = Color( r, g, b, a )
	return color
end

local i_nextparticle = 0
RenderList = RenderList or {}
local sprpos,material = Vector(0,0,0), Material( "effects/phaz_impact" )
-- ZDEV_UID: ZDEV_FUNC_D053681B | Path: ZDEV.REND.ParticleEditor
function ZDEV.REND.ParticleEditor( )

	if !GetConVar( "zedit_particle_toggle" ):GetBool() then return end
	RenderHelperLines( )
	local p = ZDEV.EDIT.EMIT.GetConVars()

	local angle = EyeAngles()
	angle = Angle( angle.p, angle.y, 0 )
	angle:RotateAroundAxis( angle:Up(), 90 )

	local trace = LocalPlayer():GetEyeTrace()
	local trent = trace.Entity
	local pos = trace.HitPos
	local size = 256 + 128 * math.sin( CurTime() * 6 ) / 2
	cam.Start3D2D( pos, angle - (Angle( pos - trace.HitNormal)), 1 )
		
		if CurTime() > i_nextparticle then
			
			--if #ZDEV.EDIT.EMIT < 1 then return end
			--for emitter_id, emitter in ipairs( ZDEV.EDIT.EMIT ) do
			--	local p = emitter
				local ent = p.entity
				local offset = p.offset
				--local pos = ZDEV.UTIL.VectorizeString( p.pos )
				local min, max = p.count_min, p.count_max 
				local num, id, mat, life, die, rep = k, p.id, p.material, p.lifetime, p.dietime, p.rep
				local size_s, alpha_s, len_s, size_e, alpha_e, len_e = p.start_size, p.start_alpha, p.start_length, p.end_size, p.end_alpha, p.end_length
				local air, bounce, coll, light, color = p.airres, p.bounce, p.collide, p.lighting, p.color
				local grav, vel = p.gravity, p.velocity
				local roll, rolldel, ang, ang_vel = p.roll, p.rolldelta, p.angles, p.ang_velocity
				local v_grav = ZDEV.UTIL.VectorizeString( grav )
				local m_vel = p.velocity_mul
				local v_vel = ZDEV.UTIL.VectorizeString( vel )
				local a_ang = ZDEV.UTIL.AngleizeString( ang )
				local a_ang_vel = ZDEV.UTIL.AngleizeString( ang_vel )
				local c_color = Color( p.color_r, p.color_g, p.color_b, p.color_a )--ZDEV.UTIL.ColorizeString( color )

				local emit = ParticleEmitter( pos )
				emit:SetNoDraw( false)
				emit:Draw()
				cam.IgnoreZ( true )
				for i = 1, math.random( min, max ) do
					local pa = emit:Add( mat, pos )
					pa:SetColor( c_color )
					pa:SetLifeTime( life )
					pa:SetDieTime( die )
					pa:SetStartSize( size_s )
					pa:SetStartAlpha( alpha_s )
					pa:SetStartLength( len_s )
					pa:SetEndSize( size_e )
					pa:SetEndAlpha( alpha_e )
					pa:SetEndLength( len_e )
					pa:SetAirResistance( air )
					pa:SetBounce( bounce * math.Rand(0.05,1.99) )
					pa:SetCollide( coll ) 
					pa:SetLighting( light )
					pa:SetRoll( roll )
					pa:SetRollDelta( rolldel )
					pa:SetAngles( a_ang )
					pa:SetAngleVelocity( a_ang_vel )
					pa:SetColor( color.r, color.g, color.b )
					pa:SetGravity( v_grav )
					pa:SetVelocity( v_vel * VectorRand() * m_vel )
					--[[pa:SetNextThink( 0.01 )

	pa:SetThinkFunction( function( pa ) 
						local vel = pa:GetVelocity()
						local r, g, b = math.random( 0,255 ), math.random( 0,255 ), 255-math.random( 0,255 )
						pa:SetVelocity( vel )
						--pa:SetColor( r, g, b )
						pa:SetNextThink(300)
					end)
					]]
				end
					cam.IgnoreZ( false )
			--end
			i_nextparticle = CurTime() + rep
			emit:Finish()
		end
	cam.End3D2D()

	RenderList = {}

end
hook.Add("PostDrawOpaqueRenderables", "ZDEV.REND.ParticleEditor", ZDEV.REND.ParticleEditor )

--[[


-- ZDEV_UID: ZDEV_FUNC_B3E50E40 | Path: ZDEV.REND.LightEditor
function ZDEV.REND.LightEditor(  )
	
	if !GetConVar( "zedit_light_toggle" ):GetBool() then return end

	local p = {
		id = GetConVarString( "zedit_light_id")
	}

	local size = 256 + 128 * math.sin( CurTime() * 6 ) / 2
	cam.Start3D2D( pos, angle - (Angle( pos - trace.HitNormal)), 1 )
		cam.IgnoreZ( true )
		cam.IgnoreZ( false )

	cam.End3D2D()
	
end
hook.Add("PostDrawOpaqueRenderables", "ZDEV.REND.LightEditor", ZDEV.REND.LightEditor )


]]


local imgui = include("zdev/client/zd_cl_imgui.lua") -- imgui.lua should be in same folder and AddCSLuaFile'd
zdev.log( "D", "▬▄▬▄▬▄▬▄▬▄▬▄▬▄▬▄▬▄▬▄▬▄▬▄▬▄▬▄▬▄▬▄▬▄▬▄▬▄▬▄▬▄▬▄▬▄▬▄▬▄▬▄▬▄▬▄▬▄▬▄▬▄▬▄▬▄▬▄▬▄▬▄▬▄▬▄▬▄▬▄▬▄" )
if (imgui) then
	DebugPrintTable(imgui)
end
hook.Add("PostDrawTranslucentRenderables", "PaintIMGUI", function(bDrawingSkybox, bDrawingDepth)

  if bDrawingDepth then return end
	--	print( "PostDrawTranslucentRenderables > PaintIMGUI")
	local pos = Vector(0, 0, 0)
	local ang = Angle(0, 0, 90)
  -- Don't render during depth pass
  debugoverlay.Axis( pos, ang, 30, 0.1, true)
  -- Starts the 3D2D context at given position, angle and scale.
  -- First 3 arguments are equivalent to cam.Start3D2D arguments.
  -- Fourth argument is the distance at which the UI panel won't be rendered anymore
  -- Fifth argument is the distance at which the UI will start fading away
  -- Function returns boolean indicating whether we should proceed with the rendering, hence the if statement
  -- These specific coordinates are for gm_construct at next to spawn
  if imgui.Start3D2D(pos, ang, 0.1, 200, 150) then
    -- This is a regular 3D2D context, so you can use normal surface functions to draw things
    surface.SetDrawColor(255, 127, 0)
    surface.DrawRect(0, 0, 100, 20)
    
    -- The main priority of the library is providing interactable panels
    -- This creates a clickable text button at x=0, y=30 with width=100, height=25
    -- The first argument is text to render inside button
    -- The second argument is special font syntax, that dynamically creates font "Roboto" at size 24
    -- The special syntax is just for convinience; you can use normal Garry's Mod font names in place
    -- The third, fourth, fith and sixth arguments are for x, y, width and height
    -- The seventh argument is the border width (optional)
    -- The last 3 arguments are for color, hover color, and press color (optional)
    if imgui.xTextButton("Foo bar", "!Roboto@24", 0, 30, 100, 25, 1, Color(255,255,255), Color(0,0,255), Color(255,0,0)) then
      -- the xTextButton function returns true, if user clicked on this area during this frame
      print("yay, we were clicked :D")
    end
    -- End the 3D2D context
    imgui.End3D2D()
  end
end)

ZDEV.FILE.SetLoaded( _f )