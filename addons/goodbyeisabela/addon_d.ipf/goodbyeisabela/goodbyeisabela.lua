--Addon name (upper case)
local addonName = "GOODBYEISABELA";
local addonNameUpper = string.upper(addonName);
local addonNameLower = string.lower(addonName);
--Author name
local author = "CHICORI";

--Create an area to use within the add-on. In the scope of the file below, you can access with the global variable G
_G["ADDONS"] = _G["ADDONS"] or {};
_G["ADDONS"][author] = _G["ADDONS"][author] or {};
_G["ADDONS"][author][addonNameUpper] = _G["ADDONS"][author][addonNameUpper] or {};
local g = _G["ADDONS"][author][addonNameUpper];

--Setting file save destination
g.settingsFileLoc = string.format("../addons/%s/settings.json", addonNameLower);

--Load library
local acutil = require('acutil');

--Default configuration
if not g.loaded then
	g.settings = {
	--Enable / Disablex
	automode = "off"
  };
end

--Message when loading lua

CHAT_SYSTEM(string.format("%s is loaded", addonName));
CHAT_SYSTEM(string.format("For futher help type /gbi"))

function GOODBYEISABELA_SAVE_SETTINGS()
	acutil.saveJSON(g.settingsFileLoc, g.settings);
end



function GOODBYEISABELA_ON_INIT(addon, frame)
	g.addon = addon;
	g.frame = frame;

	acutil.slashCommand("/"..addonNameLower, GOODBYEISABELA_PROCESS_COMMAND);
	acutil.slashCommand("/gbi", GOODBYEISABELA_PROCESS_COMMAND);

	if not g.loaded then
		local t, err = acutil.loadJSON(g.settingsFileLoc, g.settings);
		if err then
		 --Processing when setting file read failure
			CHAT_SYSTEM(string.format("[%s] cannot load settings", addonName));
			CHAT_SYSTEM(string.format("Default mode (OFF) activated."));
		else
		--Processing when setting file read success
			g.settings = t;
		end
		g.loaded = true;
	end

	--Setting file save processing
	GOODBYEISABELA_SAVE_SETTINGS();
	acutil.setupHook(BUY_BUFF_AUTOSELL_HOOKED, "BUY_BUFF_AUTOSELL");

end

function GOODBYEISABELA_PROCESS_COMMAND(command)
	local cmd = "";

	if #command > 0 then
		cmd = table.remove(command, 1);
	else
		--local msg = "on/off/self"
		local msg = "Configuration {nl} {nl} 1st mode: OFF (Default) {nl} {nl} You cant another buff while you have one active. {nl} You cant buy overpriced buffs (over 5000 silver) {nl} {nl} 2nd mode: ON {nl} {nl} Ask you if you want to cancel the active buff and buy a new one. {nl} Warn you when you are buying an overpriced buff. {nl} {nl} 3rd mode: SELF {nl} {nl} Offer you to cancel the active buff upon trying a new one. (But dont buy) {nl} Warn you when you are buying an overpriced buff. {nl} {nl} Example of usage: {nl} /gbi on {nl} /gbi off {nl} /gbi self"
		return ui.MsgBox(msg,"","Nope")
	end

	if cmd == "on" then
		--Effectiveness
		g.settings.automode = "on";
		CHAT_SYSTEM(string.format("[%s] automode on", addonName));
		GOODBYEISABELA_SAVE_SETTINGS();
		return;
	elseif cmd == "off" then
		--Invalid
		g.settings.automode = "off";
		CHAT_SYSTEM(string.format("[%s] automode off", addonName));
		GOODBYEISABELA_SAVE_SETTINGS();
		return;
	elseif cmd == "self" then
		--Invalid
		g.settings.automode = "self";
		CHAT_SYSTEM(string.format("[%s] automode self", addonName));
		GOODBYEISABELA_SAVE_SETTINGS();
		return;
	end
	CHAT_SYSTEM(string.format("[%s] Invalid Command", addonName));
end

