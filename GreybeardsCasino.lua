--Greybeards Casino
--Author: Looch

local g_app = {
	debug = false,
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
	sessionStats = {},
	minimapPosition = 75,
	rulesName = "Hi/Lo",
	version = "1.1.0", --TODO pull this from .toc
	banList = {}
}

local g_roundDefaults = {
	currentPhase = 0,
	maxPhases = 3,
	currentStakes = 0,
	entrants = {},
	entrantsCount = 0,
	acceptEntries = false,
	acceptRolls = false,
	highRoller = nil,
	lowRoller = nil, 
	highTyers = {},
	lowTyers = {},
}

local g_round = g_roundDefaults

local function has_value(arr, val) 
	for index, value in ipairs(arr) do
        if value == val then
            return true
        end
    end
    return false
end

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

--TODO find a way to deep copy round defaults
local function ResetRound()
	g_round = g_roundDefaults
	g_round.currentPhase = 0
	g_round.entrantsCount = 0
	g_round.acceptRolls = false
	
	ResetGBCFrames()

	WriteMsg("", "", "|cffffff00GCG Round has now been reset")
end

local function StartRound()
	--Grab current stakes before resetting round defaults
	g_app.savedStakes = tonumber(GBC_EditBox_Stakes:GetText())
	GBC_EditBox_Stakes:ClearFocus()

	ResetRound()

	g_round.entrants = {}
	g_round.highRoller = nil
	g_round.lowRoller = nil
	g_round.acceptEntries = true
	g_round.currentStakes = g_app.savedStakes

	ChatMsg(format(".:Greybeards Casino:. RULES: %s .:. STAKES << %s >>", g_app.rulesName, ConvertRollToGold(g_round.currentStakes)))
	ChatMsg(format(".:GBC:. To enter: type %s", g_app.chatEnterMsg))

	GBC_Btn_RoundNext:SetText("Announce Last Call")
	GBC_StatusInfo_Update()
end

local function AnnounceLastCall()
	ChatMsg(format(".:GBC:. Last Call to join! To withdraw, type %s", g_app.chatWithdrawMsg))
	GBC_Btn_RoundNext:SetText("Begin Rolling")
end

local function AnnounceRolling()
	DebugWrite(string.format("Beginning Roll Phase w/ <%d> entries", table.getn(g_round.entrants)))

	if g_round.entrantsCount > 1 or (g_app.debug and g_round.entrantsCount > 0) then
		g_round.acceptEntries = false 
		g_round.acceptRolls = true  

		ChatMsg(format(".:GBC - /roll %s NOW:.", g_round.currentStakes))
	end

	if g_round.acceptEntries and g_round.entrantsCount < 2 and not g_app.debug then
		ChatMsg("Not enough Players!")
	end

	GBC_Btn_RoundNext:Disable()
	GBC_Btn_RoundNext:SetText("Waiting for rolls...")
	GBC_Btn_ListRemaining_Update();
end

function RoundWrapup()
	ReportResults()
	ResetRound()
	ResetGBCFrames()
end

function ResetGBCFrames()
	GBC_EditBox_Stakes:SetText(g_app.savedStakes)
	GBC_Btn_RoundNext:SetText("Start Round")
	GBC_Btn_RoundNext:Enable()
	GBC_Btn_ListRemaining:Disable()

	GBC_StatusInfo_Update()
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

--TODO massively rework this
local function PrintStats(showAllStats)
	local sortlistname = {}
	local sortlistamount = {}
	local n = 0
	local i, j, k

	for name, totalWon in pairs(g_app.sessionStats) do
	--	if(GBC["joinstats"][strlower(name)] ~= nil) then
	--		name = GBC["joinstats"][strlower(name)]:gsub("^%l", string.upper)
	--	end
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

	--DEFAULT_CHAT_FRAME:AddMessage("--- Greybeards Casino Stats ---", g_app.currentChatMethod)
	ChatMsg(".:Greybeards Casino Stats:.")
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
		if sortlistamount[topIdx] ~= 0 then 
			ChatMsg(string.format("%d.  %s %s %s total", topIdx+1, sortlistname[topIdx], sortsign, ConvertRollToGold(math.abs(sortlistamount[topIdx]))), g_app.currentChatMethod);
		end
	end

	if(top+1 < bottom) then
		ChatMsg("...", g_app.currentChatMethod);
	end

	for btmIdx = bottom, n-1 do
		sortsign = "won";
		if(sortlistamount[btmIdx] < 0) then sortsign = "lost"; end
		if sortlistamount[topIdx] ~= 0 then 
			ChatMsg(string.format("%d.  %s %s %s total", btmIdx+1, sortlistname[btmIdx], sortsign, ConvertRollToGold(math.abs(sortlistamount[btmIdx]))), g_app.currentChatMethod);
		end
	end
