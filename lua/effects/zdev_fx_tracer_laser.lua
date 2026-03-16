
EFFECT.Filename = "zdev_fx_tracer_laser"
EFFECT.Category = "Tracer"
EFFECT.Name = "Laser Tracer Generic"
EFFECT.Description = "Tracer effect base for all laser weapon projectiles/shooting effect."
EFFECT.Author = "ZCOM Studios"
EFFECT.Contact = "dev@zcomstudios.com"
EFFECT.Website = "http:--zcomstudios.com"
EFFECT.Spawnable = false
EFFECT.DebugMode = true
EFFECT.Mat = Material( "effects/laser1" )
EFFECT.MatSprite = Material( "sprites/particle_glov_bfg" )
EFFECT.MatTracer = Material( "particle/beam_refract" )
EFFECT.MatTracer2 = Material( "effects/beam_generic_2" )
EFFECT.MultiplierSize = 12
function EFFECT:Init( data )

	self.Position = data:GetStart()
	self.WeaponEnt = data:GetEntity()
	self.Attachment = data:GetAttachment()

	-- Keep the start and end pos - we're going to interpolate between them
	self.StartPos = self:GetTracerShootPos( self.Position, self.WeaponEnt, self.Attachment )
	self.EndPos = data:GetOrigin()

	self.Color = data:GetColor()
	self.Size = data:GetScale() * self.MultiplierSize
	self.Angles = data:GetAngles()
	self.Alpha = 255
	self.Life = 0

	local NumParticles = 30

	local emitter = ParticleEmitter( self.EndPos )

	for i = 0, NumParticles do

		local color = Color(math.Rand(0,50),math.Rand(0,200),math.Rand(255,255))   

		local particle = emitter:Add( "effects/spark", self.EndPos )
		if ( particle ) then

			particle:SetDieTime( math.Rand(0.1,0.3 ) )
			local f_LifeTime = particle:GetLifeTime()
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 0 )

			particle:SetStartSize( math.Rand(1,8))
			particle:SetEndSize( particle:GetStartSize() )
			particle:SetStartLength(math.Rand(12,24))
			particle:SetEndLength(particle:GetStartLength())
			--particle:SetRoll( math.Rand( 0, 360 ) )
			--particle:SetRollDelta( math.Rand( -200, 200 ) )

			particle:SetAirResistance( 10 )

			particle:SetColor( color.r, color.g, color.b )

			particle:SetVelocity( VectorRand() * 100 * math.random() )
			particle:SetGravity( Vector( 0, 0, 0 ) )
			particle:SetCollide( false )
			--[[particle:SetNextThink( CurTime() )
			particle:SetThinkFunction(function(pa)
				local f_Rand = math.Rand(0.1,0.9)
				local f_DeltaTime = 1 - (pa:GetLifeTime()/pa:GetDieTime())
				pa:SetColor(255 * f_DeltaTime, 255 * f_DeltaTime, 255 * f_DeltaTime)
				pa:SetNextThink(CurTime())
			end)]]--
		end

	end

	emitter:Finish()

	self:SetRenderBoundsWS( self.StartPos, self.EndPos )

end

function EFFECT:Think()

	self.Life = self.Life + FrameTime() * 4
	self.Alpha = 255 * ( 1 - self.Life )
	local dlight = DynamicLight( LocalPlayer():EntIndex() )
	if ( dlight ) then
		dlight.pos = self.EndPos
		dlight.r = 100
		dlight.g = 200
		dlight.b = 255
		dlight.brightness = 2
		dlight.decay = 1000
		dlight.size = 128
		dlight.dietime = CurTime() + 1
	end
	return ( self.Life < 1 )

end

function EFFECT:Render()

	if ( self.Alpha < 1 ) then return end

	render.SetMaterial( self.MatSprite )
	render.DrawSprite( self.StartPos, self.Size * (1-self.Life), self.Size * (1-self.Life), Color( 100, 200, 255, self.Alpha ) )						
	render.DrawQuadEasy( self.StartPos, self.Angles:Forward(), self.Size * (1-self.Life), self.Size * (1-self.Life), Color( 100, 200, 255, self.Alpha ) )
	render.DrawQuadEasy( self.EndPos, self.Angles:Forward(), self.Size * 9, self.Size * 9, Color( 100, 200, 255, self.Alpha ) )

	render.SetMaterial( self.MatTracer )
	local texcoord = math.Rand( 0, 1 )

	local norm = (self.StartPos - self.EndPos) * self.Life

	self.Length = norm:Length()

	for i = 1, 3 do

		render.DrawBeam( self.StartPos - norm,		-- Start
					self.EndPos,					-- End
					7* i * (1-self.Life),								-- Width
					texcoord,						-- Start tex coord
					texcoord + self.Length / 128,	-- End tex coord
          Color(100,200,255,255))
					--Color( 255 - (100 * math.cos(CurTime() /12)), 50, 150 + math.cos(CurTime() /12)*100))		-- Color (optional)
	end

	render.SetMaterial( self.MatTracer2 )

	render.DrawBeam( self.StartPos,
					self.EndPos,
					math.Rand(2,4),
					texcoord,
					texcoord + ( ( self.StartPos - self.EndPos ):Length() / 128 ),
          Color( 100 * math.sin(CurTime() / 12) * 50, 200, 255, 128 * ( 1 - self.Life ) )
          --Color( 150 * math.sin(CurTime() / 12) * 50, 0, 255, 128 * ( 1 - self.Life ) )
	)
end