function BUY_BUFF_AUTOSELL_HOOKED(ctrlSet, btn)

	local frame = ctrlSet:GetTopParentFrame();
	local sellType = frame:GetUserIValue("SELLTYPE");
	local groupName = frame:GetUserValue("GROUPNAME");
	local index = ctrlSet:GetUserIValue("INDEX");
	local itemInfo = session.autoSeller.GetByIndex(groupName, index);
	local buycount =  GET_CHILD(ctrlSet, "price");
	if itemInfo == nil then
		return;
	end

	local cnt = 1;
	if buycount ~= nil then
		cnt = buycount:GetNumber();
    end

	local totalPrice = itemInfo.price * cnt;
	local myMoney = GET_TOTAL_MONEY();
	if totalPrice > myMoney or  myMoney <= 0 then
		ui.SysMsg(ClMsg("NotEnoughMoney"));
		return;
	end

	local sklObj = GetClassByType("Skill", itemInfo.classID);
	local strscp = string.format( "EXEC_BUY_AUTOSELL(%d, %d, %d, %d)", frame:GetUserIValue("HANDLE"), index, cnt, sellType);


	local msg = "{nl} {nl}" .. ClMsg("ReallyBuy?")
	local skillPrice = GetCommaedText(itemInfo.price);
	local skillName  = sklObj.Name;
	local skillImage   = "{img icon_" .. sklObj["Icon"] .. " 60 60} ";
	local relationSkill = {
	[1] = {Name = "Sacrament";   buffID = 100; sklID = 40205; Lv=10};
	[2] = {Name = "Aspersium"; buffID = 146; sklID = 40201; Lv=15};
	[3] = {Name = "Blessing";   buffID = 147; sklID = 40203; Lv=15};
	};
	
	local skl_i		= 0;
	local tblMax    = table.maxn(relationSkill);

	--Price check
	if (itemInfo.price >= 5000) then
		skillPrice = "{#FF6347}{ol}[Price Check]{/}{/} It is " .. skillPrice;
	end
	if (itemInfo.price >= 5000) and (g.settings.automode == "off") then
		msg = "{nl} {nl}{#FF6347}{ol}This buff is overpriced.";
	elseif (itemInfo.price >= 5000) then
		msg = "{nl} {nl}{#FF6347}{ol}This buff is overpriced. {nl}Do you really want to buy it?{/}{/}{nl}";
	end
	--[[if (itemInfo.price >= 5000) and (g.settings.automode == "off") then
		skillPrice = "{#FF6347}{ol}[Price Check]{/}{/}" .. skillPrice;
		msg = "{nl} {nl} {nl} {nl}{#FF6347}{ol}This buff is overpriced.";
	elseif (itemInfo.price >= 5000) then
		skillPrice = "{#FF6347}{ol}[Price Check]{/}{/}" .. skillPrice;
		msg = "{nl} {nl} {nl} {nl}{#FF6347}{ol}This buff is overpriced. {nl} {nl}Do you really want to buy it?{/}{/}{nl} {nl} ";
	end]]--

	--Color change
	local skillLv = string.format(" Lv%s{nl} {nl}",itemInfo.level)

	if 9 >= itemInfo.level then
		skillLv = "{#FF6347}{ol}" .. skillLv .. "{/}{/}";
--	elseif itemInfo.level >=15 then
--		skillLv = "{#98FB98}{ol}" .. skillLv .. "{/}{/}";	
	end


	--Overwrite confirmation
	local handle = session.GetMyHandle();
	local buffCount = info.GetBuffCount(handle);

	for i = 0, buffCount - 1 do
		local buff = info.GetBuffIndexed(handle, i);
		for skl_i = 1, tblMax do
			if buff.buffID == relationSkill[skl_i].buffID then
				if sklObj.ClassID == relationSkill[skl_i].sklID then
					if g.settings.automode == "off" then
						ui.MsgBox(skillImage .. relationSkill[skl_i].Name .. "{nl} {nl} {nl}You already has this buff.")
						return;
					elseif g.settings.automode == "self" then
						local delSkl = string.format("RERIGHTMSG(%d, %d, %d, %d, %d)",buff.buffID, frame:GetUserIValue("HANDLE"), index, cnt, sellType);
						ui.MsgBox(skillImage .. relationSkill[skl_i].Name .. "{nl} {nl} {nl}You already has this buff.{nl} {nl}{#98FB98}{ol}Do you want to cancel the active buff?{/}{/}", delSkl, "None")
						return;
					elseif g.settings.automode == "on" then
						local delSkl = string.format("RERIGHTMSG(%d, %d, %d, %d, %d)",buff.buffID, frame:GetUserIValue("HANDLE"), index, cnt, sellType);
						if (itemInfo.price >= 5000) then
							ui.MsgBox(skillImage .. skillName .. skillLv .. " {nl} " ..  skillPrice .. " silver.{nl} {nl}{#98FB98}{ol}Cancel the active buff and buy a new one?{/}{/}", delSkl, "None")
						else
							ui.MsgBox(skillImage .. skillName .. skillLv .. "{nl} It is " ..  skillPrice .. " silver.{nl} {nl}{#98FB98}{ol}Cancel the active buff and buy a new one?{/}{/}", delSkl, "None")
						end
						return;
					end

				break;
				end
			end
		end
	end

	if (itemInfo.price >= 5000) or ((itemInfo.price >= 5000) and (g.settings.automode == "off")) then
		ui.MsgBox(skillImage .. skillName .. skillLv .. " {nl} " ..  skillPrice .. " silver.{nl}" ..msg);
	else
		ui.MsgBox(skillImage .. skillName .. skillLv .. " {nl} It is " ..  skillPrice .. " silver.{nl}" .. msg, strscp, "None");
	end

end

function RERIGHTMSG(buffID,hundle,index,cnt,sellType)
	packet.ReqRemoveBuff(buffID);
	
	-- It does not stabilize here even if delayed.
	if g.settings.automode == "on" then
		EXEC_BUY_AUTOSELL(hundle, index, cnt, sellType);
	end
end
