--Addon's name (upper case)
local addonName = "BUFFSHOPEX"
local addonNameLower = string.lower(addonName)
--Author name
local author = "CHICORI"

--Create an area to use within the add-on. In the scope of the file below, you can access with the global variable G
_G["ADDONS"] = _G["ADDONS"] or {}
_G["ADDONS"][author] = _G["ADDONS"][author] or {}
_G["ADDONS"][author][addonName] = _G["ADDONS"][author][addonName] or {}
local g = _G["ADDONS"][author][addonName]

--Setting file save destination
g.settingsFileLoc = string.format("../addons/%s/settings.json", addonNameLower)

--Load library
local acutil = require('acutil')

--Default configuration
if not g.loaded then
  g.settings = {
    enable = true,
	shop   = "",
	aspar  = 1000,
	bless  = 400,
	sacra  = 700
  }
end

--Message when loading lua
CHAT_SYSTEM(string.format("---------------------------------"))
CHAT_SYSTEM(string.format("%s.lua is loaded", addonName))
CHAT_SYSTEM(string.format(""))
CHAT_SYSTEM(string.format("Type /buffshop for futher help."))
CHAT_SYSTEM(string.format("---------------------------------"))

function BUFFSHOPEX_SAVE_SETTINGS()
	acutil.saveJSON(g.settingsFileLoc, g.settings)
end


--Map loading processing (one time only)
function BUFFSHOPEX_ON_INIT(addon, frame)
	g.addon = addon
	g.frame = frame

	acutil.slashCommand("/"..addonNameLower, BUFFSHOPEX_PROCESS_COMMAND)
	acutil.slashCommand("/buffshop", BUFFSHOPEX_PROCESS_COMMAND)

	if not g.loaded then
		local t, err = acutil.loadJSON(g.settingsFileLoc, g.settings)

		if err then
			--Processing when setting file read failure
			CHAT_SYSTEM(string.format("[%s] cannot load setting files", addonName))
		else
			--Processing when setting file read success
			g.settings = t
		end

		g.loaded = true
	end

	--Setting file save processing
	BUFFSHOPEX_SAVE_SETTINGS()

	--Message reception registration processing
	acutil.setupHook(BUFFSELLER_REG_OPEN_HOOKED, "BUFFSELLER_REG_OPEN")
end


--Chat command processing (when using acutil)）
function BUFFSHOPEX_PROCESS_COMMAND(command)
	local cmd = ""

	if #command > 0 then
		cmd = table.remove(command, 1)
	else
		local msg = "How to Configure {nl} {nl} /buffshop = Help Commands {nl} /buffshop nameEXAMPLE = Set the name as EXAMPLE; {nl} /buffshop aPRICE = Set Aspersium price; {nl} /buffshop bPRICE = Set Blessing price; {nl} /buffshop sPRICE = Set Sacrament price; {nl} {nl} Exemples: {nl} {nl} /buffshop a700 {nl} /buffshop nameBuy my Buffs! {nl} "
		return ui.MsgBox(msg,"","Nope")
	end

	if cmd == "on" then
		g.settings.enable = true
		CHAT_SYSTEM(string.format("[%s] is enable", addonName))
		BUFFSHOPEX_SAVE_SETTINGS()
		return
	elseif cmd == "off" then
		--Invalid
		g.settings.enable = false
		CHAT_SYSTEM(string.format("[%s] is disable", addonName))
		BUFFSHOPEX_SAVE_SETTINGS()
		return
	elseif string.sub(cmd,1,4) == "name" then
		g.settings.shop = string.sub(cmd,5)
		ui.MsgBox("Saving shop name {nl} {nl}" .. string.sub(cmd,5))
		BUFFSHOPEX_SAVE_SETTINGS()
		return

	--This place is suitable. Obsolete
	elseif string.sub(cmd,1,1) == "a" then
		local cmdPrice = tonumber(string.sub(cmd,2))
		local altMsg = "Save the Asperion with the following price."

		if 500 >= tonumber(cmdPrice) then
			altMsg = "The cost of Asperion is 500s.{nl}It will be below the cost. Will you save it anyway?"
		end

		local calcPrice = cmdPrice - 500
		local yesscp    = string.format("SKILLPRICE_SAVE(%q)",cmd)
		ui.MsgBox(altMsg .. "{nl} {nl}(Set amount:" .. cmdPrice .. "s / Difference:".. calcPrice .."s)",yesscp,"None")
		return

	elseif string.sub(cmd,1,1) == "b" then
		local cmdPrice = tonumber(string.sub(cmd,2))
		local altMsg   = "Save the Blessing at the following price."

		if 200 >= cmdPrice then
			altMsg = "The cost of Blessing is 200s.{nl}It will be below the cost. Will you save it anyway?"
		end

		local calcPrice = cmdPrice - 200
		local yesscp = string.format("SKILLPRICE_SAVE(%q)",cmd)
		ui.MsgBox(altMsg .. "{nl} {nl}(Set amount:" .. cmdPrice .. "s / Difference:".. calcPrice .."s)",yesscp,"None")
		return

	elseif string.sub(cmd,1,1) == "s" then
		local cmdPrice = tonumber(string.sub(cmd,2))
		local altMsg   = "Save the Sacrament at the following price."

		if 350 >= tonumber(cmdPrice) then
			altMsg = "The cost of Blessing is 350s.{nl}It will be below the cost. Will you save it anyway?"
		end

		local calcPrice = cmdPrice - 350
		local yesscp = string.format("SKILLPRICE_SAVE(%q)",cmd)
		ui.MsgBox(altMsg .. "{nl} {nl}(Set amount:" .. cmdPrice .. "s / Difference:".. calcPrice .."s)",yesscp,"None")
		return
	end

	CHAT_SYSTEM(string.format("[%s] Invalid Command", addonName))
