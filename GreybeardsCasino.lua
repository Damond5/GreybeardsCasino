
local channelName = "GamblinGreybeards"
local AcceptOnes = "false";
local AcceptRolls = "false";
local totalrolls = 0
local tierolls = 0;
local theMax
local lowname = ""
local highname = ""
local low = 0
local high = 0
local tie = 0
local highbreak = 0;
local lowbreak = 0;
local tiehigh = 0;
local tielow = 0;
local whispermethod = false;
local totalentries = 0;
local highplayername = "";
local lowplayername = "";
local rollCmd = SLASH_RANDOM1:upper();
local debugLevel = 0;
local virag_debug = false
local chatmethods = {
	"RAID",
	"PARTY",
	"GUILD",
	"CHANNEL",
	"SAY"
}
local currentChatMethod = chatmethods[1];

-- LOAD FUNCTION --
function GBC_OnLoad(self)
	DEFAULT_CHAT_FRAME:AddMessage("|cffffff00<Greybeards Casino - WoW Classic!> loaded /cg to use");

	self:RegisterEvent("CHAT_MSG_RAID");
	self:RegisterEvent("CHAT_MSG_CHANNEL");
	self:RegisterEvent("CHAT_MSG_RAID_LEADER");
	self:RegisterEvent("CHAT_MSG_PARTY_LEADER");
	self:RegisterEvent("CHAT_MSG_PARTY");
	self:RegisterEvent("CHAT_MSG_GUILD");
	self:RegisterEvent("CHAT_MSG_SAY");
	self:RegisterEvent("CHAT_MSG_SYSTEM");
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterForDrag("LeftButton");
    
	GBC_ROLL_Button:Disable();
	GBC_AcceptOnes_Button:Enable();
	GBC_LASTCALL_Button:Disable();
	GBC_CHAT_Button:Enable();
end

local EventFrame=CreateFrame("Frame");
-- Need to register an event to receive it
EventFrame:RegisterEvent("CHAT_MSG_WHISPER");
EventFrame:SetScript("OnEvent", function(self,event,msg,sender)
	--We're making sure the command is case insensitive by casting it to lowercase before running a pattern check
    if msg:lower():find("!stats") then
        ChatMsg("Work in Progress","WHISPER",nil,sender);
    end
end);

local function Print(pre, red, text)
	if red == "" then red = "/CG" end
	DEFAULT_CHAT_FRAME:AddMessage(pre..GREEN_FONT_COLOR_CODE..red..FONT_COLOR_CODE_CLOSE..": "..text)
end

local function DebugMsg(level, text)
  if debugLevel < level then return end

  if level == 1 then
	level = " INFO: "
  elseif level == 2 then
	level = " DEBUG: "
  elseif level == 3 then
	  level = " ERROR: "
  end
  Print("","",GRAY_FONT_COLOR_CODE..date("%H:%M:%S")..RED_FONT_COLOR_CODE..level..FONT_COLOR_CODE_CLOSE..text)
end

local function ChatMsg(msg, chatType, language, channel)
	chatType = chatType or currentChatMethod
	channelnum = GetChannelName(channel or GBC["channel"] or channelName)
	SendChatMessage(msg, chatType, language, channelnum)
end

function hide_from_xml()
	GBC_SlashCmd("hide")
	GBC["active"] = 0;
end

