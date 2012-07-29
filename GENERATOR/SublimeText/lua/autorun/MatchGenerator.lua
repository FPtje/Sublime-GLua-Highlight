/*---------------------------------------------------------------------------
	/*---------------------------------------------------------------------------
	Generic part
	---------------------------------------------------------------------------*/
---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
Get the derma controls
Returns: match String
---------------------------------------------------------------------------*/
local function getDermaControls()
	local controls = {}
	for _, ctrl in pairs(derma.GetControlList()) do
		table.insert(controls, ctrl.ClassName)
	end

	return controls
end

/*---------------------------------------------------------------------------
Get all the libraries
---------------------------------------------------------------------------*/
local ignoreLibraries = {_G, _E, _R, GAMEMODE}
local function getLibraries()
	local libraries = {}

	for k,v in pairs(_E) do
		if type(v) ~= "table" or table.HasValue(ignoreLibraries, v) then continue end -- If it's not a table, then it's not a library by definition

		for name, value in pairs(v) do -- All libraries have functions. Some have other members
			if type(value) == "function" then
				libraries[k] = libraries[k] or {}
				table.insert(libraries[k], name)
			end
		end
	end

	return libraries
end

/*---------------------------------------------------------------------------
Get the global functions
---------------------------------------------------------------------------*/
local function getGlobalFunctions()
	local functions = {}
	for k,v in pairs(_E) do
		if type(v) == "function" then
			table.insert(functions, k)
		end
	end

	return functions
end

/*---------------------------------------------------------------------------
Get the enumerations, grouped by the text between their underscores (in a tree structure)
---------------------------------------------------------------------------*/
function getEnumerations()
	local enumerations = {}
	for k,v in SortedPairs(_E) do
		-- An enumeration is an uppercase variable with a number or boolean as value
		if string.upper(k) == k and (type(v) == "number" or type(v) == "boolean") then
			table.insert(enumerations, k)
		end
	end

	local grouped = {}

	-- The grouping part
	for k,v in SortedPairs(enumerations) do
		local parts = string.Explode("_", v)

		for num, part in pairs(parts) do
			local partTable = grouped -- Find the right table in the table tree to put it in (works in-depth)
			for i = 1, num, 1 do
				partTable[parts[i]] = partTable[parts[i]] or {}
				partTable = partTable[parts[i]]
			end
		end
	end

	return grouped
end

/*---------------------------------------------------------------------------
Metamethods
Gets the methods that can be called on any object, sorted by class.

NOTE: This doesn't get the hooks!
---------------------------------------------------------------------------*/
local function getMetaMethods()
	local objects = {} -- All the classes that exist, with their respective methods

	for k,v in pairs(_R) do
		-- All metamethods are in non-empty tables in _R. These tables always have a string as name
		if type(v) != "table" or type(k) ~= "string" then continue end

		for name, func in pairs(v) do
			if type(func) == "function" then
				objects[k] = objects[k] or {}
				table.insert(objects[k], name)
			end
		end
	end

	return objects
end

/*---------------------------------------------------------------------------
Hooks
---------------------------------------------------------------------------*/
local function hooksFromTable(tbl, othertable)
	local found = othertable or {} -- Build upon previously made table

	for k, v in pairs(tbl) do
		if type(v) ~= "table" and not table.HasValue(found, k) then
			table.insert(found, k)
		end
	end
	return found
end

local function getHooks()
	local hooks = {}

	hooks["SWEP"] = hooksFromTable(weapons.Get("weapon_base")) -- All the weapon hooks
	hooks["TOOL"] = hooksFromTable(weapons.Get("gmod_tool")) -- All the tool hooks
	hooks["GAMEMODE"] = hooksFromTable(GAMEMODE.BaseClass) -- All the gamemode hooks
	hooks["EFFECT"] = {"Init", "Think", "Render"} -- Effects. Hard coded until a method is found to generate them

	-- Entities
	hooks["ENT"] = hooksFromTable(scripted_ents.Get("base_anim"))
	hooks["ENT"] = hooksFromTable(scripted_ents.Get("base_ai"), hooks["ENT"])
	hooks["ENT"] = hooksFromTable(scripted_ents.Get("widget_base"), hooks["ENT"])
	//hooks["ENT"] = hooksFromTable(scripted_ents.Get("base_vehicle"), hooks["ENT"]) -- Gone in gmod 13?

	if SERVER then -- The server only entity types
		hooks["ENT"] = hooksFromTable(scripted_ents.Get("base_point"), hooks["ENT"])
		hooks["ENT"] = hooksFromTable(scripted_ents.Get("base_brush"), hooks["ENT"])
	end

	-- Panels.
	-- Hard coded until a method is found to generate them
	hooks["PANEL"] = {"ActionSignal", "ApplySchemeSettings", "DoClick", "Init", "OnCursorEntered", "OnCursorExited", "OnCursorMoved", "OnKeyCodePressed", "OnKeyCodeReleased", "OnKeyCodeTyped", "OnMousePressed", "OnMouseReleased", "OnMouseWheeled", "Paint", "PaintOver", "PerformLayout", "Think"}

	return hooks
