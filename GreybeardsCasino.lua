--Greybeards Casino
--Author: Looch

local g_app = {
	showing = true,
	customChannel = "GreybeardsCasino",
	chatEnterMsg = "1",
	chatWithdrawMsg = "-1",
	chatMethods = {
		"SAY",
		"RAID",
		"PARTY",
		"GUILD",
		"CHANNEL",
	},
	currentChatMethod = "SAY",
	savedStakes = 100,
	showMinimap = false,
	acceptedEntriesFrame = nil,
	debug = true,
	sessionStats = {},
	minimapPosition = 75
}

local g_roundDefaults = {
	currentPhase = 0,
	maxPhases = 3,
	entrants = {},
	acceptEntries = false,
	acceptRolls = false,
	totalRolls = 0,
	totalEntries = 0,
	tierolls = 0,
	currentStakes = 0,
	currentHighRoll = 0, 
	currentLowRoll = 0,
	currentTie = 0, 
	lowName = "",
	highName = "",
	currentHighBreak = 0, --TODO don't need a global
	currentLowBreak = 0, --TODO don't need a global
	tiehigh = 0, --TODO redundant. just use currentMax
	tielow = 0, --TODO redundant. just use currentLow
}

local g_round = g_roundDefaults

--g_rollCmd = SLASH_RANDOM1:upper()

local function ConvertRollToGold(value)
	local tempValue = tonumber(value)
	silver = tempValue % 100
	tempValue = math.floor(tempValue / 100)
	tempValue = string.format("%sg", tempValue)
	
	if silver > 0 then
		tempValue = string.format("%s %ds", tempValue, silver)
	end
	
	return tempValue
end

local function ResetRound()
	g_round = g_roundDefaults
	g_round.currentPhase = 0
	g_round.entrants = {}

	--GBC["strings"] = { }; --TODO ???
	GBC["lowtie"] = { }; --TODO remove
	GBC["hightie"] = { }; --TODO remove
	
	ResetGBCFrames()

	WriteMsg("", "", "|cffffff00GCG has now been reset");
end

local function StartRound()

	--Grab current stakes before resetting round defaults
	g_app.savedStakes = GBC_EditBox_Stakes:GetText()
	GBC_EditBox_Stakes:ClearFocus()

	ResetRound()

	g_round.acceptEntries = true
	g_round.currentStakes = tonumber(g_app.savedStakes) 
	g_round.currentLowRoll = g_round.currentStakes + 1
	g_round.tielow = g_round.currentStakes + 1

	ChatMsg(format(".:The Greybeards Casino:. STAKES << %s >>", ConvertRollToGold(g_round.currentStakes)))
	ChatMsg(".:Hi/Lo:. Lowest roller pays Highest roller the difference between rolls:.")
	ChatMsg(format(".:Players will  /roll %s  .:. Type %s to Join  .:. Type %s to withdraw:.", 
					g_round.currentStakes, 
					g_app.chatEnterMsg, 
					g_app.chatWithdrawMsg))

	GBC_Btn_RoundNext:SetText("Announce Last Call")
end

local function AnnounceLastCall()
	ChatMsg("Last Call to join!");
	GBC_Btn_RoundNext:SetText("Begin Rolling")
end

local function AnnounceRolling()
	DebugWrite(string.format("Beginning Roll Phase w/ <%d> entries", g_round.totalRolls))
	--if g_round.totalRolls > 0 and g_round.acceptRolls then
	--	if table.getn(GBC.strings) ~= 0 then
	--		ListRemainingPlayers()
	--	end
	--	return
	--end

	if g_round.totalRolls > 1 or (g_app.debug and g_round.totalRolls > 0) then
		g_round.acceptEntries = false 
		g_round.acceptRolls = true 
		if (g_round.currentTie == 0) then 
			ChatMsg(format(".:Greybeards Casino - /roll %s NOW:.", g_round.currentStakes))
		end

		if (g_round.currentLowBreak == 1) then
			ChatMsg(format("%s%d%s", "Low end tiebreaker! Roll 1-", g_round.currentStakes, " now!"))
			ListRemainingPlayers()
		end

		if (g_round.currentHighBreak == 1) then
			ChatMsg(format("%s%d%s", "High end tiebreaker! Roll 1-", g_round.currentStakes, " now!"));
			ListRemainingPlayers();
		end

		--GBC_EditBox:ClearFocus();
	end

	if g_round.acceptEntries and g_round.totalRolls < 2 and not g_app.debug then
		ChatMsg("Not enough Players!")
	end

	GBC_Btn_RoundNext:Disable()
	GBC_Btn_RoundNext:SetText("Waiting for rolls")
end

function RoundWrapup()
	if #g_round.highTyers <= 1 and #g_round.lowTyers <= 1 then
		ReportResults()
		return
	end

	if #g_round.highTyers > 1 then
		HighTieBreaker()
	end

	if #g_round.lowTyers > 1 then
		LowTieBreaker()
	end
end