function GBC_SlashCmd(msg)
	local msg = msg:lower();
	local msgPrint = 0;
	if (msg == "" or msg == nil) then
	    Print("", "", "~Following commands for GreybeardsCasino~");
		Print("", "", "show - Shows the frame");
		Print("", "", "hide - Hides the frame");
		Print("", "", "channel - Change the custom channel for gambling");
		Print("", "", "reset - Resets the AddOn");
		Print("", "", "fullstats - list full stats");
		Print("", "", "resetstats - Resets the stats");
		Print("", "", "joinstats [main] [alt] - Apply [alt]'s win/losses to [main]");
		Print("", "", "minimap - Toggle minimap show/hide");
		Print("", "", "unjoinstats [alt] - Unjoin [alt]'s win/losses from whomever it was joined to");
		Print("", "", "ban - Ban's the user from being able to roll");
		Print("", "", "unban - Unban's the user");
		Print("", "", "listban - Shows ban list");
		msgPrint = 1;
	end
	if (msg == "hide") then
		GBC_Frame:Hide();
		GBC["active"] = 0;
		msgPrint = 1;
	end
	if (msg == "show") then
		GBC_Frame:Show();
		GBC["active"] = 1;
		msgPrint = 1;
	end
	if (msg == "reset") then
		GBC_Reset();
		GBC_ResetCmd()
		msgPrint = 1;
	end
	if (msg == "fullstats") then
		GBC_OnClickSTATS(true)
		msgPrint = 1;
	end
	if (msg == "resetstats") then
		Print("", "", "|cffffff00GCG stats have now been reset");
		GBC_ResetStats();
		msgPrint = 1;
	end
	if (msg == "minimap") then
		Minimap_Toggle()
		msgPrint = 1;
	end
	if (string.sub(msg, 1, 7) == "channel") then
		GBC_ChangeChannel(strsub(msg, 9));
		msgPrint = 1;
	end
	if (string.sub(msg, 1, 9) == "joinstats") then
		GBC_JoinStats(strsub(msg, 11));
		msgPrint = 1;
	end
	if (string.sub(msg, 1, 11) == "unjoinstats") then
		GBC_UnjoinStats(strsub(msg, 13));
		msgPrint = 1;
	end

	if (string.sub(msg, 1, 3) == "ban") then
		GBC_AddBan(strsub(msg, 5));
		msgPrint = 1;
	end

	if (string.sub(msg, 1, 5) == "unban") then
		GBC_RemoveBan(strsub(msg, 7));
		msgPrint = 1;
	end

	if (string.sub(msg, 1, 7) == "listban") then
		GBC_ListBan();
		msgPrint = 1;
	end

	if (msgPrint == 0) then
		Print("", "", "|cffffff00Invalid argument for command /cg");
	end
end

SLASH_GBC1 = "/GreyCasino";
SLASH_GBC2 = "/GBC";
SlashCmdList["GBC"] = GBC_SlashCmd

function GBC_ParseChatMsg(arg1, arg2)
	if (arg1 == "1") then
		if(GBC_ChkBan(tostring(arg2)) == 0) then
			GBC_Add(tostring(arg2));
			if (not GBC_LASTCALL_Button:IsEnabled() and totalrolls == 1) then
				GBC_LASTCALL_Button:Enable();
			end
			if totalrolls == 2 then
				GBC_AcceptOnes_Button:Disable();
				GBC_AcceptOnes_Button:SetText("Open Entry");
			end
		else
			ChatMsg("Sorry, but you're banned from the game!");
		end

	elseif(arg1 == "-1") then
		GBC_Remove(tostring(arg2));
		if (GBC_LASTCALL_Button:IsEnabled() and totalrolls == 0) then
			GBC_LASTCALL_Button:Disable();
		end
		if totalrolls == 1 then
			GBC_AcceptOnes_Button:Enable();
			GBC_AcceptOnes_Button:SetText("Open Entry");
		end
	end
end

local function OptionsFormatter(text, prefix)
	if prefix == "" or prefix == nil then prefix = "/CG" end
	DEFAULT_CHAT_FRAME:AddMessage(string.format("%s%s%s: %s", GREEN_FONT_COLOR_CODE, prefix, FONT_COLOR_CODE_CLOSE, text))
end

--TODO scrap this
function debug(name, data)
	if not virag_debug then
		return false
	elseif not ViragDevTool_AddData and virag_debug then
	 	OptionsFormatter("VDT not enabled for debugging")
	 	return false
	elseif not data or not name then
		OptionsFormatter(string.format("Debug failed: data: %s, name: %s", data, name))
		return false
	end
	ViragDevTool_AddData(data, name)
