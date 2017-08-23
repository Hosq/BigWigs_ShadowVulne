assert( BigWigs, "BigWigs not found!")

-----------------------------------------------------------------------
--      Are you local?
-----------------------------------------------------------------------
local name = "ShadowVulne"
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..name)

local timer = {
	vulne = 15,
}

-----------------------------------------------------------------------
--      Localization
-----------------------------------------------------------------------

L:RegisterTranslations("enUS", function() return {
	["Enable"] = true,
	["Enable timers."] = true,
	["ShadowVulne"] = true,
	["Gives timer for Shadow Vulnerability."] = true,
	["Target only"] = true,
	["Only show timer for the current target."] = true,
	["Show anchor"] = true,
	["Show the bar anchor frame."] = true,

	shadowvuln_test = "^(.+) is afflicted by Shadow Vulnerability.",
	swpResist_test	= "^Your Shadow Word: Pain was resisted by (.+).",
	mindblast_test = "^Your Mind Blast (%a%a?)\its (.+) for",
	vulneResist_test = "^Your Shadow Vulnerability was resisted by (.+).",
	mindflay_test = "^Your Mind Flay was resisted by (.+).",

} end)

-----------------------------------------------------------------------
--      Module Declaration
-----------------------------------------------------------------------
BigWigsShadowVulne = BigWigs:NewModule(name)
BigWigsShadowVulne.defaultDB = {
	enable = true,
	currentonly = true,
}

BigWigsShadowVulne.consoleCmd = L["ShadowVulne"]
BigWigsShadowVulne.consoleOptions = {
	type = "group",
	name = L["ShadowVulne"],
	desc = L["Gives timer for Shadow Vulnerability."],
	args   = {
		enable = {
			type = "toggle",
			name = L["Enable"],
			desc = L["Enable timers."],
			order = 1,
			get = function() return BigWigsShadowVulne.db.profile.enable end,
			set = function(v) BigWigsShadowVulne.db.profile.enable = v end,
		},
		currentonly = {
			type = "toggle",
			name = L["Target only"],
			desc = L["Only show timer for the current target."],
			order = 2,
			get = function() return BigWigsShadowVulne.db.profile.currentonly end,
			set = function(v) BigWigsShadowVulne.db.profile.currentonly = v end,
		},
		spacer = {
			type = "header",
			name = " ",
			order = 4,
		},
		anchor = {
			type = "execute",
			name = L["Show anchor"],
			desc = L["Show the bar anchor frame."],
			order = 5,
			func = function() BigWigsScorchTimer:ShowAnchors() end,
		},
	},
}

BigWigsShadowVulne.revision = 20001
BigWigsShadowVulne.external = true

BigWigsShadowVulne.target = nil
BigWigsShadowVulne.lastResist = GetTime()
BigWigsShadowVulne.lastVictim = nil
BigWigsShadowVulne.debuffs = {}
-----------------------------------------------------------------------
--      Initialization
-----------------------------------------------------------------------

function BigWigsShadowVulne:OnEnable()
	self:RegisterEvent("SpellStatus_SpellCastInstant")
	self:RegisterEvent("SpellStatus_SpellCastChannelingStart")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE", "PlayerDamageEvents")
	self:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE", "PlayerDamageEvents")
	self:RegisterEvent("CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF", "PlayerDamageEvents")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
end

-----------------------------------------------------------------------
--      Event Handlers
-----------------------------------------------------------------------
function BigWigsShadowVulne:SpellStatus_SpellCastChannelingStart(sId, sName, sRank, sFullName, sCastTime)
	if self.db.profile.enable then
		if sName == "Mind Flay" then
			local tmpTime = GetTime()-self.lastResist
			if tmpTime > 0.1 then
				self.lastVictim = UnitName("target");
				self:ScheduleEvent("ShadowVulneDelayedBar", self.DelayedBar, 0.2, self)
				--self:DebugMessage("Mind Flay - ".. self.lastVictim.." "..GetTime())
			end
		end
	end
