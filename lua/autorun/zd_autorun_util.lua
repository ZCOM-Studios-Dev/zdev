local _f = 'autorun/zd_autorun_util.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',Color(150,255,150),"(AUTORUN)",color_white,_f .. '\n')
--
if ZDEV.FILE.Loaded( _f ) then return end
if SERVER then pcall( require, "glon" ) end  -- glon is a server-side binary; skip silently if absent

if SERVER then
	AddCSLuaFile()
end

--[[
	zd_autorun_util.lua
	Utility autorun script for Garry's Mod.
	Author: zcomstudios
	Description: Provides utility functions and helpers for the addon.
]]

local MsgC = MsgC;
local type = type;

-- ZDEV_UID: ZDEV_FUNC_426DAFF8 | Path: ZDEV.UTIL.VectorizeString
function ZDEV.UTIL.VectorizeString( str )
	if type( str ) ~= "string" or str == "" then return end
	local strexp = string.Explode( " ", str )
	local x, y, z = tonumber( strexp[1] ), tonumber( strexp[2] ), tonumber( strexp[3] )
	return Vector( x, y, z )
end

-- ZDEV_UID: ZDEV_FUNC_DC482759 | Path: ZDEV.UTIL.AngleizeString
function ZDEV.UTIL.AngleizeString( str )
	if type( str ) ~= "string" or str == "" then return end
	local strexp = string.Explode( " ", str )
	local p, y, r = tonumber( strexp[1] ), tonumber( strexp[2] ), tonumber( strexp[3] )
	return Angle( p, y, r )
end

-- ZDEV_UID: ZDEV_FUNC_B113D67A | Path: ZDEV.UTIL.ColorizeString
function ZDEV.UTIL.ColorizeString( str )
	if type( str ) ~= "string" or str == "" then return end
	local strexp = string.Explode( " ", str )
	local r, g, b, a = tonumber( strexp[1] ), tonumber( strexp[2] ), tonumber( strexp[3] ), tonumber( strexp[4] )
	print( r, g, b, a )
	return Color( r, g, b, a )
end


--[[---------------------------------
	Make it available Server-side
---------------------------------]]--
local function GetTextSize(x)
	if(SERVER) then
		return x:len(), 1;
	else
		return surface.GetTextSize(x);
	end
end

--[[-------------------------------
	Make a good version of type
-------------------------------]]--

local function PrintType(x)
	if(IsColor(x)) then return "Color"; end
	if(TypeID(x) == TYPE_ENTITY) then
		if(x:IsPlayer()) then return "Player"; end
		return "Entity";
	end
	return type(x);
end

--[[-----------------------------------------------------------
	Do not mess with it unless you know what you are doing!
-----------------------------------------------------------]]--

local function FixTabs(x, width)
	local curw = GetTextSize(x);
	local ret = "";
	while(curw < width) do -- not using string.rep since linux
		x 		= x.." ";
		ret 	= ret.." ";
		curw 	= GetTextSize(x);
	end
	return ret;
end

--[[----------------------------------------------------
	Font based on default ClientScheme resource file
----------------------------------------------------]]--

local linux = system.IsLinux();
local mac	= system.IsOSX();
local win	= system.IsWindows();


if(not SERVER) then
	local _font_data = {
		font	= ((linux or mac) and "Verdana" or "Lucida Console");
		size	= (mac and 11 or linux and 14 or 10);
		weight	= 500;
	}
	-- Fallback to surface.CreateFont if ZDEV.FONT.Register isn't ready yet (load-order safety).
	if ZDEV and ZDEV.FONT and ZDEV.FONT.Register then
		ZDEV.FONT.Register("ConsoleText", _font_data)
	else
		surface.CreateFont("ConsoleText", _font_data)
	end
end

--[[---------------------------------------------------------------------
	Editable Variables:
		typecol: change and/or add types and colors it prints
		DebugFixToString: Add or change how it prints things
		DebugFixToStringColored: Add or change colors/printing styles
---------------------------------------------------------------------]]--

local typecol = {
	boolean         = Color(0x98, 0x81, 0xF5);
	["function"]    = Color(0x00, 0xC0, 0xB6);
	number          = Color(0xF9, 0xD0, 0x8B);
	string          = Color(0xF9, 0x8D, 0x81);
	table           = Color(040, 175, 140);
	func            = Color(0x82, 0xAF, 0xF9);
	etc             = Color(0xF0, 0xF0, 0xF0);
	unk             = Color(255, 255, 255);
	com             = Color(0x00, 0xB0, 0x00);
};

local replacements = {
	["\n"]	= "\\n";
	["\r"]	= "\\r";
	["\v"]	= "\\v";
	["\f"]	= "\\f";
	["\x00"]= "\\x00";
	["\\"]	= "\\\\";
	["\""]	= "\\\"";
}