end

/*---------------------------------------------------------------------------
	/*---------------------------------------------------------------------------
	Sublime text implementation

	Usage:
	sublime_generate_sv
	sublime_generate_cl
	sublime_finishgenerate
	---------------------------------------------------------------------------*/
---------------------------------------------------------------------------*/
require("glon")
/*---------------------------------------------------------------------------
generateXSideFiles
Generates the syntax files of syntax data for either server or clientside
The server- and clientside versions of the files will later be merged

side: string which side. sv for server, cl for client
---------------------------------------------------------------------------*/
local function generateXSideFiles()
	local side = SERVER and "sv" or "cl"

	file.Write("enums_"..side..".txt", glon.encode(getEnumerations()))
	file.Write("libraries_"..side..".txt", glon.encode(getLibraries()))
	file.Write("globalfunctions_"..side..".txt", glon.encode(getGlobalFunctions()))
	file.Write("metamethods_"..side..".txt", glon.encode(getMetaMethods()))
	file.Write("hooks_"..side..".txt", glon.encode(getHooks()))

	if CLIENT then
		file.Write("DermaControls_cl.txt", glon.encode(getDermaControls()))
	end
end
if SERVER then
	concommand.Add("sublime_generate_sv", generateXSideFiles)
else
	concommand.Add("sublime_generate_cl", generateXSideFiles)
end

/*---------------------------------------------------------------------------
readGlon
A helper function to properly read the file as a glon file.
---------------------------------------------------------------------------*/
local function readGlon( filename, path )
	if ( path == true ) then path = "GAME" end
	if ( path == nil || path == false ) then path = "DATA" end

	local f = file.Open( filename, "r", path )
	if ( !f ) then return end

	local result = f:Read( f:Size() )

	f:Close()

	return glon.decode(result)
end


/*---------------------------------------------------------------------------
Merge the server- and clientside files
---------------------------------------------------------------------------*/
local function MergeFiles()
	-- Merge a serverside and clientside file
	local function mergeSingle(filename)
		local sv = readGlon(filename.."_sv.txt")
		local cl = readGlon(filename.."_cl.txt")

		local shared = sv

		local function recursiveMerge(tbl1, tbl2) -- table.Merge doesn't do it properly
			for k,v in pairs(tbl2) do
				if type(v) ~= "table" and not table.HasValue(tbl1, v) then
					table.insert(tbl1, v)
				elseif type(v) == "table" and type(k) == "string" then
					tbl1[k] = recursiveMerge(tbl1[k] or {}, v)
				end
			end

			return tbl1
		end

		return recursiveMerge(shared, cl)
	end


	return {enums = mergeSingle("enums"),
		libraries = mergeSingle("libraries"),
		globalfunctions = mergeSingle("globalfunctions"),
		metamethods = mergeSingle("metamethods"),
		hooks = mergeSingle("hooks")}
end