end

--TODO soft code rule sets
function PrintRules()
	ChatMsg(format(".:GBC:. %s RULES:.", g_app.rulesName))
	ChatMsg(".:Players will /roll the STAKES:.")
	ChatMsg(".:High roll wins. Low Roll loses. Loser pays out the roll difference:.")
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

function ChangeChannel(channel)
	g_app.customChannel = channel
end

function ResetStats()
	g_app.sessionStats = {}
	WriteMsg("", "", "|cffffff00GCG Stats have now been reset")
end

function PlayerStatsUpdate(name, value)
	g_app.sessionStats[name] = (g_app.sessionStats[name] or 0) + value
end

function ReportResults()
	local highRoll = GetCurrentHighRoll()
	local lowRoll = GetCurrentLowRoll()
	local goldOwed = highRoll - lowRoll

	local splitCount = table.getn(g_round.lowTyers) + table.getn(g_round.highTyers) - 1
	goldOwed = goldOwed / splitCount

	if goldOwed ~= 0 and (highRoll > 0 and lowRoll > 0) then
		--TODO clean up this with a function to add amount to player stats
		local lowNames = g_round.lowRoller
		PlayerStatsUpdate(g_round.lowRoller, -goldOwed)
		for idx=2, #g_round.lowTyers, 1 do
			lowNames = lowNames..","..g_round.lowTyers[idx]
			PlayerStatsUpdate(g_round.lowTyers[idx], -goldOwed)
		end

		local highNames = g_round.highRoller
		PlayerStatsUpdate(g_round.highRoller, goldOwed)
		for idx=2, #g_round.highTyers, 1 do
			highNames = highNames..", "..g_round.highTyers[idx]
			PlayerStatsUpdate(g_round.highTyers[idx], goldOwed)
		end

		local msg = format("%s owes %s < %s >", lowNames, highNames, ConvertRollToGold(goldOwed))
		if splitCount > 1 then
			msg = msg.." each."
		end

		ChatMsg(format(".:GBC Payouts:. %s", msg))
	else
		ChatMsg(".:GBC:. TIE! No payouts on this roll!")
	end
end

function HighTieBreaker(rTyers)
	local msgNames = ""
	for idx=1 , #rTyers, 1 do
		local roller =rTyers[idx]
		msgNames = format("%s, %s", msgNames, roller)
		g_round.entrants[roller].rolled = false
		g_round.entrants[roller].roll = -1
	end

	g_round.highTieBreakActive = true

	ChatMsg(format(".:GBC:. High Tiebreaker between: ", msgNames))
end

function LowTieBreaker(rTyers)
	local msgNames = ""
	for idx=1, #rTyers, 1 do
		local roller = rTyers[idx]
		msgNames = format("%s, %s", msgNames, roller)
		g_round.entrants[roller].rolled = false
		g_round.entrants[roller].roll = -1
	end

	g_round.lowTieBreakActive = true

	ChatMsg(format(".:GBC:. Low Tiebreaker between: %s. Roll again!", msgNames))
end

function ParseChatMsg(msg, username)
	if msg == g_app.chatEnterMsg then
		AddPlayer(username);
	elseif msg == g_app.chatWithdrawMsg then
		WithdrawPlayer(username);
	end
end