local ConversionLookupTable = {
	string = function(obj, iscom)
		return {typecol.string, '"'..obj:gsub(".", replacements)..'"'}; -- took from string.lua
	end,
	Vector = function(obj, iscom)
		return {typecol.func, "Vector", typecol.etc, "(", typecol.number, tostring(obj.x), typecol.etc, ", ",
			typecol.number, tostring(obj.y), typecol.etc, ", ", typecol.number, tostring(obj.z), typecol.etc, ")"};
	end,
	Angle = function(obj, iscom)
		return {typecol.func, "Angle", typecol.etc, "(", typecol.number, tostring(obj.p), typecol.etc, ", ",
			typecol.number, tostring(obj.y), typecol.etc, ", ", typecol.number, tostring(obj.r), typecol.etc, ")"};
	end,
	Color = function(obj, iscom)
		return {typecol.func, "Color", typecol.etc, "(", typecol.number, tostring(obj.r), typecol.etc, ", ", typecol.number,
			tostring(obj.g), typecol.etc, ", ", typecol.number, tostring(obj.b), typecol.etc, ", ", typecol.number,
				tostring(obj.a), typecol.etc, ")", typecol.etc, "; ", typecol.com, "-- ", obj, "\xE2\x96\x88 ", typecol.com, string.format("(0x%02X%02X%02X%02X)", obj.r, obj.g, obj.b, obj.a)}, true;
	end,
	Player = function(obj, iscom)
		return {typecol.func, "Player", typecol.etc, "(", typecol.number, tostring(obj:UserID()), typecol.etc,
			")"..(iscom and "; " or ""), typecol.com, (iscom and "-- "..(obj:IsValid() and obj.Nick and obj:Nick() or "missing_nick") or "")}, true;
	end,
};

local function DebugFixToStringColored(obj, iscom)
	local type = PrintType(obj);
	if(ConversionLookupTable[type]) then
		return ConversionLookupTable[type](obj, iscom);
	end
	if(not typecol[type]) then
		return {typecol.unk, "("..type..") "..tostring(obj)};
	else
		return {typecol[type], tostring(obj)};
	end
end

local function DebugFixToString(obj, iscom)
	local ret = "";
	local rets, osc = DebugFixToStringColored(obj, iscom);
	for i = 2, #rets, 2 do
		ret = ret.. rets[i];
	end
	return ret;
end

--[[------------------------------------------------------------------------------
	Function: DebugPrintTable
	Usage: DebugPrintTable( _IN_ to_print, _RESERVED_ spaces, _RESERVED_ done)
	Returns: nil
------------------------------------------------------------------------------]]--