/*---------------------------------------------------------------------------
Generates all the settings files for sublime.
Note: the ones you should use always start with sublime_. The other files are in-between products.
---------------------------------------------------------------------------*/
local function GenerateSublimeStrings()
	local merged = MergeFiles() -- First merge the files

	-- Convert enumerations table to sublime Text recognized string
	local function enumString(tbl)
		local enums = ""
		for k,v in pairs(tbl) do
			if table.Count(v) > 1 then
				enums = enums .. string.upper(k) .. "_(" .. enumString(v) .. ")|"
			elseif table.Count(v) > 0 then
				enums = enums .. string.upper(k) .. "(|_" .. enumString(v) .. ")|"
			else
				enums = enums .. string.upper(k) .. "|"
			end
		end

		return string.sub(enums, 1, -2)
	end

	file.Write("sublime_1enums.txt", "(?&lt;![^.]\\.|:)\\b("..enumString(merged.enums)..")\\b|(?&lt;![.])\\.{3}(?!\\.)")


	-- Libraries
	local strLibraries = "\\b("
	for name, lib in pairs(merged.libraries) do
		strLibraries = strLibraries .. name .. "\\.("
		for _, func in pairs(lib) do
			strLibraries = strLibraries .. func .. "|"
		end
		strLibraries = string.sub(strLibraries, 1, -2) .. ")|"
	end

	file.Write("sublime_2libraries.txt", string.sub(strLibraries, 1, -2) .. ")\\b")

	-- Global functions
	local strGlobalFuncs = "\\b("
	for k,v in pairs(merged.globalfunctions) do
		strGlobalFuncs = strGlobalFuncs .. v .. "|"
	end
	file.Write("sublime_3globalfunctions.txt", string.sub(strGlobalFuncs, 1, -2) .. ")\\b(?=[( {])")

	-- Meta methods
	local strMeta = "\\b("
	for k,v in pairs(merged.metamethods) do
		for a, b in pairs(v) do
			if not string.find(strMeta, "|"..b.."|", 1, true) then
				strMeta = strMeta .. b .. "|"
			end
		end
	end
	file.Write("sublime_4metafunctions.txt", string.sub(strMeta, 1, -2) .. ")\\b(?=[( {])")

	-- Hooks
	local strHooks = "("
	for k,v in pairs(merged.hooks) do
		if string.upper(k) == "GAMEMODE" then k = "(GAMEMODE|GM)" end -- Special case where GM has the same functions as GAMEMODE
		strHooks = strHooks .. "(("..string.upper(k).."|self)(\\.|:))("
		for _, func in pairs(v) do
			strHooks = strHooks .. func .. "|"
		end
		strHooks = string.sub(strHooks, 1, -2) .. ")|"
	end
	file.Write("sublime_5hooks.txt", string.sub(strHooks, 1, -2) .. ")\\b(?=[( {])")

	-- The derma controls and the package names
	local strPackages = "(?&lt;![^.]\\.|:)\\b("
	for k,v in pairs(readGlon("DermaControls_cl.txt")) do
		strPackages = strPackages .. v .. "|"
	end

	for k,v in pairs(merged.libraries) do
		strPackages = strPackages .. string.lower(k) .. "|"
	end
	file.Write("sublime_6packages.txt", string.sub(strPackages, 1, -2) .. ")\\b|(?&lt;![.])\\.{3}(?!\\.)")

	-- Auto completion
	local completions = file.Open("sublime-completions.txt", "w", "DATA")
	completions:Write(
	[[{
	"scope": "source.lua - keyword.control.lua - constant.language.lua - string",

	"completions":
	[
		"in", "else", "return", "false", "true", "break", "or", "and",
]])

	for k,v in pairs(merged.globalfunctions) do
		completions:Write('\t\t{ "trigger": "'.. v ..'", "contents": "'.. v ..'(${1})" },\n')
	end

	for k,v in pairs(merged.libraries) do
		for a, b in pairs(v) do
			completions:Write('\t\t{ "trigger": "'.. k ..'.'..b.. '", "contents": "'.. k ..'.'.. b ..'(${1})" },\n')
		end
	end

	for k,v in pairs(merged.hooks) do
		if string.upper(k) == "GAMEMODE" then
			for _, func in pairs(v) do
				completions:Write('\t\t{ "trigger": "'.. func .. '", "contents": "hook.Add(\\"'..func..'\\", ${1}, ${2})" },\n')
			end
		else
			for _, func in pairs(v) do
				completions:Write('\t\t{ "trigger": "'.. func .. '", "contents": "function '.. k ..':'.. func ..'(${1})\\n\\t${2}\\nend" },\n')
			end
		end
	end

	local doubleMethods = {} -- Some classes have the same methods. We want them to be in there only once
	for k,v in pairs(merged.metamethods) do
		for _, func in pairs(v) do
			if table.HasValue(doubleMethods, func) then continue end
			completions:Write('\t\t{ "trigger": ":'.. func ..'", "contents": ":'.. func ..'(${1})" },\n')
			table.insert(doubleMethods, func)
		end
	end


	completions:Write("\t\t{}\n\t]\n}")

	completions:Close()
end
concommand.Add("sublime_finishgenerate", GenerateSublimeStrings)