end

function SKILLPRICE_SAVE(cmd)
	local cmdFlg   = string.sub(cmd,1,1)
	local cmdPrice = tonumber(string.sub(cmd,2))

		if cmdFlg == "a" then				--Aspersium
			g.settings.aspar = cmdPrice

		elseif cmdFlg == "b" then			--Blessing
			g.settings.bless = cmdPrice

		elseif cmdFlg == "s" then			--Sacrament
			g.settings.sacra = cmdPrice

		end

		BUFFSHOPEX_SAVE_SETTINGS()
end


function BUFFSELLER_REG_OPEN_HOOKED(frame)
	ui.OpenFrame("skilltree")

	local customSkill = frame:GetUserValue("CUSTOM_SKILL")
	if customSkill == "None" then
		frame:SetUserValue("GroupName", "BuffRegister")
		frame:SetUserValue("ServerGroupName", "Buff")
	else
		frame:SetUserValue("GroupName", customSkill)
		frame:SetUserValue("ServerGroupName", customSkill)
	end
	BUFFSELLER_UPDATE_LIST(frame)

-- From here, additional processing (original processing up to this point) ------------------------------


--Usability
	if g.settings.enable == false then return end


--Address
	local gBox     = GET_CHILD(frame, "gbox")
	local sellList = GET_CHILD(gBox, "selllist")
	local shopName = GET_CHILD(gBox, "inputname", "ui::CEditControl")
	shopName:SetText(g.settings.shop)


--Skill SET
	local relationSkill = {
		[1] = {name = "Aspersium"; sklID = 40201; price=g.settings.aspar};
		[2] = {name = "Blessing";   sklID = 40203; price=g.settings.bless};
		[3] = {name = "Sacrament";   sklID = 40205; price=g.settings.sacra};
	}
	for i, ver in ipairs(relationSkill) do
		local skillID = relationSkill[i].sklID
		local toFrame = frame:GetTopParentFrame()
		BUFFSELLER_REGISTER(toFrame, skillID)
	end


--Priced set (If you put it in the same loop as the skill set, it will not go out due to processing timing relationship.)
	for i, ver in ipairs(relationSkill) do
		local setPrice = relationSkill[i].price
		local ctrlSet  = GET_CHILD(sellList, "CTRLSET_" .. i - 1)
		local priceIn  = GET_CHILD(ctrlSet, "priceinput")
		tolua.cast(priceIn, 'ui::CEditControl');
		priceIn:SetText(setPrice)

		BUFFSELLER_TYPING_PRICE(ctrlSet, priceIn)
	end

end
