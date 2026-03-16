local _f = 'zdev/shared/zd_sh_effect.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
--
if ZDEV.FILE.Loaded( _f ) then return end

--if ZDEV.SEFX then zdev.log( "S", "Located 'ZDEV.SEFX' master-table." ) else return end

ZDEV.SEFX.INDEX = {}

-- ZDEV_UID: ZDEV_FUNC_0BDA9AE6 | Path: ZDEV.SEFX.RegisterFXType
function ZDEV.SEFX.RegisterFXType( type )
	ZDEV.SEFX.TYPE = ZDEV.SEFX.TYPE or {}
	for i = 1, 7 do
		if not (ZDEV.SEFX.TYPE[ i ]) then
			ZDEV.SEFX.TYPE[ i ] = {name="", icon="", desc="", base=""}
		end
	end
end

-- ZDEV_UID: ZDEV_FUNC_72EB948D | Path: ZDEV.SEFX.GetNameFromFolder
function ZDEV.SEFX.GetNameFromFolder( s_folder )
	local s_name = string.Replace( s_folder, "effects/", "" )
	return s_name
end

-- ZDEV_UID: ZDEV_FUNC_B5F3ABB4 | Path: ZDEV.SEFX.GetAll
function ZDEV.SEFX.GetAll()
	return effects.GetList()
end

-- ZDEV_UID: ZDEV_FUNC_1E97812A | Path: ZDEV.SEFX.Register
function ZDEV.SEFX.Register( fxtbl )

	local eid = ZDEV.UTIL.GenerateUID( 6 )
	local name = ZDEV.SEFX.GetNameFromFolder( fxtbl.Folder )

	if !ZDEV.SEFX[ eid ] then

		fxtbl.Name = name
		fxtbl.ID = eid

		ZDEV.SEFX[ eid ] = fxtbl

	end

end

-- ZDEV_UID: ZDEV_FUNC_142AE1E9 | Path: ZDEV.SEFX.GetByName
function ZDEV.SEFX.GetByName( name )

	local t_fx

	for k, v in pairs( ZDEV.SEFX.GetAll() ) do
		if v.Name == name then
			t_fx = v
			break
		end
	end

	return t_fx

end

-- ZDEV_UID: ZDEV_FUNC_72A5A69F | Path: ZDEV.SEFX.Create
function ZDEV.SEFX.Create( name, pos, ent )
	local efx = util.Effect( name )
end

ZDEV.SEFX.Emitter = {}

function ZDEV.SEFX.Emitter.New( pos, min, max, const )

	local emitter = {}

	emitter.ent = ParticleEmitter( pos )
	emitter.Particles = {}
	for i = 1, math.random( min, max ) do
		emitter.Particles[ i ] = {}
	end
	return emitter

end

function ZDEV.SEFX.Emitter.GetParticles( emit )

end

function ZDEV.SEFX.Emitter.AddParticle( emitter, count_min, count_max, data )

	local particle = {}

end

ZDEV.FILE.SetLoaded( _f )
