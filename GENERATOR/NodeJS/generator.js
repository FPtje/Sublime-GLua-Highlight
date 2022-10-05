const fs = require("fs")

// Use https://www.npmjs.com/package/gmod-wiki-scraper from cmd in the same directory

const classes = require("./output/classes.json")
const enums = require("./output/enums.json")
const globals = require("./output/global-functions.json")
const hooks = require("./output/hooks.json")
const libraries = require("./output/libraries.json")
const panels = require("./output/panels.json")

const output = {
	"scope": "source.lua - keyword.control.lua - constant.language.lua - string",
	"completions": []
};

const kw = ["and", "break", "do", "elseif", "else", "end", "false", "for", "function", "goto", "if", "in", "local", "nil", "not", "or", "repeat", "return", "then", "true", "until", "while"];

kw.forEach(k => {
	output.completions.push({
		trigger: k,
		contents: k,
		kind: "keyword"
	})
})

const gw = ["derma.Controls", "derma.SkinList", "jit.arch", "jit.os", "jit.version", "jit.version_num", "net.Receivers", "utf8.charpattern", "_VERSION", "CLIENT", "CLIENT_DLL", "SERVER", "GAME_DLL", "MENU_DLL", "GAMEMODE_NAME", "NULL", "VERSION", "VERSIONSTR", "BRANCH", "GAMEMODE", "GM", "ENT", "SWEP", "EFFECT", "_G", "_MODULES"];

gw.forEach(k => {
	output.completions.push({
		trigger: k,
		contents: k,
		kind: ["namespace", "G", "Global Variable"]
	})
})

const gwv = [
	["vector_origin", "Vector(0, 0, 0)"],
	["vector_up", "Vector(0, 0, 1)"],
	["angle_zero", "Angle(0, 0, 0)"],
	["color_white", "Color(255, 255, 255, 255)"],
	["color_black", "Color(0, 0, 0, 255)"],
	["color_transparent", "Color(255, 255, 255, 0)"],
	["math.huge", "∞"],
	["math.pi", "π"],
]

gwv.forEach(k => {
	output.completions.push({
		trigger: k[0],
		contents: k[0],
		kind: ["namespace", "G", "Global Variable"],
		details: k[0] + " = " + k[1]
	})
})

rName = {
	1: "Client",
	2: "Server",
	3: "Shared",
	4: "Menu",
	5: "Shared",
	7: "SharedMenu",
}

function realm(t) {
	let realmNum = 0;
	console.log(t == ["client"]);
	if (t.includes("client")) {
		realmNum += 1
	}
	if (t.includes("server")) {
		realmNum += 2
	}
	if (t.includes("menu")) {
		realmNum += 4
	}
	return rName[realmNum]
}

function arguments(args) {
	if (!args) return "()";

	let i = 1;
	let output = "("
	args.forEach(arg => {
		output += "${" + i + ":" + arg.type + " " + arg.name + (arg.default ? " = " + arg.default : "") + "}, ";
		i++;
	})

	return output.slice(0, -2) + ")"
}

globals.forEach((func) => {
	console.log(func.name, func.realms)
	output.completions.push({
		trigger: func.name,
		contents: func.name + arguments(func.arguments),
		annotation: realm(func.realms),
		kind : ["function", "f", "Global"],
		details: func.name + "(" + (func.arguments ? func.arguments.map(a => a.name).join(", ") : "") + ")"
	})
})

classes.forEach((category) => {
	console.log(category.name)
	category.functions.forEach((func) => {
		output.completions.push({
			trigger: func.name,
			contents: func.name + arguments(func.arguments),
			annotation: realm(func.realms),
			kind : ["function", "c", "Class"],
			details: category.name + ":" + func.name + "(" + (func.arguments ? func.arguments.map(a => a.name).join(", ") : "") + ")"
		})
	})
})

const blacklist = {
	"math.huge": true,
	"math.pi": true
}

libraries.forEach((category) => {
	console.log(category.name)
	category.functions.forEach((func) => {
		const funcNameC = category.name + "." + func.name;
		if (blacklist[funcNameC]) return;
		output.completions.push({
			trigger: funcNameC,
			contents: funcNameC + arguments(func.arguments),
			annotation: realm(func.realms),
			kind : ["function", "f", "Function"],
			details: funcNameC + "(" + (func.arguments ? func.arguments.map(a => a.name).join(", ") : "") + ")"
		})
	})
})

hooks.forEach((category) => {
	console.log(category.name)
	category.functions.forEach((func) => {
		output.completions.push({
			trigger: func.name,
			contents: func.name,
			annotation: realm(func.realms),
			kind : ["snippet", "H", "Hook"],
			details: category.name + ":" + func.name + "(" + (func.arguments ? func.arguments.map(a => a.name).join(", ") : "") + ")"
		})
	})
})

panels.forEach((category) => {
	output.completions.push({
		trigger: category.name,
		contents: category.name,
		annotation: "Panel",
		kind : ["navigation", "P", "Panel"],
		details: "vgui.Create(\""+ category.name + "\")"
	})

	if (!category.functions) return;

	category.functions.forEach((func) => {
		output.completions.push({
			trigger: func.name,
			contents: func.name + arguments(func.arguments),
			annotation: realm(func.realms),
			kind : ["markup", "m", "Panel Method"],
			details: category.name + ":" + func.name + "(" + (func.arguments ? func.arguments.map(a => a.name).join(", ") : "") + ")"
		})
	})
})

enums.forEach((category) => {
	console.log(category.name)
	category.fields.forEach((field) => {
		output.completions.push({
			trigger: field.name,
			contents: field.name,
			annotation: realm(category.realms),
			kind : ["variable", "E", "Enum"],
			details: field.name + " = " + field.value
		})
	})
})

const data = JSON.stringify(output, null, 2);
fs.writeFileSync("output.json", data);