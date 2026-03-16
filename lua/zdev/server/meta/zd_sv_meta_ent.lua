local _f = 'zdev/server/meta/zd_sv_meta_ent.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
--
if ZDEV.FILE.Loaded( _f ) then return end

ZDEV.FILE.SetLoaded( _f )

local meta = FindMetaTable( "Entity" )
if not meta then return end


local t_typeconv = {
	string = SetNWString

}
function meta:NetworkKeyValues()

	local kv = self:GetKeyValues()
	local kv_keys = table.GetKeys( kv )

	for i = 1, table.Count( kv_keys ) do
		local key = kv_keys[ i ]
		local val = kv[ key ]
		local val_type = type( val )

	end

end