function ResetGBCFrames()
	GBC_EditBox_Stakes:SetText(g_app.savedStakes)
	GBC_Btn_RoundNext:SetText("Start Round")
	GBC_Btn_RoundNext:Enable()

	GBC_StatusInfo_Update()

	--GBC_ROLL_Button:Disable();
	--GBC_AcceptEntries_Button:Enable();
	--GBC_LASTCALL_Button:Disable();
	--GBC_CHAT_Button:Enable();

	--if g_app.acceptedEntriesFrame ~= nil then
	--	g_app.acceptedEntriesFrame.text:SetText("")
	--	g_app.acceptedEntriesFrame:Hide()
	--end
end

--TODO soft code this for different rule sets
local function NextPhase()
	if g_round.currentPhase == 0 then
		StartRound()
	elseif g_round.currentPhase == 1 then
		AnnounceLastCall()
	elseif g_round.currentPhase == 2 then
		AnnounceRolling()
	end

	g_round.currentPhase = g_round.currentPhase + 1
end

--local function GBC_OnClickROLL()
--	DebugWrite(string.format("Beginning Roll Phase w/ <%d> entries", g_round.totalRolls))
--	if g_round.totalRolls > 0 and g_round.acceptRolls then
--		if table.getn(GBC.strings) ~= 0 then
--			ListRemainingPlayers()
--		end
--		return
--	end

--	if g_round.totalRolls > 1 or (g_app.debug and g_round.totalRolls > 0) then
---		g_round.acceptEntries = false 
--		g_round.acceptRolls = true 
--		if (g_round.currentTie == 0) then 
--			ChatMsg(format(".:Greybeards Casino - /roll %s NOW:.", currentStakes))
--		end
--
--		if (g_round.currentLowBreak == 1) then
--			ChatMsg(format("%s%d%s", "Low end tiebreaker! Roll 1-", g_round.currentStakes, " now!"))
--			ListRemainingPlayers()
--		end
--
--		if (g_round.currentHighBreak == 1) then
--			ChatMsg(format("%s%d%s", "High end tiebreaker! Roll 1-", g_round.currentStakes, " now!"));
--			ListRemainingPlayers();
--		end
--
		--GBC_EditBox:ClearFocus();
--	end

--	if g_round.acceptEntries and g_round.totalRolls < 2 and not g_app.debug then
--		ChatMsg("Not enough Players!");
--	end
--end


--function GBC_OnClickRoll()
	--hash_SlashCmdList[g_rollCmd](g_round.currentStakes)
	--hash_SlashCmdList[g_rollCmd](GBC_EditBox:GetText())
--end

--function GBC_OnClickRoll1()
--	ChatMsg(g_app.chatEnterMsg);
--end

--TODO remove JoinStats. unnecessary bloat that nobody will ever use
--Joins the stats for an alternate name
local function JoinStats(msg)
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

local function UnjoinStats(altname)
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

local function PrintStats(showAllStats)
	local sortlistname = {}
	local sortlistamount = {}
	local n = 0
	local i, j, k

	for name, totalWon in pairs(g_app.sessionStats) do
		if(GBC["joinstats"][strlower(name)] ~= nil) then
			name = GBC["joinstats"][strlower(name)]:gsub("^%l", string.upper)
		end
		for k=0,n do
			if(k == n) then
				sortlistname[n] = name
				sortlistamount[n] = totalWon
				n = n + 1
				break
			elseif(strlower(name) == strlower(sortlistname[k])) then
				sortlistamount[k] = (sortlistamount[k] or 0) + totalWon
				break
			end
		end
	end

	if(n == 0) then
		DEFAULT_CHAT_FRAME:AddMessage(".:GBC:. No stats recorded yet.")
		return
	end

	for i = 0, n-1 do
		for j = i+1, n-1 do
			if(sortlistamount[j] > sortlistamount[i]) then
				sortlistamount[i], sortlistamount[j] = sortlistamount[j], sortlistamount[i]
				sortlistname[i], sortlistname[j] = sortlistname[j], sortlistname[i]
			end
		end
	end

	DEFAULT_CHAT_FRAME:AddMessage("--- Greybeards Casino Stats ---", g_app.currentChatMethod)

	--if showAllStats then
	--	for k = 0, #sortlistamount do
	--		local sortsign = "won"
	--		if(sortlistamount[k] < 0) then sortsign = "lost" end
	--		ChatMsg(string.format("%d.  %s %s %d total", k+1, sortlistname[k], sortsign, math.abs(sortlistamount[k])), g_app.currentChatMethod)
	--	end
	--	return
	--end

	local top = 2;
	local bottom = n-3;

	if(top >= n) then top = n-1; end
	if(bottom <= top) then bottom = top+1; end

	for topIdx = 0, top do
		sortsign = "won";
		if(sortlistamount[topIdx] < 0) then sortsign = "lost"; end
		ChatMsg(string.format("%d.  %s %s %s total", topIdx+1, sortlistname[topIdx], sortsign, ConvertRollToGold(math.abs(sortlistamount[topIdx]))), g_app.currentChatMethod);
	end

	if(top+1 < bottom) then
		ChatMsg("...", g_app.currentChatMethod);
	end

	for btmIdx = bottom, n-1 do
		sortsign = "won";
		if(sortlistamount[btmIdx] < 0) then sortsign = "lost"; end
		ChatMsg(string.format("%d.  %s %s %s total", btmIdx+1, sortlistname[btmIdx], sortsign, ConvertRollToGold(math.abs(sortlistamount[btmIdx]))), g_app.currentChatMethod);
	end