end

function BigWigsShadowVulne:SpellStatus_SpellCastInstant(sId, sName, sRank, sFullName, sCastTime)
	if self.db.profile.enable then
		if sName == "Shadow Word: Pain" then
			local tmpTime = GetTime()-self.lastResist
			if tmpTime > 0.1 then
				self.lastVictim = UnitName("target");
				self:ScheduleEvent("ShadowVulneDelayedBar", self.DelayedBar, 0.2, self)
				--self:DebugMessage("Mind Flay - ".. self.lastVictim.." "..GetTime())
			end
		end
	end
end

function BigWigsShadowVulne:PlayerDamageEvents(msg)
	if self.db.profile.enable then
		--local start, ending, victim = string.find(msg, L["shadowvuln_test"])
		--if victim and UnitName("target") == victim then
		--self:DebugMessage("Shadow vulne - ".. victim)
		--	self.debuffs[victim] = GetTime()
		--	BigWigsScorchTimer:StartBar(victim, timer.vulne, "Interface\\Icons\\Spell_Shadow_BlackPlague")
		--end

		local start, ending, _, victim = string.find(msg, L["mindblast_test"])
		if victim then
			--self:DebugMessage("MindBlast - ".. victim)
			self.lastVictim = victim
			self:ScheduleEvent("ShadowVulneDelayedBar", self.DelayedBar, 0.2, self)
		end

		local start, ending, victim = string.find(msg, L["vulneResist_test"])
		if victim then
			--self:DebugMessage("Shadow vulne resist - ".. victim.." "..GetTime())
			self.lastResist = GetTime()
			self:CancelScheduledEvent("ShadowVulneDelayedBar")
		end

		local start, ending, victim = string.find(msg, L["swpResist_test"])
		if victim then
			--self:DebugMessage("swp resist - ".. victim.." "..GetTime())
			self.lastResist = GetTime()
			self:CancelScheduledEvent("ShadowVulneDelayedBar")
		end

		local start, ending, victim = string.find(msg, L["mindflay_test"])
		if victim then
			--self:DebugMessage("mindflay resist - ".. victim.." "..GetTime())
			self.lastResist = GetTime()
			self:CancelScheduledEvent("ShadowVulneDelayedBar")
		end

	end
end

function BigWigsShadowVulne:DelayedBar()
	self.debuffs[self.lastVictim] = GetTime()-0.2
	BigWigsScorchTimer:StartBar(self.lastVictim, timer.vulne-0.2, "Interface\\Icons\\Spell_Shadow_BlackPlague")
end

function BigWigsShadowVulne:PLAYER_REGEN_ENABLED()
	self.target = nil
	BigWigsScorchTimer:StopAllBars()
	self.debuffs = {}
end

function BigWigsShadowVulne:RecheckTargetChange()
	local target = UnitName("target")
	if target ~= self.target then
		if self.db.profile.currentonly then
			BigWigsScorchTimer:StopAllBars()
		end
		self.target = target
		local victim, timeleft = self:GetTargetInfo()
		if victim and timeleft and self.db.profile.enable then
			BigWigsScorchTimer:StartBar(victim, timeleft, "Interface\\Icons\\Spell_Shadow_BlackPlague")
		end
	end
end
-- reset data if you change your target
function BigWigsShadowVulne:PLAYER_TARGET_CHANGED(msg)
	if not self:IsEventScheduled("ShadowVulneReckeckTargetChange") then
		self:ScheduleEvent("ShadowVulneReckeckTargetChange", self.RecheckTargetChange, 0.1, self)
	end
end

-----------------------------------------------------------------------
--      Util
-----------------------------------------------------------------------
function BigWigsShadowVulne:GetTargetInfo()
	for k, v in pairs(self.debuffs) do
		if k == self.target then
			local timeleft = timer.vulne-(GetTime() - v)
			if timeleft > 0 then
				return k, timeleft
			end
		end
	end
	return false
end
