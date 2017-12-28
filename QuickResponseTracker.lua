require "Apollo"
require "Window"
 
local QuickResponseTracker = {}

--[[
function Find()
	local ret = {}
	for i = 1,99999 do
		local spl = GameLib.GetSpell(i)
		if (spl:GetName() == "Quick Response") then
			table.insert(ret, i)
		end
	end
	return ret
end

Quick Response IDs: { 56731, 61006, 61007 }
]]--

function QuickResponseTracker:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self

	self.QuickResponseSpellId = 61007
	self.QuickResponseSpell = GameLib.GetSpell(self.QuickResponseSpellId)

	self.ReadyPixieData = {
		cr = { a = 1.0, r = 1.0, b = 1.0, g = 1.0 },
		loc = { fPoints = {0.0, 0.0, 0.0, 0.0}, nOffsets = {15, 15, 65, 65} },
		strSprite = "CRB_Nameplates:sprNP_HighLevel" 
	}

	self.QuickResponseWasReady = true

	return o
end

function QuickResponseTracker:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {}

	Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

function QuickResponseTracker:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("QuickResponseTracker.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

function QuickResponseTracker:OnDocLoaded()
	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
		self.wndMain = Apollo.LoadForm(self.xmlDoc, "QuickResponseIcon", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
		self.wndMain:Show(false, true)
	
		self.xmlDoc = nil

		self.ReadyPixieId = self.wndMain:AddPixie(self.ReadyPixieData)
		
		Apollo.RegisterSlashCommand("qrt", "OnQuickResponseTrackerOn", self)

		Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
		self:OnWindowManagementReady()
		end
end

function QuickResponseTracker:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementRegister", 
		{
			wnd = self.wndMain,
			strName = "Quick Response Tracker",
			nSaveVersion = 1
		}
	)
	Event_FireGenericEvent("WindowManagementAdd", 
		{
			wnd = self.wndMain,
			strName = "Quick Response Tracker",
			nSaveVersion = 1
		}
	)
end

function QuickResponseTracker:OnNextFrame()
	local cooldown_remaining = self.QuickResponseSpell:GetCooldownRemaining()

	if (cooldown_remaining > 0) then
		self.wndMain:SetText(Apollo.FormatNumber(cooldown_remaining, 1, false))

		if self.QuickResponseWasReady then
			self.ReadyPixieData.cr.a = 0.0

			self.wndMain:UpdatePixie(self.ReadyPixieId, self.ReadyPixieData)

			self.QuickResponseWasReady = false
		end
	else
		self.wndMain:SetText("")

		if not self.QuickResponseWasReady then
			self.ReadyPixieData.cr.a = 1.0

			self.wndMain:UpdatePixie(self.ReadyPixieId, self.ReadyPixieData)

			self.QuickResponseWasReady = true						
		end
	end
end

function QuickResponseTracker:OnQuickResponseTrackerOn()
	if self.wndMain:IsShown() then
		self.wndMain:Show(false)

		Apollo.RemoveEventHandler("NextFrame", self)
	else
		Apollo.RegisterEventHandler("NextFrame", "OnNextFrame", self)

		self.wndMain:Show(true)
	end
end


local QuickResponseTrackerInst = QuickResponseTracker:new()
QuickResponseTrackerInst:Init()