end

local function ToggleRootFrame()
	g_app.showing = not g_app.showing
	
	if g_app.showing then
		GBC_Root:Show()
	else
		GBC_Root:Hide()
	end
end

function ShowRootFrame()
	g_app.showing = true
	GBC_Root:Show()
end

function CloseRootFrame()
	g_app.showing = false
	GBC_Root:Hide()
end

--function ToggleMinimap()
--	g_app.showMinimap = not g_app.showMinimap

	--if g_app.showMinimap then
	--	GBC_MinimapButton:Show()
	--else
	--	GBC_MinimapButton:Hide()
	--end
--end

--GBC_Settings = {
--	MinimapPos = 75
--}
-- ** do not call from the mod's OnLoad, VARIABLES_LOADED or later is fine. **
--function GBC_MinimapButton_Reposition()
	--GBC_MinimapButton:SetPoint(
	--	"TOPLEFT",
	--	"Minimap",
	--	"TOPLEFT",
	--	52-(80*cos(GBC_Settings.MinimapPos)),
	--	(80*sin(GBC_Settings.MinimapPos))-52)
--end

--TODO drag function does not work
--function GBC_MinimapButton_DraggingFrame_OnUpdate()
	--local xpos,ypos = GetCursorPosition()
	--local xmin,ymin = Minimap:GetLeft(), Minimap:GetBottom()

	--xpos = xmin-xpos/UIParent:GetScale()+70
	--ypos = ypos/UIParent:GetScale()-ymin-70

	--GBC_Settings.MinimapPos = math.deg(math.atan2(ypos,xpos))
	--GBC_MinimapButton_Reposition()
--end


--function GBC_MinimapButton_OnClick()
	--DEFAULT_CHAT_FRAME:AddMessage(tostring(arg1).." was clicked.")
--end

function ChangeChannel(channel)
	g_app.customChannel = channel
end

function ResetStats()
	--GBC["stats"] = { };
	g_app.sessionStats = {}
end

function ReportResults()
	local highRoll = GetCurrentHighRoll()
	local lowRoll = GetCurrentLowRoll()
	local goldowed = highRoll - lowRoll
	if goldowed ~= 0 and (highRoll > 0 and lowRoll > 0) then
		g_round.lowName = g_round.lowName:gsub("^%l", string.upper)
		g_round.highName = g_round.highName:gsub("^%l", string.upper)
		local msg = format("%s owes %s < %s >", g_round.lowName, g_round.highName, ConvertRollToGold(goldowed))

		g_app.sessionStats[g_round.highName] = (g_app.sessionStats[g_round.highName] or 0) + goldowed
		g_app.sessionStats[g_round.lowName] = (g_app.sessionStats[g_round.lowName] or 0) - goldowed

		ChatMsg(msg)
	else
		ChatMsg(".:GBC:. TIE! No payouts on this roll!")
	end
	
	--Reset Game
	ResetRound()
	ResetGBCFrames()
	--GBC_AcceptEntries_Button:SetText("Open Entry");
	--GBC_CHAT_Button:Enable();
end

function HighTieBreaker()
	local msgNames = ""
	for roller in g_round.highTyers do
		msgNames = format("%s, %s", msgNames, roller)
		g_round.entrants[roller].rolled = false
	end

	g_round.highTyers = {}

	ChatMsg(format(".:GBC:. High Tiebreaker between: ", msgNames))
end

function LowTieBreaker()
	local msgNames = ""
	for roller in g_round.lowTyers do
		msgNames = format("%s, %s", msgNames, roller)
		g_round.entrants[roller].rolled = false
	end

	g_round.lowTyers = {}
	ChatMsg(format(".:GBC:. Low Tiebreaker between: ", msgNames))
end

function Tiebreaker()
	g_round.tierolls = 0;
	g_round.totalRolls = 0;
	g_round.currentTie = 1;
	if table.getn(GBC.lowtie) == 1 then
		GBC.lowtie = {}; --TODO move to g_round
	end
	if table.getn(GBC.hightie) == 1 then
		GBC.hightie = {}; --TODO move to g_round
	end
	g_round.totalRolls = table.getn(GBC.lowtie) + table.getn(GBC.hightie);
	g_round.tierolls = g_round.totalRolls;
	if (table.getn(GBC.hightie) == 0 and table.getn(GBC.lowtie) == 0) then
		ReportResults();
	else
		g_round.acceptRolls = false;
		if table.getn(GBC.lowtie) > 0 then
			g_round.currentLowBreak = 1;
			g_round.currentHighBreak = 0;
			g_round.tielow = g_round.currentStakes+1;
			g_round.tiehigh = 0;
			g_round.entrants = GBC.lowtie
			--GBC.strings = GBC.lowtie; --TODO move to g_round
			GBC.lowtie = {}; --TODO move to g_round
			GBC_OnClickROLL(); --TODO local function
		end
		if table.getn(GBC.hightie) > 0  and #g_round.entrants == 0 then
			g_round.currentLowBreak = 0;
			g_round.currentHighBreak = 1;
			g_round.tielow = g_round.currentStakes+1;
			g_round.tiehigh = 0;
			g_round.entrants = GBC.hightie; --TODO move to g_round
			GBC.hightie = {}; --TODO move to g_round
			GBC_OnClickROLL(); --TODO local function
		end
	end