function ParseRoll(msg)
	local playerName, junk, roll, range = strsplit(" ", msg)
	local player = g_round.entrants[playerName]

	if player == nil or not player.entered or player.rolled or junk ~= "rolls" then
		return
	end 

	minRoll, maxRoll = strsplit("-", range)
	minRoll = tonumber(strsub(minRoll,2))
	maxRoll = tonumber(strsub(maxRoll,1,-2))
	roll = tonumber(roll)
	
	if minRoll ~= 1 or maxRoll ~= g_round.currentStakes and (roll > maxRoll or roll < minRoll) then 
		DebugWrite("Invalid roll parsed!")
		return
	end

	player.rolled = true
	player.roll = roll

	if roll > GetCurrentHighRoll() then
		g_round.highRoller = playerName
		g_round.highTyers = { playerName }
	elseif roll == GetCurrentHighRoll() then 
		table.insert(g_round.highTyers, playerName)
	end

	if roll < GetCurrentLowRoll() then
		g_round.lowRoller = playerName
		g_round.lowTyers = { playerName }
	elseif roll == GetCurrentLowRoll() then 
		table.insert(g_round.lowTyers, playerName)
	end

	if GetRemainingToRollCount() == 0 then
		RoundWrapup()
	end
	
	GBC_StatusInfo_Update()
	GBC_Btn_ListRemaining_Update()
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

function GetCurrentHighTieHighRoll()
	if g_round.highTieHighRoller == nil then
		return 0
	end

	return g_round.entrants[g_round.highTieHighRoller].roll
end

function GetCurrentHighTieLowRoll()
	if g_round.highTieLowRoller == nil then
		return g_round.currentStakes
	end

	return g_round.entrants[g_round.highTieLowRoller].roll
end

function GetCurrentLowTieHighRoll()
	if g_round.lowTieHighRoller == nil then
		return 0
	end

	return g_round.entrants[g_round.lowTieHighRoller].roll
end

function GetCurrentLowTieLowRoll()
	if g_round.lowTieLowRoller == nil then
		return g_round.currentStakes
	end

	return g_round.entrants[g_round.lowTieLowRoller].roll
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
	if charname ~= nil and g_round.entrants[charname] == nil then
		entrantInfo = { 
			name = charname,
			rolled = false,
			roll = -1,
			entered = true 
		}

		g_round.entrants[charname] = entrantInfo
		g_round.entrantsCount = g_round.entrantsCount + 1

		DebugWrite(format("Added player: %s", charname))
	else
		g_round.entrants[charname].entered = true
	end
	
	GBC_StatusInfo_Update()
end

function WithdrawPlayer(name)
	DebugWrite(format("Withdrawing players %s", name))

	local charname, realmname = strsplit("-",name)
	if charname == nil or g_round.entrants[charname] == nil then
		return
	end

	g_round.entrants[charname].entered = false

	GBC_StatusInfo_Update()
end

function GBC_Btn_ListRemaining_Update()
	DebugWrite(format("list %d", GetRemainingToRollCount()))
	if GetRemainingToRollCount() > 0 then
		GBC_Btn_ListRemaining:Enable()
	else
		GBC_Btn_ListRemaining:Disable()
	end
end

function ListRemainingPlayers()
	local strRollers = ""
	for player, info in pairs(g_round.entrants) do
		if not info.rolled then
			local delim = ", "
			if strRollers == "" then
				delim = ""
			end

			strRollers = player..delim..strRollers
		end	
	end

	local msg = format("Remaining Rollers: %s", strRollers)
	if strRollers == "" then
		msg = "Everyone has rolled."
	end
	ChatMsg(msg)
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

--TODO rework bans
function ListBannedPlayers()
	WriteMsg("", "", "|cffffff00To ban do /gbc ban (Name) or to unban /gbc unban (Name) - The Current Bans:");
end

function IsBanned(name)
	local charname, realmname = strsplit("-",name)
	return g_app.banList[charname] ~= nil
end

function AddBannedPlayer(name)
	local charname, realmname = strsplit("-", name)
	
	if charname == nil or charname == "" then
		WriteMsg("", "", "|cffffff00Error: No name provided.")
		return
	end
	
	if IsBanned(charname) then
		WriteMsg("", "", "|cffffff00Unable to add to ban list - user already banned.");
		return
	end

	table.insert(g_app.banList, charname)
	WriteMsg("", "", "|cffffff00User is now banned!");
end

function RemoveBannedPlayer(name)
	local charname, realmname = strsplit("-",name);

	if charname == nil or charname == "" then
		DebugWrite("BAN Remove - No Name provided")
		return
	end

	table.remove(g_app.banList, charname)
	WriteMsg("", "", "|cffffff00User removed from ban successfully.");