end


function GBC_OnEvent(self, event, ...)
	-- LOADS ALL DATA FOR INITIALIZATION 
	if (event == "PLAYER_ENTERING_WORLD") then
		GBC_EditBox:SetJustifyH("CENTER");

		--TODO clean up this initialization garbage
		if(not GBC) then
			GBC = {
				["active"] = 0,
				["chat"] = 1,
				["channel"] = channelName,
				["whispers"] = false,
				["strings"] = { },
				["lowtie"] = { },
				["hightie"] = { },
				["bans"] = { },
				["minimap"] = true
			}
		-- fix older legacy items for new chat channels.  Probably need to iterate through each to see if it should be set.
		elseif tostring(type(GBC["chat"])) ~= "number" then
			GBC["chat"] = 1
		elseif GBC["minimap"] == nil then
			-- If the value is not true/false then set it to true to show initially.
			GBC["minimap"] = true
		end

		if(not GBC["lastroll"]) then 		GBC["lastroll"] 	= 100; end
		if(not GBC["stats"]) then 			GBC["stats"] 		= { }; end
		if(not GBC["joinstats"]) then 		GBC["joinstats"] 	= { }; end
		if(not GBC["chat"]) then 			GBC["chat"] 		= 1; end
		if(not GBC["channel"]) then 		GBC["channel"] 		= channelName; end
		if(not GBC["whispers"]) then 		GBC["whispers"] 	= false; end
		if(not GBC["bans"]) then 			GBC["bans"] 		= { }; end

		GBC_EditBox:SetText(""..GBC["lastroll"]);

		--SetChatTarget
		currentChatMethod = chatmethods[GBC["chat"]];
		GBC_CHAT_Button:SetText(string.format("Broadcast Gambling to: %s", currentChatMethod)); 

		-- show minimap
		if GBC["minimap"] then
			GBC_MinimapButton:Show()
		else
			GBC_MinimapButton:Hide()
		end

		whispermethod = GBC["whispers"]
		if whispermethod then
			GBC_WHISPER_Button:SetText("(Whispers)");
		end
		
		if(GBC["active"] == 1) then
			GBC_Frame:Show();
		else
			GBC_Frame:Hide();
		end
	end

	-- CHAT PARSING 
	if ((event == "CHAT_MSG_RAID_LEADER" or event == "CHAT_MSG_RAID") and AcceptOnes=="true" and GBC["chat"] == 1) then
		local msg, _,_,_,name = ... -- name no realm
		GBC_ParseChatMsg(msg, name)
	end

	if ((event == "CHAT_MSG_PARTY_LEADER" or event == "CHAT_MSG_PARTY")and AcceptOnes=="true" and GBC["chat"] == 2) then
		local msg, name = ... -- name no realm
		GBC_ParseChatMsg(msg, name)
	end

    if ((event == "CHAT_MSG_GUILD_LEADER" or event == "CHAT_MSG_GUILD")and AcceptOnes=="true" and GBC["chat"] == 3) then
		local msg, name = ... -- name no realm
		GBC_ParseChatMsg(msg, name)
	end
	
	if event == "CHAT_MSG_CHANNEL" and AcceptOnes=="true" and GBC["chat"] == 4 then
		local msg,_,_,_,name,_,_,_,channel = ...
		if channel == GBC["channel"] then
			GBC_ParseChatMsg(msg, name)
		end
	end

	if event == "CHAT_MSG_SAY" and AcceptOnes=="true" and GBC["chat"] == 5 then
		local msg, name = ... -- name no realm
		GBC_ParseChatMsg(msg, name)
	end

	if (event == "CHAT_MSG_SYSTEM" and AcceptRolls=="true") then
		local msg = ...
		GBC_ParseRoll(tostring(msg));
	end
end


function GBC_ResetStats()
	GBC["stats"] = { };