end

function ParseChatMsg(msg, username)
	if msg == g_app.chatEnterMsg then
		AddPlayer(username);
	elseif msg == g_app.chatWithdrawMsg then
		RemovePlayer(username);
	end
end

function ParseRoll(msg)
	local player, junk, roll, range = strsplit(" ", msg)

	if junk == "rolls" and g_round.entrants[player] ~= nil and not g_round.entrants[player].rolled then
		minRoll, maxRoll = strsplit("-", range)
		minRoll = tonumber(strsub(minRoll,2))
		maxRoll = tonumber(strsub(maxRoll,1,-2))
		roll = tonumber(roll)
		
		if minRoll ~= 1 or maxRoll ~= g_round.currentStakes then 
			--TODO some error output
			return
		end

		g_round.entrants[player].roll = roll
		g_round.entrants[player].rolled = true

		if roll > GetCurrentHighRoll() then
			g_round.highRoller = player
			g_round.highTyers = { player }
		elseif roll == GetCurrentHighRoll() then 
			table.insert(g_round.highTyers, player)
		end

		if roll < GetCurrentLowRoll() then
			g_round.lowRoller = player
			g_round.lowTyers = { player }
		elseif roll == GetCurrentLowRoll() then 
			table.insert(g_round.lowTyers, player)
		end
		
		--TIE Breaker logic
		--if g_round.currentTie == 0 then --TODO this needs to be a bool
			--if roll == g_round.currentHighRoll then
			--	if table.getn(GBC.hightie) == 0 then
			--		AddTiedPlayer(g_round.highName, GBC.hightie)
			--	end
			--	AddTiedPlayer(player, GBC.hightie)
			--end
			
			--if roll > g_round.currentHighRoll then
			--	g_round.highName = player
			--	g_round.currentHighRoll = roll
				--TODO cleanup
			--	GBC.hightie = {}
			--end
			
			--if roll == g_round.currentLowRoll then
			--	if table.getn(GBC.lowtie) == 0 then
			--		AddTiedPlayer(g_round.lowName, GBC.lowtie)
			--	end
			--	AddTiedPlayer(player, GBC.lowtie)
			--end
			
			--if roll < g_round.currentLowRoll then
			--	g_round.lowName = player
			--	g_round.currentLowRoll = roll
				--TODO cleanup
			--	GBC.lowtie = {}
			--end
		--else
		if g_round.currentTie ~= 0 then
			if g_round.currentLowBreak == 1 then
				if roll == g_round.tielow then
					if table.getn(GBC.lowtie) == 0 then
						AddTiedPlayer(g_round.lowName, GBC.lowtie)
					end
					AddTiedPlayer(player, GBC.lowtie)
				end
				if roll < g_round.tielow then
					g_round.lowName = player
					g_round.tielow = roll
					GBC.lowtie = {}
				end
			end
			
			if g_round.currentHighBreak == 1 then
				if roll == g_round.tiehigh then
					if table.getn(GBC.hightie) == 0 then
						AddTiedPlayer(g_round.highName, GBC.hightie)
					end
					AddTiedPlayer(player, GBC.hightie)
				end
				if roll > g_round.tiehigh then
					g_round.highName = player
					g_round.tiehigh = roll
					GBC.hightie = {}
				end
			end
		end

		--DebugWrite(string.format("Accepted roll. Removing player %s", player))
		
		--RemovePlayer(player)
		--g_round.totalEntries = g_round.totalEntries + 1

		if GetRemainingToRollCount() == 0 then
			RoundWrapup()
		end
		
		GBC_StatusInfo_Update()
	end
end

--TODO table contains player function
function GBC_Check(player)	
	return GBC.string[player] ~= nil
	--for i=1, table.getn(GBC.strings) do
	--	if GBC.strings[i] == player then
	--		return true
	--	end
	--end
	--return false
end

function GetCurrentHighRoll()
	if g_round.highRoller == nil then
		return 0
	end

	return g_round.entrants[g_round.highRoller].roll
end

function GetCurrentLowRoll()
	if g_round.lowRoller == nil then
		return g_round.currentStakes
	end

	return g_round.entrants[g_round.lowRoller].roll
end

