
EFFECT.Filename = "zdev_fx_attachment_laser"
EFFECT.Category = "Tracer"
EFFECT.Name = "Laser Tracer Generic"
EFFECT.Description = "Tracer effect base for all laser weapon projectiles/shooting effect."
EFFECT.Author = "ZCOM Studios"
EFFECT.Contact = "dev@zcomstudios.com"
EFFECT.Website = "http:--zcomstudios.com"
EFFECT.Spawnable = false
EFFECT.DebugMode = true
EFFECT.Mat = Material( "effects/laser_line2" )
EFFECT.MatSprite = Material( "effects/redflare" )
EFFECT.MatTracer = Material( "particle/beam_refract" )
EFFECT.MatTracer2 = Material( "effects/beam_generic_2" )
EFFECT.MultiplierSize = 1

function EFFECT:Init( data )

	self.Position = data:GetStart()
	self.WeaponEnt = data:GetEntity()
	self.Attachment = data:GetAttachment()

	-- Keep the start and end pos - we're going to interpolate between them
	self.StartPos = self:GetTracerShootPos( self.Position, self.WeaponEnt, self.Attachment )
	self.EndPos = data:GetOrigin()
	self.Normal = data:GetNormal()
	self.Color = data:GetColor()
	self.Size = data:GetScale() * self.MultiplierSize
	self.Angles = data:GetAngles()
	self.Alpha = 255
	self.Life = 0

	self:SetRenderBoundsWS( self.StartPos, self.EndPos )

end

function EFFECT:Think()

	--[[
	local dlight = DynamicLight( LocalPlayer():EntIndex() )
	if ( dlight ) then
		dlight.pos = self.EndPos
		dlight.r = 255
		dlight.g = 0
		dlight.b = 0
		dlight.brightness = 0.5
		dlight.decay = 500
		dlight.size = 32
		dlight.dietime = CurTime() + 1
	end
	]]
	return true

end

function EFFECT:Render()

	self.Life = self.Life + FrameTime() * 1
	self.Alpha = 255 * ( 1 - self.Life )

	render.SetMaterial( self.MatSprite )
	render.DrawQuadEasy( self.EndPos, self.Normal, self.Size, self.Size, Color( 255, 255, 255, 255 ) )

	render.SetMaterial( self.Mat )
	render.DrawBeam( self.StartPos, self.EndPos, 2, 0, 1, Color(255, 255, 255, 100))

    MsgC(Color(0,255,0), "Life: " .. tostring(self.Life) .. "\n", Color(255,255,0), " Alpha: " .. tostring(self.Alpha) .. "\n", Color(255,0,0), " FrameTime: " .. tostring(FrameTime()) .. "\n", Color(0,0,255), " CurTime: " .. tostring(CurTime()) .. "\n")

	return (self.Life < 1) 
end