end

function Minimap_Toggle()
	if GBC["minimap"] then
		-- minimap is shown, set to false, and hide
		GBC["minimap"] = false
		GBC_MinimapButton:Hide()
	else
		-- minimap is now shown, set to true, and show
		GBC["minimap"] = true
		GBC_MinimapButton:Show()
	end
end

function GBC_OnClickCHAT()
	--TODO cleanup
	if(GBC["chat"] == nil) then GBC["chat"] = 1; end

	GBC["chat"] = (GBC["chat"] % #chatmethods) + 1;

	--TODO SetChatTarget
	currentChatMethod = chatmethods[GBC["chat"]];
	GBC_CHAT_Button:SetText(string.format("Broadcast Gambling to: %s", currentChatMethod));
end

function GBC_OnClickWHISPERS()
	if(GBC["whispers"] == nil) then GBC["whispers"] = false; end

	GBC["whispers"] = not GBC["whispers"];

	if(GBC["whispers"] == false) then
		GBC_WHISPER_Button:SetText("(No Whispers)");
		whispermethod = false;
	else
		GBC_WHISPER_Button:SetText("(Whispers)");
		whispermethod = true;
	end
end

function GBC_ChangeChannel(channel)
	GBC["channel"] = channel
end

function GBC_JoinStats(msg)
	local i = string.find(msg, " ");
	if((not i) or i == -1 or string.find(msg, "[", 1, true) or string.find(msg, "]", 1, true)) then
		ChatFrame1:AddMessage("");
		return;
	end

	local mainname = string.sub(msg, 1, i-1);
	local altname = string.sub(msg, i+1);

	ChatFrame1:AddMessage(string.format("Joined alt '%s' -> main '%s'", altname, mainname));
	GBC["joinstats"][altname] = mainname;
end

function GBC_UnjoinStats(altname)
	if(altname ~= nil and altname ~= "") then
		ChatFrame1:AddMessage(string.format("Unjoined alt '%s' from any other characters", altname));
		GBC["joinstats"][altname] = nil;
	else
		local i, e;
		for i, e in pairs(GBC["joinstats"]) do
			ChatFrame1:AddMessage(string.format("currently joined: alt '%s' -> main '%s'", i, e));
		end
	end
end

function GBC_OnClickSTATS(full)
	local sortlistname = {};
	local sortlistamount = {};
	local n = 0;
	local i, j, k;

	for name, totalWon in pairs(GBC["stats"]) do
		if(GBC["joinstats"][strlower(name)] ~= nil) then
			name = GBC["joinstats"][strlower(name)]:gsub("^%l", string.upper);
		end
		for k=0,n do
			if(k == n) then
				sortlistname[n] = name;
				sortlistamount[n] = totalWon;
				n = n + 1;
				break;
			elseif(strlower(name) == strlower(sortlistname[k])) then
				sortlistamount[k] = (sortlistamount[k] or 0) + totalWon;
				break;
			end
		end
	end

	if(n == 0) then
		DEFAULT_CHAT_FRAME:AddMessage("No stats yet!");
		return;
	end

	for i = 0, n-1 do
		for j = i+1, n-1 do
			if(sortlistamount[j] > sortlistamount[i]) then
				sortlistamount[i], sortlistamount[j] = sortlistamount[j], sortlistamount[i];
				sortlistname[i], sortlistname[j] = sortlistname[j], sortlistname[i];
			end
		end
	end

	DEFAULT_CHAT_FRAME:AddMessage("--- Greybeards Casino Stats ---", currentChatMethod);

	if full then
		for k = 0,  #sortlistamount do
			local sortsign = "won";
			if(sortlistamount[k] < 0) then sortsign = "lost"; end
			ChatMsg(string.format("%d.  %s %s %d total", k+1, sortlistname[k], sortsign, math.abs(sortlistamount[k])), currentChatMethod);
		end
		return
	end

	local top = 2;
	local bottom = n-3;

	if(top >= n) then top = n-1; end
	if(bottom <= top) then bottom = top+1; end

	for topIdx = 0, top do
		sortsign = "won";
		if(sortlistamount[topIdx] < 0) then sortsign = "lost"; end
		ChatMsg(string.format("%d.  %s %s %d total", topIdx+1, sortlistname[topIdx], sortsign, GBC_RollToGold(math.abs(sortlistamount[topIdx]))), currentChatMethod);
	end

	if(top+1 < bottom) then
		ChatMsg("...", currentChatMethod);
	end

	for btmIdx = bottom, n-1 do
		sortsign = "won";
		if(sortlistamount[btmIdx] < 0) then sortsign = "lost"; end
		ChatMsg(string.format("%d.  %s %s %d total", btmIdx+1, sortlistname[btmIdx], sortsign, GBC_RollToGold(math.abs(sortlistamount[btmIdx]))), currentChatMethod);
	end
end

function GBC_OnClickROLL()
	if (totalrolls > 0 and AcceptRolls == "true") then
		if table.getn(GBC.strings) ~= 0 then
			GBC_List();
		end
		return;
	end
	if (totalrolls >1) then
		AcceptOnes = "false";
		AcceptRolls = "true";
		if (tie == 0) then
			ChatMsg("Roll now!");
		end

		if (lowbreak == 1) then
			ChatMsg(format("%s%d%s", "Low end tiebreaker! Roll 1-", theMax, " now!"));
			GBC_List();
		end

		if (highbreak == 1) then
			ChatMsg(format("%s%d%s", "High end tiebreaker! Roll 1-", theMax, " now!"));
			GBC_List();
		end

		GBC_EditBox:ClearFocus();

	end

	if (AcceptOnes == "true" and totalrolls <2) then
		ChatMsg("Not enough Players!");
	end
end

function GBC_OnClickLASTCALL()
	ChatMsg("Last Call to join!");
	GBC_EditBox:ClearFocus();
	GBC_LASTCALL_Button:Disable();
	GBC_ROLL_Button:Enable();
end

function GBC_OnClickACCEPTONES()
	if GBC_EditBox:GetText() ~= "" and GBC_EditBox:GetText() ~= "1" then
		GBC_Reset()
		GBC_ROLL_Button:Disable()
		GBC_LASTCALL_Button:Disable()
		AcceptOnes = "true"
		local fakeroll = ""
		theMax = tonumber(GBC_EditBox:GetText())
		ChatMsg(format(".:The Greybeard$ Casino:. STAKES << %s >>", GBC_RollToGold(theMax)))
		ChatMsg(format(".:Players will  /roll %s  // Type 1 to Join  // Type -1 to withdraw:.", GBC_EditBox:GetText()))
        GBC["lastroll"] = GBC_EditBox:GetText()
		low = theMax + 1
		tielow = theMax + 1
		GBC_EditBox:ClearFocus()
		GBC_AcceptOnes_Button:SetText("New Game")
		GBC_LASTCALL_Button:Disable()
		GBC_EditBox:ClearFocus()
	else
		message("Please enter a number to roll from.", chatmethod)
	end
end

function GBC_OnClickRoll()
hash_SlashCmdList[rollCmd](GBC_EditBox:GetText())
end

function GBC_OnClickRoll1()
	ChatMsg("1");
end

CG_Settings = {
	MinimapPos = 75
}

-- ** do not call from the mod's OnLoad, VARIABLES_LOADED or later is fine. **
function CG_MinimapButton_Reposition()
	CG_MinimapButton:SetPoint(
		"TOPLEFT",
		"Minimap",
		"TOPLEFT",
		52-(80*cos(CG_Settings.MinimapPos)),
		(80*sin(CG_Settings.MinimapPos))-52)
end


function CG_MinimapButton_DraggingFrame_OnUpdate()
	local xpos,ypos = GetCursorPosition()
	local xmin,ymin = Minimap:GetLeft(), Minimap:GetBottom()

	xpos = xmin-xpos/UIParent:GetScale()+70
	ypos = ypos/UIParent:GetScale()-ymin-70

	CG_Settings.MinimapPos = math.deg(math.atan2(ypos,xpos))
	CG_MinimapButton_Reposition()
end


function CG_MinimapButton_OnClick()
	DEFAULT_CHAT_FRAME:AddMessage(tostring(arg1).." was clicked.")
end

function GBC_Report()
	local goldowed = high - low
	if (goldowed ~= 0) then
		lowname = lowname:gsub("^%l", string.upper)
		highname = highname:gsub("^%l", string.upper)
		local string3 = format("%s owes %s < %d >", lowname, highname, GBC_RollToGold(goldowd))

		if highname == "Louch" then
			string3 = format("%s - %s", string3, "Thanks for further enabling Louch's gambling addiction.")
		elseif lowname == "Louch" then
			string3 = format("%s - %s", string3, "Alternatively, Louch has good mage water available to trade.")
		end
		
		GBC["stats"][highname] = (GBC["stats"][highname] or 0) + goldowed;
		GBC["stats"][lowname] = (GBC["stats"][lowname] or 0) - goldowed;

		ChatMsg(string3);
	else
		ChatMsg("It was a tie! No payouts on this roll!");
	end
	GBC_Reset();
	GBC_AcceptOnes_Button:SetText("Open Entry");
	GBC_CHAT_Button:Enable();
end

function GBC_Tiebreaker()
	tierolls = 0;
	totalrolls = 0;
	tie = 1;
	if table.getn(GBC.lowtie) == 1 then
		GBC.lowtie = {};
	end
	if table.getn(GBC.hightie) == 1 then
		GBC.hightie = {};
	end
	totalrolls = table.getn(GBC.lowtie) + table.getn(GBC.hightie);
	tierolls = totalrolls;
	if (table.getn(GBC.hightie) == 0 and table.getn(GBC.lowtie) == 0) then
		GBC_Report();
	else
		AcceptRolls = "false";
		if table.getn(GBC.lowtie) > 0 then
			lowbreak = 1;
			highbreak = 0;
			tielow = theMax+1;
			tiehigh = 0;
			GBC.strings = GBC.lowtie;
			GBC.lowtie = {};
			GBC_OnClickROLL();
		end
		if table.getn(GBC.hightie) > 0  and table.getn(GBC.strings) == 0 then
			lowbreak = 0;
			highbreak = 1;
			tielow = theMax+1;
			tiehigh = 0;
			GBC.strings = GBC.hightie;
			GBC.hightie = {};
			GBC_OnClickROLL();
		end
	end
end

function GBC_ParseRoll(temp2)
	local temp1 = strlower(temp2);

	local player, junk, roll, range = strsplit(" ", temp1);

	if junk == "rolls" and GBC_Check(player)==1 then
		minRoll, maxRoll = strsplit("-",range);
		minRoll = tonumber(strsub(minRoll,2));
		maxRoll = tonumber(strsub(maxRoll,1,-2));
		roll = tonumber(roll);
		if (maxRoll == theMax and minRoll == 1) then
			if (tie == 0) then
				if (roll == high) then
					if table.getn(GBC.hightie) == 0 then
						GBC_AddTie(highname, GBC.hightie);
					end
					GBC_AddTie(player, GBC.hightie);
				end
				if (roll>high) then
					highname = player
					highplayername = player
					if (high == 0) then
						high = roll
						if (whispermethod) then
							ChatMsg(string.format("You have the HIGHEST roll so far: %s and you might win a max of %sg", roll, (high - 1)),"WHISPER",GetDefaultLanguage("player"),player);
						end
					else
						high = roll
						if (whispermethod) then
							ChatMsg(string.format("You have the HIGHEST roll so far: %s and you might win %sg from %s", roll, (high - low), lowplayername),"WHISPER",GetDefaultLanguage("player"),player);
							ChatMsg(string.format("%s now has the HIGHEST roller so far: %s and you might owe him/her %sg", player, roll, (high - low)),"WHISPER",GetDefaultLanguage("player"),lowplayername);
						end
					end
					GBC.hightie = {};

				end
				if (roll == low) then
					if table.getn(GBC.lowtie) == 0 then
						GBC_AddTie(lowname, GBC.lowtie);
					end
					GBC_AddTie(player, GBC.lowtie);
				end
				if (roll<low) then
					lowname = player
					lowplayername = player
					low = roll
					if (high ~= low) then
						if (whispermethod) then
							ChatMsg(string.format("You have the LOWEST roll so far: %s and you might owe %s %sg ", roll, highplayername, (high - low)),"WHISPER",GetDefaultLanguage("player"),player);
						end
					end
					GBC.lowtie = {};

				end
			else
				if (lowbreak == 1) then
					if (roll == tielow) then

						if table.getn(GBC.lowtie) == 0 then
							GBC_AddTie(lowname, GBC.lowtie);
						end
						GBC_AddTie(player, GBC.lowtie);
					end
					if (roll < tielow) then
						lowname = player
						tielow = roll;
						GBC.lowtie = {};

					end
				end
				if (highbreak == 1) then
					if (roll == tiehigh) then
						if table.getn(GBC.hightie) == 0 then
							GBC_AddTie(highname, GBC.hightie);
						end
						GBC_AddTie(player, GBC.hightie);
					end
					if (roll>tiehigh) then
						highname = player
						tiehigh = roll;
						GBC.hightie = {};

					end
				end
			end
			GBC_Remove(tostring(player));
			totalentries = totalentries + 1;

			if table.getn(GBC.strings) == 0 then
				if tierolls == 0 then
					GBC_Report();
				else
					if totalentries == 2 then
						GBC_Report();
					else
						GBC_Tiebreaker();
					end
				end
			end
		end
	end
end

function GBC_Check(player)
	for i=1, table.getn(GBC.strings) do
		if strlower(GBC.strings[i]) == tostring(player) then
			return 1
		end
	end
	return 0
end

function GBC_List()
	for i=1, table.getn(GBC.strings) do
	  	local string3 = strjoin(" ", "", tostring(GBC.strings[i]):gsub("^%l", string.upper),"still needs to roll.")
		ChatMsg(string3);
	end
end

function GBC_ListBan()
	local bancnt = 0;
	Print("", "", "|cffffff00To ban do /cg ban (Name) or to unban /cg unban (Name) - The Current Bans:");
	for i=1, table.getn(GBC.bans) do
		bancnt = 1;
		DEFAULT_CHAT_FRAME:AddMessage(strjoin("|cffffff00", "...", tostring(GBC.bans[i])));
	end
	if (bancnt == 0) then
		DEFAULT_CHAT_FRAME:AddMessage("|cffffff00To ban do /cg ban (Name) or to unban /cg unban (Name).");
	end
end

function GBC_Add(name)
	local charname, realmname = strsplit("-",name);
	local insname = strlower(charname);
	if (insname ~= nil or insname ~= "") then
		local found = 0;
		for i=1, table.getn(GBC.strings) do
		  	if GBC.strings[i] == insname then
				found = 1;
			end
        	end
		if found == 0 then
		      	table.insert(GBC.strings, insname)
			totalrolls = totalrolls+1
		end
	end
end

function GBC_ChkBan(name)
	local charname, realmname = strsplit("-",name);
	local insname = strlower(charname);
	if (insname ~= nil or insname ~= "") then
		for i=1, table.getn(GBC.bans) do
			if strlower(GBC.bans[i]) == strlower(insname) then
				return 1
			end
		end
	end
	return 0
end

function GBC_AddBan(name)
	local charname, realmname = strsplit("-",name);
	local insname = strlower(charname);
	if (insname ~= nil or insname ~= "") then
		local banexist = 0;
		for i=1, table.getn(GBC.bans) do
			if GBC.bans[i] == insname then
				Print("", "", "|cffffff00Unable to add to ban list - user already banned.");
				banexist = 1;
			end
		end
		if (banexist == 0) then
			table.insert(GBC.bans, insname)
			Print("", "", "|cffffff00User is now banned!");
			local banMsg = strjoin(" ", "", "User Banned from rolling! -> ",insname, "!")
			DEFAULT_CHAT_FRAME:AddMessage(strjoin("|cffffff00", banMsg));
		end
	else
		Print("", "", "|cffffff00Error: No name provided.");
	end
end

function GBC_RemoveBan(name)
	local charname, realmname = strsplit("-",name);
	local insname = strlower(charname);
	if (insname ~= nil or insname ~= "") then
		for i=1, table.getn(GBC.bans) do
			if strlower(GBC.bans[i]) == strlower(insname) then
				table.remove(GBC.bans, i)
				Print("", "", "|cffffff00User removed from ban successfully.");
				return;
			end
		end
	else
		Print("", "", "|cffffff00Error: No name provided.");
	end
end

function GBC_AddTie(name, tietable)
	local charname, realmname = strsplit("-",name);
	local insname = strlower(charname);
	if (insname ~= nil or insname ~= "") then
		local found = 0;
		for i=1, table.getn(tietable) do
		  	if tietable[i] == insname then
				found = 1;
			end
        	end
		if found == 0 then
		    table.insert(tietable, insname)
			tierolls = tierolls+1
			totalrolls = totalrolls+1
		end
	end
end

function GBC_Remove(name)
	local charname, realmname = strsplit("-",name);
	local insname = strlower(charname);
	for i=1, table.getn(GBC.strings) do
		if GBC.strings[i] ~= nil then
		  	if strlower(GBC.strings[i]) == strlower(insname) then
				table.remove(GBC.strings, i)
				totalrolls = totalrolls - 1;
			end
		end
      end
end

function GBC_RemoveTie(name, tietable)
	local charname, realmname = strsplit("-",name);
	local insname = strlower(charname);
	for i=1, table.getn(tietable) do
		if tietable[i] ~= nil then
		  	if strlower(tietable[i]) == insname then
				table.remove(tietable, i)
			end
		end
      end
end

function GBC_Reset()
	GBC["strings"] = { };
	GBC["lowtie"] = { };
	GBC["hightie"] = { };
	AcceptOnes = "false"
	AcceptRolls = "false"
	totalrolls = 0
	theMax = 0
	tierolls = 0;
	lowname = ""
	highname = ""
	low = theMax
	high = 0
	tie = 0
	highbreak = 0;
	lowbreak = 0;
	tiehigh = 0;
	tielow = 0;
	totalentries = 0;
	highplayername = "";
	lowplayername = "";
	GBC_ROLL_Button:Disable();
	GBC_AcceptOnes_Button:Enable();
	GBC_LASTCALL_Button:Disable();
	GBC_CHAT_Button:Enable();
	GBC_AcceptOnes_Button:SetText("Open Entry");
	Print("", "", "|cffffff00GCG has now been reset");
end

function GBC_ResetCmd()
	ChatMsg(".:GBC:. Game has been reset", chatmethod)
end

function GBC_EditBox_OnLoad()
    GBC_EditBox:SetNumeric(true);
	GBC_EditBox:SetAutoFocus(false);
end

function GBC_EditBox_OnEnterPressed()
    GBC_EditBox:ClearFocus();
end

function GBC_RollToGold(value)
	local tempValue = tonumber(value)
	silver = tempValue % 100
	tempValue = math.floor(tempValue / 100)
	tempValue = string.format("%sg", tempValue)
	
	if silver > 0 then
		tempValue = string.format("%s %ds", tempValue, silver)
	end
	
	return tempValue
end