function DebugPrintTable(tbl, spaces, done)
	local buffer = {};
	local rbuf = {};
	local maxwidth = 0;
	local spaces = spaces or 0;
	local done = done or {};
	done[tbl] = true;
	if(not SERVER) then
		surface.SetFont("ConsoleText");
	end
	for key,val in pairs(tbl) do
		rbuf[#rbuf + 1]  = key;
		buffer[#buffer + 1] = "["..DebugFixToString(key).."] ";
		maxwidth = math.max(GetTextSize(buffer[#buffer]), maxwidth);
	end
	local str = string.rep(" ", spaces);
	if(spaces == 0) then MsgN("\n"); end
	MsgC(typecol.etc, "{\n");
	local tabbed = str..string.rep(" ", 4);

	for i = 1, #buffer do
		local overridesc = false;
		local key = rbuf[i];
		local value = tbl[key];
		MsgC(typecol.etc, tabbed.."[");
		MsgC(unpack((DebugFixToStringColored(key))));
		MsgC(typecol.etc, "] "..FixTabs(buffer[i], maxwidth), typecol.etc, "= ");
		if(type(value) == "table" and not IsColor(value) and not done[value]) then
			DebugPrintTable(tbl[key], spaces + 4, done);
		else
			local args, osc = DebugFixToStringColored(value, true);
			overridesc = osc;
			MsgC(unpack(args));
		end
		if(not overridesc) then
			MsgC(typecol.etc, ";");
		end
		MsgN"";
	end
	MsgC(typecol.etc, str.."}");
	if(spaces == 0) then
		MsgN"";
	end
end

--
-- Sizes for ints to send
--
local TYPE_SIZE = 4
local UINTV_SIZE = 5

local Char2HexaLookup, Hexa2CharLookup = {}, {}

--
-- Generate Hexa Lookups
-- Hexa is a 6-bit English character encoding
--
local HexaRanges = {
	{ "a", "z" }, -- 26
	{ "A", "Z" }, -- 52
	{ "0", "9" }, -- 62
	{ "_", "_" }, -- 63
}

local offset = 1

for k, v in ipairs( HexaRanges ) do

	local starts, ends = v[ 1 ]:byte(), v[ 2 ]:byte()

	for char = starts, ends do

		local hexa = char - starts + offset

		Char2HexaLookup[ char ] = hexa
		Hexa2CharLookup[ hexa ] = string.char( char )

	end

	offset = offset + 1 + ends - starts

end

-- Converts an ASCII character in to a Hexa Character
local function CharToHexa( c )

	return Char2HexaLookup[ c ]

end

-- Converts a Hexa character in to an ASCII character
local function HexaToChar( h )

	return Hexa2CharLookup[ h ]

end

-- Returns true if the string can be represented in 7-Bit ASCII
-- Null bytes are not allowed as they are used for termination
local function Is7BitString( str )

	return str:find( "[\x80-\xFF%z]" ) == nil

end

-- Returns true if the string can be represented in Hexa
local function IsHexaString( str )

	return str:find( "[^a-zA-Z0-9_]" ) == nil

end

-- Returns true if the argument is NaN ( can also be interpreted as 0/0 )
local function IsNaN( x )
	return x ~= x
end

-- An imaginary NaN table for caching in writing.table
local NaN = {}

-- This exists because you can't make a table index NaN
-- We need to do this so we can cache it in our references table
local function IndexSafe( x )
	if ( IsNaN( x ) ) then return NaN end
	return x
end

local reading, writing

-- Gets the type of way we are going to send the data
-- Not all of these exist in reality
-- We are only going to add 16 types ( 0-15 ) since that's
-- the max we can fit into 4 bits
local function SendType( x )

	local t = type( x )

	if ( IsColor( x ) ) then
		return "Color"
	end

	if ( TypeID( x ) == TYPE_ENTITY ) then
		return "Entity"
	end

	if ( x == 1 or x == 0 ) then return "bit" end

	--
	-- check if a number has no decimal places
	-- and is able to be sent in an int
	--

	if ( t == "number" and x % 1 == 0 and x >= -0x7FFFFFFF and x <= 0xFFFFFFFF ) then

		-- test if we can fit it in a single iteration with uintv
		if ( x < bit.lshift( 1, UINTV_SIZE ) and x >= 0 ) then
			return "uintv"
		end

		if ( x <= 0x7FFF and x >= -0x7FFF ) then
			return "int16"
		end

		if ( x <= 0x7FFFFFFF and x >= -0x7FFFFFFF ) then
			return "int32"
		end

		return "uintv"

	end

	if ( t == "string" and IsHexaString( x ) ) then
		return "hexastring"
	end

	if ( t == "string" and Is7BitString( x ) ) then
		return "string7"
	end

	return t

end

local StringToTypeLookup, TypeToStringLookup = { }, { }

do
	--
	-- MUST BE 16 OR LESS TYPES
	--
	StringToTypeLookup = {
		-- strings
		string       = 0,
		hexastring   = 1,
		string7      = 2,

		--numbers
		bit          = 3,
		int16        = 4,
		int32        = 5,
		number       = 6,
		uintv        = 7,

		-- default things
		boolean      = 8,

		--float arrays
		Vector       = 9,
		Angle        = 10,

		--tables
		table        = 11,
		reference    = 13,

		-- Garry's Mod specific
		Color        = 14,
		Entity       = 15,
	}

	--
	-- backwards lookup
	--
	for k,v in pairs( StringToTypeLookup ) do
		TypeToStringLookup[ v ] = k
	end

end

local function TypeToString( n )
	return TypeToStringLookup[ n ]
end

local function StringToType( s )
	return StringToTypeLookup[ s ]
end

local ReferenceType = StringToType( "reference" )
local TableType     = StringToType( "table" )

reading = {
	--
	-- Normal gmod types we can't really improve
	--
	Color       = net.ReadColor,
	boolean     = net.ReadBool,
	number      = net.ReadDouble,
	bit         = net.ReadBit,
	Entity      = net.ReadEntity,

	--
	-- Simple integers
	--
	int16 = function() return net.ReadInt( 16 ) end,
	int32 = function() return net.ReadInt( 32 ) end,

	--
	-- A reference index in our already-sent-table
	--
	reference = function( references ) return references[ reading.uintv() ] end,

	--
	-- Variable length unsigned integers
	--
	uintv = function()

		local i = 0
		local ret = 0

		while net.ReadBool() do


			local t = net.ReadUInt( UINTV_SIZE )
			ret = ret + bit.lshift( t, i * UINTV_SIZE )

			i = i + 1

		end

		return ret

	end,

	--
	-- 7 bit encoded strings
	-- NULL terminated
	--
	string7 = function()

		if ( net.ReadBool() ) then -- it's compressed

			return util.Decompress( net.ReadData( reading.uintv() ) )

		else -- it's not compressed

			local ret = ""

			while true do

				local chr = net.ReadUInt( 7 )
				if ( chr == 0 ) then return ret end
				ret = ret..string.char( chr )

			end

		end

	end,

	--
	-- Our 6-bit encoded strings
	-- NULL terminated
	--
	hexastring = function()

		if ( net.ReadBool() ) then

			return util.Decompress( net.ReadData( reading.uintv() ) )

		else

			local ret = ""

			while true do
				local chr = net.ReadUInt( 6 )
				if ( chr == 0 ) then return ret end -- terminator
				ret = ret..Hexa2CharLookup[ chr ]
			end

		end

	end,

	--
	-- C String
	-- NULL terminated
	-- NOTE: Must be NULL terminated or else will break compatibility
	-- with some addons! Also could lead to exploits
	--
	string = function()

		if ( net.ReadBool() ) then -- compressed or not

			return util.Decompress( net.ReadData( reading.uintv() ) )

		else

			return net.ReadString()

		end

	end,

	--
	-- Vector, we are using our own wrapper since
	-- default net.WriteVector loses lots of precision
	--
	Vector = function()
		return Vector( net.ReadFloat(), net.ReadFloat(), net.ReadFloat() )

	end,

	--
	-- Angle, we are using our own wrapper since
	-- default net.WriteAngle loses lots of precision
	--
	Angle = function()
		return Angle( net.ReadFloat(), net.ReadFloat(), net.ReadFloat() )
	end,

	--
	-- our readtable
	-- directly used as net.ReadTable
	--
	table = function( references )

		local ret = {}

		references = references or {};

		local reference = function( type, value )

			if ( not type or ( type ~= TableType and type ~= ReferenceType ) ) then

				table.insert( references, value )

			end

		end

		reference(nil, ret)

		for i = 1, reading.uintv() do

			local type = net.ReadUInt( TYPE_SIZE )

			local value = reading[ TypeToString( type ) ]( references )

			reference(type, value)

			ret[ i ] = value

		end

		for i = 1, reading.uintv() do

			local keytype = net.ReadUInt(TYPE_SIZE)

			local keyvalue = reading[ TypeToString( keytype ) ]( references )

			reference(keytype, keyvalue)


			local valuetype = net.ReadUInt(TYPE_SIZE)

			local valuevalue = reading[ TypeToString( valuetype ) ]( references )

			reference(valuetype, valuevalue)

			ret[ keyvalue ] = valuevalue;

		end

		return ret

	end
}

--
-- We need this since #table returns undefined values
-- by the lua spec if it doesn't have incremental keys
-- we use pairs since it's backwards compatible
--
local function array_len(x)

	local indices = {};
    for k,v in pairs(x) do

        indices[k] = true;

    end

    for i = 1, 8096 do

        if(nil == indices[i]) then
						--	zdev.log( "I",indices[i] )
            return i - 1
        end

    end

    return 8096

end

writing = {

	bit      = net.WriteBit,
	Color    = net.WriteColor,
	boolean  = net.WriteBool,
	number   = net.WriteDouble,
	Entity   = net.WriteEntity,

	int16 = function( w ) net.WriteInt( w, 16 ) end,
	int32 = function( d ) net.WriteInt( d, 32 ) end,

	--
	-- Variable length unsigned integers
	--
	uintv = function( n )

		while( n > 0 ) do

			net.WriteBool(true);
			net.WriteUInt( n, UINTV_SIZE )
			n = bit.rshift( n, UINTV_SIZE )

		end

		net.WriteBool(false);

	end,


	--
	-- 7 bit encoded strings
	-- NULL terminated
	--
	string7 = function( s )

		local null = s:find( "%z" )

		if (null) then

			s = s:sub( 1, null - 1 )

		end


		local compressed = util.Compress( s )

		-- add one for the null terminator
		if ( compressed and compressed:len() < (s:len() + 1) / 8 * 7 ) then

			net.WriteBool( true )
			writing.uintv( compressed:len() )
			net.WriteData( compressed, compressed:len() )

		else

			net.WriteBool( false )

			for i = 1, s:len() do
				net.WriteUInt( s:byte( i, i ), 7 )
			end

			net.WriteUInt( 0, 7 )

		end

	end,

	--
	-- Our 6-bit encoded strings
	-- NULL terminated
	--
	hexastring = function( s )

		local null = s:find( "%z" )

		if (null) then

			s = s:sub( 1, null - 1 )

		end

		local compressed = util.Compress( s )

		-- add one for the null terminator
		if ( compressed and compressed:len() < ( s:len() + 1 ) / 8 * 6 ) then

			net.WriteBool( true )
			writing.uintv( compressed:len() )
			net.WriteData( compressed, compressed:len() )

		else

			net.WriteBool( false )

			for i = 1, s:len() do
				net.WriteUInt( Char2HexaLookup[ s:byte( i, i ) ], 6 )
			end

			net.WriteUInt( 0, 6 )

		end

	end,

	--
	-- C String
	-- NULL terminated
	-- NOTE: Must be NULL terminated or else will break compatibility
	-- with some addons! Also could lead to exploits
	--
	string = function( x )

		local null = x:find( "%z" )

		if (null) then

			x = x:sub( 1, null - 1 )

		end

		local compressed = util.Compress( x )

		if ( compressed and compressed:len() < x:len() + 1 ) then

			net.WriteBool( true )
			writing.uintv( compressed:len() )
			net.WriteData( compressed, compressed:len() )

		else

			net.WriteBool( false )
			net.WriteString( x:len() )

		end

	end,

	--
	-- Vector, we are using our own wrapper since
	-- default net.WriteVector loses lots of precision
	--
	Vector = function( v )

		net.WriteFloat( v.x )
		net.WriteFloat( v.y )
		net.WriteFloat( v.z )

	end,

	--
	-- Angle, we are using our own wrapper since
	-- default net.WriteAngle loses lots of precision
	--
	Angle = function( a )

		net.WriteFloat( a.p )
		net.WriteFloat( a.y )
		net.WriteFloat( a.r )

	end,

	--
	-- our writetable
	-- directly used as net.WriteTable
	--

	table = function( tbl, references, num )

		references = references or {[tbl] = 1}
		num = num or 1

		local SendValue = function( value )

			if ( references[ IndexSafe( value ) ] ) then

				net.WriteUInt( ReferenceType, TYPE_SIZE )
				writing.uintv( references[ IndexSafe( value ) ] )

				return

			end

			local sendtype = SendType( value )

			num = num + 1
			references[ IndexSafe( value ) ] = num

			net.WriteUInt( StringToType( sendtype ), TYPE_SIZE )

		 	num = writing[ sendtype ]( value, references, num ) or num

		end

		local pairs_table = {}

		for k,v in pairs(tbl) do

			pairs_table[k] = v

		end

		local array_size = array_len( pairs_table )

		writing.uintv( array_size )

		for i = 1, array_size do

			local value = pairs_table[ i ]

			pairs_table[ i ] = nil

			SendValue( value )

		end

		local object_key_count = table.Count( pairs_table )

		writing.uintv( object_key_count )

		for k,v in next, pairs_table, nil do

			SendValue( k )
			SendValue( v )

		end

		return num;

	end
}

net.WriteTable = function(t) writing.table(t); end
net.ReadTable = function() return reading.table(); end



--[[〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓
	Utility Functions
〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓]]

do
	--[[===============================================
		FUNC-SH ZDEV.UTILGenerateUID
	===============================================]]
-- ZDEV_UID: ZDEV_FUNC_51C15DA0 | Path: ZDEV.UTIL.GenerateUID
	function ZDEV.UTIL.GenerateUID( len )
		local uid = ""
		for i = 1, len do
			local rand = math.random(1,9)
			uid = uid .. rand
		end
		return uid
	end


	--[[===============================================
		FUNC-SH ZDEv.UTIL.PrintFunctionParameters
	===============================================]]
-- ZDEV_UID: ZDEV_FUNC_A885DCD4 | Path: ZDEV.UTIL.PrintFuncParam
	function ZDEV.UTIL.PrintFuncParam( func, lvl, count  )
		--local args = {...}
		MsgC( Color(255,100,255), "Retrieving Parameters of " .. tostring(func) .. " Level: "..tostring(lvl) .." Count: "..tostring(count) .."\n ")
		local k, param = lvl, debug.getlocal( func, (lvl-1), count )
		while param ~= nil do
			MsgC( Color(150,150,150), "["..tostring(k).."] ", color_white, param, Color(100,200,255), " (" .. tostring(type(param)) .. "), " )
			param = debug.getlocal( func, k )
			k = k - 1
		end
		print( k, param, lvl, count, func )
		Msg("\n")
	end

	--[[===============================================
		FUNC-SH ZDEV.UTIL.DumpEntityMetaTable
	===============================================]]
-- ZDEV_UID: ZDEV_FUNC_BA2C9B40 | Path: ZDEV.UTIL.DumpEntityMeta
	function ZDEV.UTIL.DumpEntityMeta( ent )
		local meta = debug.getmetatable( ent )
		local t_func = {}
		for k, v in pairs( meta ) do
			MsgC( color_white, tostring(k) .. " = ", Color(255,150,0), tostring( ent[k] ) .. "\n" )
			t_func[ k ] = v
		end
		return t_func
	end

end


-- ZDEV_UID: ZDEV_FUNC_FF502A16 | Path: ZDEV.UTIL.AddToTbl
ZDEV.UTIL.AddToTbl = function( t, d )
	if !t or t == nil then	t = {} end
	table.insert( t, d )
end

-- ZDEV_UID: ZDEV_FUNC_DF56C450 | Path: ZDEV.UTIL.GetTraceEnt
function ZDEV.UTIL.GetTraceEnt( ply )
	if not ( IsValid(ply) and ply:Alive() ) then return end
	local tr = ply:GetEyeTrace()
	return tr.Entity
end

-- ZDEV_UID: ZDEV_FUNC_FC0F4855 | Path: ZDEV.UTIL.DropPrimaryWeapon
function ZDEV.UTIL.DropPrimaryWeapon( ply )
	if ply and IsValid(ply) and ply:GetActiveWeapon() and IsValid(ply:GetActiveWeapon() ) then
		local wep = ply:GetActiveWeapon()
		ply:DropWeapon( wep )
		zdev.log( "W", "Forced " ..tostring(ply:Nick()).." to drop primary weapon: "..tostring(wep).." via Utility CMD" )
	end
end
ZDEV.CMDS.Register( "zdev_dev_dropprimary", function(ply, cmd, arg) ZDEV.UTIL.DropPrimaryWeapon(ply) end,
	{ aliases = { "zd_dropprimary" }, flags = 0 } )


-- ZDEV_UID: ZDEV_FUNC_7D4B2DA5 | Path: ZDEV.UTIL.DataFileExists
function ZDEV.UTIL.DataFileExists( s_file )
	return tobool( file.Exists( s_file, "DATA" ))
end

-- ZDEV_UID: ZDEV_FUNC_BDB6F026 | Path: ZDEV.UTIL.AnalyzeTable
function ZDEV.UTIL.AnalyzeTable( tbl )
	zdev.log( "D", "Analyzing table: " .. tostring(tbl) )
	if tbl then
		local s_head = "| KEY | TYPE | VAL "
		MsgC( color_white, s_head .. "\n" );
		for k, v in pairs( tbl ) do
			local s_row = string.format( "| %s | %s | %s ",k,type(v),tostring(v) )
			MsgC( color_white, s_row .. "\n")
			if type(v) == "table" then
				DebugPrintTable(v)
			end
		end
	end

end

-- ZDEV_UID: ZDEV_FUNC_C775AAEF | Path: ZDEV.DATA.ExportToJSON
function ZDEV.DATA.ExportToJSON( t_data, s_filename )

	if (!t_data or type(t_data) ~= "table" ) then return false end

	local t_copy = {}
	for k, v in pairs( t_data ) do
		if type(v) ==  "table" then
			v = table.ToString(v, tostring(k), true)
		end
		t_copy[k] = v
	end

	local tab = util.TableToJSON( t_copy ) -- Convert the player table to JSON
	file.CreateDir( "zdev/export" ) -- Create the directory
	file.Write( "zdev/export/"..s_filename..".txt", tab) -- Write to .txt
end

local t_iter = t_iter or {}
-- ZDEV_UID: ZDEV_FUNC_C3E93CC0 | Path: ZDEV.UTIL.ReIterateTable
function ZDEV.UTIL.ReIterateTable( tbl )
	local t_iter = {}
	local t_keys = table.GetKeys( tbl )
	local s_pre = ""

	for i = 1, table.Count( tbl ) do
		local i_h = i*10
		local j = t_keys[ i ]
		local c = tbl[ j ]

		if type(c) == "table" then
			t_iter[ i ] = {key = j, val = table.ToString(c,j, true), h = i_h }
		else
			t_iter[ i ] = {key = j, val = c, h = i_h }
		end
	end

	return t_iter

end

pcall(require, "glon")
if not glon then 
	MsgC(Color(255, 127, 127), debug.getinfo(1).source .. " could not find glon lua module!\n")
	return
end

ZDEV.UTIL = ZDEV.UTIL or {}
 local s = ZDEV.UTIL

do
	local META = {}
	META.__index = META

	function META:__index(key)
		return rawget(s.SliderVars, key) or 0
	end

	function META:__newindex(key, value)

		if CLIENT then
			value = tonumber(value)
			if value then
				RunConsoleCommand("zdev_dev_slider_vars", key, value)
			end
		end

		if SERVER then
			value = tonumber(value)
			if value then
				umsg.Start("dbgutl_slider_vars")
					umsg.String(key)
					umsg.Float(value)
				umsg.End()
			end
		end

		(SERVER and print or epoe.Print)(key.. " = ".. value .. " ".. (SERVER and "SERVER" or "CLIENT") .. "\n")
	end

	ZDEV.UTIL.SliderVarsMeta = META
	ZDEV.UTIL.SliderVars = setmetatable({}, META)

	if CLIENT then
-- ZDEV_UID: ZDEV_FUNC_553B7A53 | Path: ZDEV.UTIL.ReceiveSliderVar
		function ZDEV.UTIL.ReceiveSliderVar(umr)
			local key = umr:ReadString()
			local value = umr:ReadFloat()

			rawset(ZDEV.UTIL.SliderVars, key, value)
		end

		usermessage.Hook("dbgutl_slider_vars", ZDEV.UTIL.ReceiveSliderVar)
	end

	if SERVER then
-- ZDEV_UID: ZDEV_FUNC_553B7A53 | Path: ZDEV.UTIL.ReceiveSliderVar
		function ZDEV.UTIL.ReceiveSliderVar(ply, _, args)
			if true or ply:IsAdmin() then
				local key = args[1]
				local value = args[2]

				rawset(s.SliderVars, key, tonumber(value))
			end
		end

		ZDEV.CMDS.Register( "zdev_dev_slider_vars", ZDEV.UTIL.ReceiveSliderVar,
			{ aliases = { "dbgutl_slider_vars" } } )
	end
end

-- ╥▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬
-- ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
-- ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
-- ▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃
-- ════════════════════════════════════════════════════════════════
-- ▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅
-- ──────────────────────────────────────────────────────────────────────
-- ▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆
-- CLIENT UTILITY FUNCTIONS
-- ▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆

if CLIENT then
	ZDEV.UTIL.PrintQueue = {}

-- ZDEV_UID: ZDEV_FUNC_8399ED7A | Path: ZDEV.UTIL.ArgsToString
	function ZDEV.UTIL.ArgsToString(...)
		local str = ""
		for _, arg in pairs({...}) do
			local type = type(arg)

			if type == "Vector" then
				str = str .. ("Vector(%s, %s, %s)"):format(math.Round(arg.x, 2), math.Round(arg.y, 2), math.Round(arg.z, 2)) .. "\n"
			elseif type == "Angle" then
				str = str .. ("Angle(%s, %s, %s)"):format(math.Round(arg.p, 2), math.Round(arg.y, 2), math.Round(arg.r, 2)) .. "\n"
			elseif type == "string" or type == "number" then
				str = str .. arg .. "\n"
			else
				str = str .. tostring(arg) .. "\n"
			end
		end

		return str
	end

-- ZDEV_UID: ZDEV_FUNC_0A3E59B1 | Path: ZDEV.UTIL.GarbageCollect
	function ZDEV.UTIL.GarbageCollect()
		for id, data in pairs(s.PrintQueue) do
			if data.time < CurTime() then
				s.PrintQueue[id] = nil
			end
		end
	end

-- ZDEV_UID: ZDEV_FUNC_D0D3D1A1 | Path: ZDEV.UTIL.Print
	function ZDEV.UTIL.Print(id, pos, ...)
		ZDEV.UTIL.GarbageCollect()

		local str = s.ArgsToString(...)
		s.PrintQueue[id] = {
			is_entity = IsEntity(pos),
			pos3d = pos,
			lines = str:Split("\n"),
			args = {...},
			time = CurTime() + 0.1,
		}

		timer.Create("debugutils_gc", 10, 0, ZDEV.UTIL.GarbageCollect)
	end

	local box_x, box_y = 0, 0
	local box_width, box_height = 0, 0

-- ZDEV_UID: ZDEV_FUNC_7FB6B668 | Path: ZDEV.UTIL.HUDPaint
--[[
	function ZDEV.UTIL.HUDPaint()
		for id, data in pairs(s.PrintQueue) do
			local pos
			if data.is_entity and data.pos3d:IsValid() then
				pos = data.pos3d:GetPos():ToScreen()
			else
				pos = data.pos3d:ToScreen()
			end

			box_x = pos.x
			box_y = pos.x

			surface.SetFont("BudgetLabel")
			surface.SetTextColor(color_white)

			for i, line in pairs(data.lines) do
				local width, height = surface.GetTextSize(line)
				height = height * (i-1)
				surface.SetTextPos(pos.x, pos.y + height)
				surface.DrawText(line)

				box_height = height
				box_width = width > box_width and width or box_width
			end

			data.box_height = box_height
			data.box_width = box_width
		end
	end
	hook.Add("HUDPaint", "debugutils_HUDPaint", ZDEV.UTIL.HUDPaint)

	timer.Create("debugutils_gc", 10, 0, ZDEV.UTIL.GarbageCollect)
]]
-- ZDEV_UID: ZDEV_FUNC_3CB36C46 | Path: ZDEV.UTIL.ReceiveServerMessage
	function ZDEV.UTIL.ReceiveServerMessage(umr)
		local id = umr:ReadString()
		local is_entity = umr:ReadBool()
		local pos

		if is_entity then
			pos = umr:ReadEntity()
		else
			pos = umr:ReadVector()
		end

		local args = glon.decode(umr:ReadString())

		s.Print(id, pos, unpack(args))
	end
	usermessage.Hook("debugutils", ZDEV.UTIL.ReceiveServerMessage)

	-- ════════════════════════════════════════════════════════════════
	-- ZDEV Particle Emitter Utility Functions
	function ZDEV.UTIL.SetParticleData( emit, n, mat, particle_data )
		
	end

	--[[-------------------------------------------------------------------------
		Custom Particle Helper Function
	---------------------------------------------------------------------------]]
	local function AddParticle(EmitterEntity, Count, mat, ParticleData)
		-- 1. Check that EmitterEntity is valid
		if not IsValid(EmitterEntity) then return end

		-- 2. Loop for the specified Count
		for i = 1, Count do
			-- Declare local particle at the emitter's current position
			local particle = EmitterEntity:Add(mat, EmitterEntity:GetPos())

			if not particle then continue end

			-- 3. Loop through ParticleData and call corresponding setter functions
			-- Expected table format: { ["DieTime"] = 2, ["Velocity"] = Vector(0, 0, 100), ... }
			for key, value in pairs(ParticleData) do
				local setterName = "Set" .. key
				local setterFunc = particle[setterName]

				if type(setterFunc) == "function" then
					-- Handle cases where parameters are passed as a sub-table or unpackable array
					if type(value) == "table" and value.unpack then
						setterFunc(particle, unpack(value))
					elseif type(value) == "table" and #value > 0 and type(value[1]) ~= "table" then
						-- Fallback for standard array-style tables (like color channels)
						setterFunc(particle, unpack(value))
					else
						-- Single value (Vector, Angle, number, boolean, IMaterial)
						setterFunc(particle, value)
					end
				else
					ErrorNoHalt("CLuaParticle: Method " .. setterName .. " does not exist!\n")
				end
			end
		end
	end
end

-- ▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆
-- SERVER UTILITY FUNCTIONS
-- ▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆▆
if SERVER then
-- ZDEV_UID: ZDEV_FUNC_D0D3D1A1 | Path: ZDEV.UTIL.Print
	function ZDEV.UTIL.Print(id, pos, ...)
		local is_entity = false

		if IsEntity(pos) then
			is_entity = true
		end

		umsg.Start("debugutils")
			umsg.String(tostring(id))
			umsg.Bool(is_entity)

			if is_entity then
				umsg.Entity(pos)
			else
				umsg.Vector(pos)
			end

			umsg.String(glon.encode({...}))
		umsg.End()
	end
end

-- ZDEV_UID: ZDEV_FUNC_47EFF7B2 | Path: ZDEV.UTIL.DirectionFromTo
function ZDEV.UTIL.DirectionFromTo( v0, v1 )
	-- get the direction
	local vec = ( v0 - v1 ):Normalize();
	-- convert the vector to an angle
	local ang = vec:Angle();
	return ang
end


-- ZDEV_UID: ZDEV_FUNC_8060B92F | Path: ZDEV.UTIL.NoCollideWorld
function ZDEV.UTIL.NoCollideWorld( ply )

	if !IsValid(ply) or !ply:Alive() then return end

	local tr, ent, bone, const
	
	tr = ply:GetEyeTrace()

	if tr.Hit and tr.HitNonWorld and !tr.HitSky then
		
		ent = tr.Entity

		if !ent or !ent:IsValid() then return end

		bone = 0

		if ent:IsRagdoll() then
			bone = 1
		end
		
		debugoverlay.Box(ent:GetPos(),Vector(-8,-8,-8),Vector(8,8,8),3,Color(0,255,0,255) ) 
		constraint.NoCollide( game.GetWorld(), ent, 0, bone )

	end

	return const
end

ZDEV.CMDS.Register( "zdev_dev_nocollideworld", function( ply, cmd, arg )

	if !SERVER then return end
	ZDEV.UTIL.NoCollideWorld( ply )

end, { aliases = { "zd_nocollideworld" } } )

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- CLAUDE CODE 
-- GMod side: watch a command file, execute, write output back
timer.Create("zdev_bridge", 1, 0, function()
    if file.Exists("zdev/bridge_cmd.txt", "DATA") then
        local cmd = file.Read("zdev/bridge_cmd.txt", "DATA")
        file.Delete("zdev/bridge_cmd.txt")
        -- execute cmd, write result back
        file.Write("zdev/bridge_out.txt", tostring(RunString(cmd)))
    end
end)

ZDEV.FILE.SetLoaded( _f )