function AddPlayer(name)
	if IsBanned(name) then
		ChatMsg(format("%s: You're banned from the casino! Get outta here ya degenerate.", name))
		return	
	end

	if g_round.entrants == nil then
		g_round.entrants = {}
	end

	local charname, realmname = strsplit("-",name)
	print(format("charname %s", charname))
	print(g_round.entrants[charname])
	if charname ~= nil and g_round.entrants[charname] == nil then
		entrantInfo = { 
			name = charname,
			rolled = false,
			roll = -1 
		}

		g_round.entrants[charname] = entrantInfo
		--table.insert(g_round.entrants, #g_round.entrants, entrantInfo)
		--print(g_round.entrants[charname].name)
		--print("tset"..#g_round.entrants) 
		--TODO totalRolls cleanup
		g_round.totalRolls = g_round.totalRolls+1

		DebugWrite(format("Added player: %s", charname))
	end
	
	--if not GBC_LASTCALL_Button:IsEnabled() and g_round.totalRolls == 1 then
	--	GBC_LASTCALL_Button:Enable();
	--end
	
	--if g_round.totalRolls == 2 then
	--	GBC_AcceptEntries_Button:Disable();
	--	GBC_AcceptEntries_Button:SetText("Open Entry");
	--end

	--UpdateStatusInfo()
	GBC_StatusInfo_Update()
end

--TODO remove this entire thing
--function RemovePlayer(name)
--	local charname, realmname = strsplit("-",name)
--	local insname = charname

	--for i=1, table.getn(GBC.strings) do
	--	if GBC.strings[i] ~= nil then
	--	  	if strlower(GBC.strings[i]) == strlower(insname) then
	--			table.remove(GBC.strings, i)
	--			g_round.totalRolls = g_round.totalRolls - 1;
--
	--			DebugWrite(format("Removed player %s", insname))
	--		end
	--	end
	--end
	
	--if (GBC_LASTCALL_Button:IsEnabled() and g_round.totalRolls == 0) then
	--	GBC_LASTCALL_Button:Disable();
	--end
	
	--if g_round.totalRolls == 1 then
	--	GBC_AcceptEntries_Button:Enable();
	--	GBC_AcceptEntries_Button:SetText("Open Entry");
	--end
--end

--TODO remove, 
function ListRemainingPlayers()
	--for i=1, table.getn(GBC.strings) do
	--  	local msg = strjoin(" ", "", tostring(GBC.strings[i]):gsub("^%l", string.upper),"still needs to roll.")
	--	ChatMsg(msg);
	--end
end

function GetRemainingToRollCount()
	remainCount = 0
	for key,value in pairs(g_round.entrants) do
		if not value.rolled then
			remainCount = remainCount + 1
		end
	end
	return remainCount
end


function ListBannedPlayers()
	local bancnt = 0;
	WriteMsg("", "", "|cffffff00To ban do /gbc ban (Name) or to unban /gbc unban (Name) - The Current Bans:");
	for i=1, table.getn(GBC.bans) do
		bancnt = 1;
		--DEFAULT_CHAT_FRAME:AddMessage(strjoin("|cffffff00", "...", tostring(GBC.bans[i])));
	end
	if (bancnt == 0) then
		--DEFAULT_CHAT_FRAME:AddMessage("|cffffff00To ban do /gbc ban (Name) or to unban /gbc unban (Name).");
	end
end

--TODO table contains
function IsBanned(name)
	local charname, realmname = strsplit("-",name);
	local insname = charname;
	
	--TODO check if contained in table
	if (insname ~= nil or insname ~= "") then
		for i=1, table.getn(GBC.bans) do
			if strlower(GBC.bans[i]) == strlower(insname) then
				return true
			end
		end
	end
	return false
end

function AddBannedPlayer(name)
	local charname, realmname = strsplit("-", name);
	local insname = charname;
	
	if (insname ~= nil or insname ~= "") then
		WriteMsg("", "", "|cffffff00Error: No name provided.");
		return
	end
	
	for i=1, table.getn(GBC.bans) do
		if GBC.bans[i] == insname then
			WriteMsg("", "", "|cffffff00Unable to add to ban list - user already banned.");
			return
		end
	end
	
	table.insert(GBC.bans, insname)
	WriteMsg("", "", "|cffffff00User is now banned!");
	--local banMsg = strjoin(" ", "", "User Banned from rolling! -> ",insname, "!")
	--DEFAULT_CHAT_FRAME:AddMessage(strjoin("|cffffff00", banMsg));
end

function RemoveBannedPlayer(name)
	local charname, realmname = strsplit("-",name);
	local insname = charname;
	if (insname ~= nil or insname ~= "") then
		for i=1, table.getn(GBC.bans) do
			if GBC.bans[i] == insname then
				table.remove(GBC.bans, i)
				WriteMsg("", "", "|cffffff00User removed from ban successfully.");
				return;
			end
		end
	else
		WriteMsg("", "", "|cffffff00Error: No name provided.");
	end
end

function AddTiedPlayer(name, tietable)
	local charname, realmname = strsplit("-",name)
	local insname = charname
	
	if (insname ~= nil or insname ~= "") then
		local exists = false;
		for i=1, table.getn(tietable) do
		  	if tietable[i] == insname then
				exists = true;
			end
		end
		if not exists then
		    table.insert(tietable, insname)
			g_round.tierolls = g_round.tierolls+1
			g_round.totalRolls = g_round.totalRolls+1
		end
	end
end

--Display all player info in the status panel
function GBC_StatusInfo_Update()
	if g_round == nil or g_round.entrants == nil or next(g_round.entrants) == nil then
		for idx=1, 15, 1 do
			local f = getglobal("GBC_StatusEntry_"..(idx))
			if f ~= nil then
				f:SetText("")
			end
		end
		return
	end

	local idx = 1
	for key,value in pairs(g_round.entrants) do
		local f = getglobal("GBC_StatusEntry_"..(idx))
		if f ~= nil then 
			local rollText = tostring(value.roll)
			if tonumber(value.roll) < 0 then
				rollText = "NOROLL"
			end

	  		f:SetText(format("%d. %s - [ %s ]", 
	  			idx, 
	  			value.name, 
	  			rollText))
	  	end
	  	idx = idx + 1
	end

	FauxScrollFrame_Update(GBC_StatusInfo, 40, 15, 12);
end

function WriteMsg(pre, red, text)
	if red == "" then 
		red = "/gbc" 
	end
	DEFAULT_CHAT_FRAME:AddMessage(pre..GREEN_FONT_COLOR_CODE..red..FONT_COLOR_CODE_CLOSE..": "..text)
end

function ChatMsg(msg, chatType, language, channel)
	chatType = g_app.currentChatMethod
	channelnum = GetChannelName(channel or g_app.customChannel)
	SendChatMessage(msg, chatType, language, channelnum)
end

function DebugMode(enable)
	msg = "enabled"
	if not enable then
		msg = "disabled"
	end
	WriteMsg("","",format("Debug mode <%s>", strupper(msg)))
	g_app.debug = enable
end

function DebugWrite(msg)
	if g_app.debug then
		WriteMsg("","","[DEBUG] "..msg)
	end
end


-- LOAD FUNCTION --
function GBC_OnLoad(self)
	DEFAULT_CHAT_FRAME:AddMessage("|cffffff00<Greybeards Casino> loaded. Type /gbc to display available commands.")

	self:RegisterEvent("CHAT_MSG_RAID")
	self:RegisterEvent("CHAT_MSG_CHANNEL")
	self:RegisterEvent("CHAT_MSG_RAID_LEADER")
	self:RegisterEvent("CHAT_MSG_PARTY_LEADER")
	self:RegisterEvent("CHAT_MSG_PARTY")
	self:RegisterEvent("CHAT_MSG_GUILD")
	self:RegisterEvent("CHAT_MSG_SAY")
	self:RegisterEvent("CHAT_MSG_SYSTEM")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	
	self:RegisterForDrag("LeftButton");
    
	ResetGBCFrames()

	--DEFAULT to not show
	if not g_app.debug then
		ToggleRootFrame()
	end
end

function GBC_OnEvent(self, event, ...)
	if event == "PLAYER_ENTERING_WORLD" then
		--TODO remove
		if(not GBC) then
			GBC = {
				--["chat"] = 1,
				--["strings"] = { },
				["lowtie"] = { }, --TODO remove
				["hightie"] = { }, --TODO remove
				["bans"] = { },
			}
		--TODO cleanup crossgambling relic
		-- fix older legacy items for new chat channels.  Probably need to iterate through each to see if it should be set.
		--elseif tostring(type(GBC["chat"])) ~= "number" then
		--	GBC["chat"] = 1
		end

		--if(not GBC["stats"]) then 			GBC["stats"] 		= { }; end
		if(not GBC["joinstats"]) then 		GBC["joinstats"] 	= { }; end
		--if(not GBC["chat"]) then 			GBC["chat"] 		= 1; end
		if(not GBC["bans"]) then 			GBC["bans"] 		= { }; end
	
		--TODO UI initialization
		--GBC_EditBox:SetJustifyH("CENTER");
		--GBC_EditBox:SetText(g_app.lastRoll);

		--SetChatTarget
		--g_app.currentChatMethod = g_app.chatMethods[GBC["chat"]]
		--GBC_CHAT_Button:SetText(string.format("Broadcast Gambling to: %s", g_app.currentChatMethod)); 

		--MiniMap
		--if g_app.showMinimap then
		--	GBC_MinimapButton:Show()
		--else
		--	GBC_MinimapButton:Hide()
		--end

		--TODO move to ?? idk
		--if(GBC["active"] == 1) then
		--	GBC_Frame:Show();
		--else
		--	GBC_Frame:Hide();
		--end
	end

	-- CHAT PARSING 
	--TODO clean this up. sloppy string checking
	if ((event == "CHAT_MSG_RAID_LEADER" or event == "CHAT_MSG_RAID") and g_round.acceptEntries and g_app.currentChatMethod == "RAID") then
		local msg, _,_,_,name = ... -- name no realm
		ParseChatMsg(msg, name)
	end

	if ((event == "CHAT_MSG_PARTY_LEADER" or event == "CHAT_MSG_PARTY")and g_round.acceptEntries and g_app.currentChatMethod == "PARTY") then
		local msg, name = ... -- name no realm
		ParseChatMsg(msg, name)
	end

    if ((event == "CHAT_MSG_GUILD_LEADER" or event == "CHAT_MSG_GUILD")and g_round.acceptEntries and g_app.currentChatMethod == "GUILD") then
		local msg, name = ... -- name no realm
		ParseChatMsg(msg, name)
	end
	
	if event == "CHAT_MSG_CHANNEL" and g_round.acceptEntries and g_app.currentChatMethod == "CHANNEL" then
		local msg,_,_,_,name,_,_,_,channel = ...
		if channel == g_app.customChannel then
			ParseChatMsg(msg, name)
		end
	end

	if event == "CHAT_MSG_SAY" and g_round.acceptEntries and g_app.currentChatMethod == "SAY" then
		local msg, name = ... -- name no realm
		ParseChatMsg(msg, name)
	end

	if event == "CHAT_MSG_SYSTEM" and g_round.acceptRolls then
		local msg = ...
		ParseRoll(msg);
	end
end

--TODO cleanup slop
--local EventFrame=CreateFrame("Frame");
-- Need to register an event to receive it
--EventFrame:RegisterEvent("CHAT_MSG_WHISPER");
--EventFrame:SetScript("OnEvent", function(self,event,msg,sender)
	--We're making sure the command is case insensitive by casting it to lowercase before running a pattern check
--    if msg:lower():find("!stats") then
--        ChatMsg("Work in Progress","WHISPER",nil,sender);
--    end
--end);

--local function OptionsFormatter(text, prefix)
--	if prefix == "" or prefix == nil then 
--		prefix = "/gbc" 
--	end
--	DEFAULT_CHAT_FRAME:AddMessage(string.format("%s%s%s: %s", GREEN_FONT_COLOR_CODE, prefix, FONT_COLOR_CODE_CLOSE, text))
--end

function GBC_EditBox_Stakes_OnLoad()
    GBC_EditBox_Stakes:SetNumeric(true);
	GBC_EditBox_Stakes:SetAutoFocus(false);
end

function GBC_EditBox_Stakes_OnEnterPressed()
    GBC_EditBox_Stakes:ClearFocus();
end

function GBC_CloseFrame()
	CloseRootFrame()
end

local function CreateChatMethodText(chatMethod)
	return format("Broadcast to %s", chatMethod)
end

function SetChatMethod(self)
	local chatMethod = self.value
	g_app.currentChatMethod = chatMethod
	UIDropDownMenu_SetSelectedValue(GBC_Btn_ChatBroadcast, self, true)
	UIDropDownMenu_SetText(GBC_Btn_ChatBroadcast, CreateChatMethodText(chatMethod))
end

function GBC_Btn_ChatBroadcast_OnLoad()
	for idx=1, #g_app.chatMethods, 1 do
		option = {
			text = CreateChatMethodText(g_app.chatMethods[idx]),
			value = g_app.chatMethods[idx], 
			func = SetChatMethod
		}

		UIDropDownMenu_AddButton(option)

		if UIDropDownMenu_GetText(GBC_Btn_ChatBroadcast) == nil then
			UIDropDownMenu_SetSelectedValue(GBC_Btn_ChatBroadcast, option, true)
			UIDropDownMenu_SetText(GBC_Btn_ChatBroadcast, CreateChatMethodText(g_app.chatMethods[idx]))
		end 
	end 

	UIDropDownMenu_SetWidth(GBC_Btn_ChatBroadcast, GBC_Admin:GetWidth()-40, 0)
	UIDropDownMenu_JustifyText(GBC_Btn_ChatBroadcast, "LEFT")
end

--TODO remove
--function GBC_Btn_ChatBroadcast_OnClick()
	--TODO cleanup, find a clean way to loop over available chat channels
	--TODO remove this redundant GBC["chat"]
--	if(GBC["chat"] == nil) then 
--		GBC["chat"] = 1 
--	end

--	GBC["chat"] = (GBC["chat"] % #g_app.chatMethods) + 1
--	g_app.currentChatMethod = g_app.chatMethods[GBC["chat"]]

--	GBC_Btn_ChatBroadcast:SetText(format("Broadcast to: %s", g_app.currentChatMethod))
	
	--GBC_CHAT_Button:SetText(string.format("Broadcast Gambling to: %s", g_app.currentChatMethod))
	--print(g_app.currentChatMethod)
--	WriteMsg("","",string.format("Channel set to: %s", g_app.currentChatMethod))
	--if g_app.currentChatMethod == "CHANNEL" then
	--	WriteMsg("","",string.format("Custom channel set to: %s", g_app.customChannel))
	--end
--end

function GBC_Btn_StatsDisplay_OnClick()
	PrintStats(false)
end

--TODO
function GBC_Btn_StatsReset_OnClick()

end

--function GBC_Reset()
--	GBC["strings"] = { }; --TODO ???
--	GBC["lowtie"] = { }; --TODO remove
--	GBC["hightie"] = { }; --TODO remove
	
--	g_round = g_roundDefaults
	
	--GBC_ResetUI()
	
	--GBC_AcceptEntries_Button:SetText("Open Entry");
--	WriteMsg("", "", "|cffffff00GCG has now been reset");
--end

--function GBC_ResetCmd()
--	ChatMsg(".:GBC:. Game has been reset", chatmethod)
--end

function GBC_Btn_RoundNext_OnClick()
	NextPhase()
end

function GBC_Btn_RoundReset_OnClick()
	ResetRound()
end

--TODO attach a function callback to each slash command
--		cuts out 90% of this vertical space
--function GBC_SlashCmd(msg)


	--local msg = msg:lower()
	
	--if (msg == "" or msg == nil) then
	--    WriteMsg("", "", "~Following commands for GreybeardsCasino~")
	--	WriteMsg("", "", "show - Shows the frame")
	--	WriteMsg("", "", "hide - Hides the frame")
	--	WriteMsg("", "", "channel - Change the custom channel for gambling")
	--	WriteMsg("", "", "reset - Resets the AddOn")
	--	WriteMsg("", "", "fullstats - list full stats")
	--	WriteMsg("", "", "resetstats - Resets the stats")
	--	WriteMsg("", "", "joinstats [main] [alt] - Apply [alt]'s win/losses to [main]")
	--	WriteMsg("", "", "minimap - Toggle minimap show/hide")
	--	WriteMsg("", "", "unjoinstats [alt] - Unjoin [alt]'s win/losses from whomever it was joined to")
	--	WriteMsg("", "", "ban - Ban's the user from being able to roll")
	--	WriteMsg("", "", "unban - Unban's the user")
	--	WriteMsg("", "", "listban - Shows ban list")
	--	WriteMsg("", "", "debug {enable|disable}")
	--	return
	--end
	
	--if (msg == "hide") then
	--	CloseRootFrame()
	--	return
	--end
	
	--if (msg == "show") then
	--	OpenRootFrame()
	--	return
	--end
	
	--if (msg == "reset") then
	--	GBC_Reset()
	--	return
	--end
	
	--if (msg == "fullstats") then
	--	PrintStats(true)
	--	return
	--end
	
	--if (msg == "resetstats") then
	--	ResetStats()
	--	return
	--end
	
	--if (msg == "minimap") then
	--	ToggleMinimap()
	--	return
	--end
	
	--if (string.sub(msg, 1, 7) == "channel") then
	--	ChangeChannel(strsub(msg, 9))
	--	return
	--end
	
	--if (string.sub(msg, 1, 9) == "joinstats") then
	--	JoinStats(strsub(msg, 11))
	--	return
	--end
	
	--if (string.sub(msg, 1, 11) == "unjoinstats") then
	--	UnjoinStats(strsub(msg, 13))
	--	return
	--end

	--if (string.sub(msg, 1, 3) == "ban") then
	--	AddBannedPlayer(strsub(msg, 5))
	--	return
	--end

	--if (string.sub(msg, 1, 5) == "unban") then
	--	RemoveBannedPlayer(strsub(msg, 7))
	--	return
	--end

	--if (string.sub(msg, 1, 7) == "listban") then
	--	ListBannedPlayers()
	--	return
	--end

	--if(string.sub(msg,1,5) == "debug" and string.sub(msg,7,13) == "enable") then
	--	DebugMode(true)
	--	return
	--end

	--if(string.sub(msg,1,5) == "debug" and string.sub(msg,7,14) == "disable") then
	--	DebugMode(false)
	--	return
	--end

	--Fallthrough
	--WriteMsg("", "", "|cffffff00Invalid argument for command /cg")
--end

local g_cmds = {
	show = {
		cmd = "show",
		func = ShowRootFrame,
		description = "Shows the main window."
	},
	hide = {
		cmd = "hide",
		func = CloseRootFrame,
		description = "Hides the main window."
	},
	reset = {
		cmd = "reset",
		func = GBC_Reset,
		description = "Reset the current round."
	},
	debug = {
		cmd = "debug",
		func = DebugMode,
		description = "Debug mode { on | off }"
	}
}

function GBC_SlashCmd(msg)
	if (msg == "" or msg == nil) then
		WriteMsg("", "", "~Following commands for GreybeardsCasino~")

		for key,value in pairs(g_cmds) do
			WriteMsg("","", format("%s - %s", value.cmd, value.description))
		end

	elseif g_cmds[msg] ~= nil then
		g_cmds[msg].func()
	else
		WriteMsg("", "", "|cffffff00Invalid argument for command /gbc")
	end
end


SLASH_GBC1 = "/gbc"
SlashCmdList["GBC"] = GBC_SlashCmd


--MINIMAP BUTTON
function GBC_MinimapBtn_DraggingFrame_OnUpdate()
	local xpos,ypos = GetCursorPosition()
	local xmin,ymin = Minimap:GetLeft(), Minimap:GetBottom()

	xpos = xmin-xpos/UIParent:GetScale()+70
	ypos = ypos/UIParent:GetScale()-ymin-70

	local minimapPos = math.deg(math.atan2(ypos,xpos))
	local xoffset = 52 - ( 80 * cos(minimapPos))
	local yoffset = (80 * sin(minimapPos)) - 52
	GBC_MinimapBtn:SetPoint("TOPLEFT","Minimap","TOPLEFT", xoffset, yoffset)
end

function GBC_MinimapBtn_OnClick()
	ToggleRootFrame()
end