end

--Display all player info in the status panel
function GBC_StatusInfo_Update()
	--Clear status frames
	if g_round == nil or g_round.entrants == nil or next(g_round.entrants) == nil then
		for idx=1, 15, 1 do
			local f = getglobal("GBC_StatusEntry_"..(idx))
			if f ~= nil then
				f:SetText("")
			end
		end
		return
	end

	--Fill status frames with entrant info
	local idx = 1
	for key,value in pairs(g_round.entrants) do
		local f = getglobal("GBC_StatusEntry_"..(idx))
		if f ~= nil then 
			local rollText = tostring(value.roll)
			local btnFS = f:CreateFontString()
			btnFS:SetFont(f:GetNormalFontObject():GetFont())	
			btnFS:SetTextColor(0.75, 0.75, 0.75)

			--TODO soft code these colors
			--ENTERED
			if tonumber(value.roll) <= 0 then
				rollText = "---"
				btnFS:SetTextColor(0.91, 0.88, 0.08) 
			else
				if has_value(g_round.highTyers, value.name) then
					btnFS:SetTextColor(0.2, 1, 0.2)
				elseif has_value(g_round.lowTyers, value.name) then
					btnFS:SetTextColor(1, 0.2, 0.2)
				end
			end
			--WITHDRAWN
			if not value.entered then
				rollText = "X"
				btnFS:SetTextColor(0.5, 0.5, 0.5) 
			end

	  		btnFS:SetText(format("%d. %s - [ %s ]", idx, value.name, rollText))
	  		f:SetFontString(btnFS)
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

--TODO wrap these debug args in an object
function DebugMode(args)
	if args == nil or #args == 0 or args[0] ~= "debug" then
		return
	end

	if args[1] == "enable" then
		SetDebugMode(true)
		return
	elseif args[1] == "disable" then
		SetDebugMode(false)
		return
	end

	if not g_app.debug then
		return
	end

	if args[1] == "roll" then
		fakemsg = format("%s rolls %s (1-%s)", args[2], args[3], g_round.currentStakes)
		ParseRoll(fakemsg)
	elseif args[1] == "enter" then
		ParseChatMsg("1", args[2])
	elseif args[1] == "withdraw" then
		ParseChatMsg("-1", args[2])
	else
		WriteMsg("", "", "|cffffff00Invalid argument for command /gbc debug")
	end
end

function SetDebugMode(enable)
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
	
	self:RegisterForDrag("LeftButton");
    
	ResetGBCFrames()

	--DEFAULT to not show
	if not g_app.debug then
		ToggleRootFrame()
	end
end

function GBC_OnEvent(self, event, ...)
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

function GBC_Btn_RulesDisplay_OnClick()
	PrintRules()
end

function GBC_Btn_StatsDisplay_OnClick()
	PrintStats(false)
end

function GBC_Btn_StatsReset_OnClick()
	ResetStats()
end

function GBC_Btn_RoundNext_OnClick()
	NextPhase()
end

function GBC_Btn_ListRemaining_OnClick()
	ListRemainingPlayers()
end

function GBC_Btn_RoundReset_OnClick()
	ResetRound()
end

function GetVersionString()
	return g_app.version
end

function DisplayVersion()
	WriteMsg("","", format("GreybeardsCasino v%s", GetVersionString()))
end

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
	next = {
		cmd = "next",
		func = NextPhase,
		description = "Go to next phase of game round."
	},
	debug = {
		cmd = "debug",
		func = DebugMode,
		description = "Debug mode { on | off }"
	},
	version = {
		cmd = "version",
		func = DisplayVersion,
		description = "Display current addon version."
	}
}

function GBC_SlashCmd(msg)
	if (msg == "" or msg == nil) then
		WriteMsg("", "", "~Following commands for GreybeardsCasino~")

		for key,value in pairs(g_cmds) do
			WriteMsg("","", format("%s - %s", value.cmd, value.description))
		end
	end

	--split string
	args = {} 
	idx = 0
	for arg in string.gmatch(msg, "([^".." ".."]+)") do
		args[idx] = arg
		idx = idx + 1
	end

	if g_cmds[args[0]] ~= nil then
		g_cmds[args[0]].func(args)
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

