-- Improved Round End Menu for Event Handler Mode
-- With animated player names, unique patterns, and transparency

local PANEL = {}

-- Color definitions
local COLOR_ALIVE = Color(50, 180, 50, 255)      -- Green - Survived
local COLOR_DEAD = Color(100, 100, 100, 255)     -- Gray - Dead
local COLOR_WOUNDED = Color(80, 140, 80, 255)    -- Dark Green - Wounded
local COLOR_POLICE = Color(0, 100, 255, 255)     -- Blue - Police
local COLOR_KILLER = Color(255, 50, 50, 255)     -- Red - Killer/Murderer
local COLOR_CIVILIAN = Color(255, 100, 200, 255) -- Pink - Civilian
local COLOR_TEXT = Color(255, 255, 255, 255)     -- White text
local COLOR_SHADOW = Color(0, 0, 0, 150)         -- Black shadow
local COLOR_GRAY = Color(150, 150, 150, 255)     -- Gray text

-- Background blur
local blurMat = Material("pp/blurscreen")
BlurBackground = BlurBackground or hg.DrawBlur

-- 20 unique background patterns
local BACKGROUND_PATTERNS = {
	{type = "lines", angle = 0, spacing = 15},
	{type = "lines", angle = 45, spacing = 20},
	{type = "lines", angle = 90, spacing = 15},
	{type = "dots", size = 4, spacing = 20},
	{type = "dots", size = 6, spacing = 25},
	{type = "waves", amplitude = 10, frequency = 0.05},
	{type = "waves", amplitude = 15, frequency = 0.03},
	{type = "grid", spacing = 20},
	{type = "grid", spacing = 30},
	{type = "diagonal", angle = 45, spacing = 15},
	{type = "diagonal", angle = -45, spacing = 15},
	{type = "circles", radius = 8, spacing = 25},
	{type = "circles", radius = 12, spacing = 35},
	{type = "triangles", size = 10, spacing = 20},
	{type = "hex", size = 8, spacing = 20},
	{type = "crosshatch", spacing = 15},
	{type = "waves", amplitude = 20, frequency = 0.02},
	{type = "ripple", center_x = 0.5, center_y = 0.5},
	{type = "noise", scale = 0.1},
	{type = "zigzag", amplitude = 8, spacing = 20}
}

-- Function to draw animated patterns
local function DrawPattern(pattern, x, y, w, h, time, alpha)
	surface.SetDrawColor(255, 255, 255, alpha * 0.15)
	
	if pattern.type == "lines" then
		local spacing = pattern.spacing
		local angle_rad = math.rad(pattern.angle)
		for i = -h, w, spacing do
			surface.DrawLine(
				x + i * math.cos(angle_rad),
				y + i * math.sin(angle_rad),
				x + (i + w) * math.cos(angle_rad),
				y + (i + w) * math.sin(angle_rad)
			)
		end
	
	elseif pattern.type == "dots" then
		local spacing = pattern.spacing
		local size = pattern.size
		for py = y, y + h, spacing do
			for px = x, x + w, spacing do
				local offset = math.sin(time + (px + py) * 0.01) * 2
				surface.DrawRect(px + offset, py, size, size)
			end
		end
	
	elseif pattern.type == "waves" then
		local amp = pattern.amplitude
		local freq = pattern.frequency
		for px = x, x + w, 3 do
			local py = y + amp * math.sin((px - x) * freq + time)
			surface.DrawRect(px, py, 2, h)
		end
	
	elseif pattern.type == "grid" then
		local spacing = pattern.spacing
		for px = x, x + w, spacing do
			surface.DrawLine(px, y, px, y + h)
		end
		for py = y, y + h, spacing do
			surface.DrawLine(x, py, x + w, py)
		end
	
	elseif pattern.type == "diagonal" then
		local spacing = pattern.spacing
		local angle_rad = math.rad(pattern.angle)
		for i = -h - w, w + h, spacing do
			local x1 = x + i * math.cos(angle_rad)
			local y1 = y + i * math.sin(angle_rad)
			local x2 = x1 + h * math.cos(angle_rad + math.pi/2)
			local y2 = y1 + h * math.sin(angle_rad + math.pi/2)
			surface.DrawLine(x1, y1, x2, y2)
		end
	
	elseif pattern.type == "circles" then
		local spacing = pattern.spacing
		local radius = pattern.radius
		for py = y, y + h, spacing do
			for px = x, x + w, spacing do
				local offset = math.sin(time + (px + py) * 0.01) * 3
				draw.Circle(px + offset, py, radius, 255, 16)
			end
		end
	
	elseif pattern.type == "crosshatch" then
		local spacing = pattern.spacing
		for i = -h, w + h, spacing do
			-- Forward diagonal
			surface.DrawLine(x + i, y, x + i + h, y + h)
			-- Backward diagonal
			surface.DrawLine(x + i, y + h, x + i - h, y)
		end
	
	elseif pattern.type == "ripple" then
		local center_x = x + w * pattern.center_x
		local center_y = y + h * pattern.center_y
		for radius = 0, math.sqrt(w*w + h*h), 15 do
			local wave_effect = math.sin(time - radius * 0.1) * 0.5
			if math.abs(wave_effect) > 0.2 then
				draw.Circle(center_x, center_y, radius, math.abs(wave_effect) * 100, 32)
			end
		end
	
	elseif pattern.type == "noise" then
		for py = y, y + h, 4 do
			for px = x, x + w, 4 do
				local noise = math.random(0, 100)
				if noise > 70 then
					surface.DrawRect(px, py, 3, 3)
				end
			end
		end
	
	elseif pattern.type == "zigzag" then
		local amp = pattern.amplitude
		local spacing = pattern.spacing
		for px = x, x + w, spacing do
			local offset = amp * math.sin((px - x) * 0.05 + time)
			surface.DrawLine(px, y, px, y + h + offset)
		end
	end
end

function PANEL:Init()
	local sw, sh = ScrW(), ScrH()
	
	-- Window size and position (centered, wider than current)
	local panelWidth = sw * 0.55   -- 55% of screen width
	local panelHeight = sh * 0.75  -- 75% of screen height
	local panelX = (sw - panelWidth) / 2
	local panelY = (sh - panelHeight) / 2
	
	self:SetPos(panelX, panelY)
	self:SetSize(panelWidth, panelHeight)
	self:SetTitle("Round Results")
	self:MakePopup()
	self:SetKeyboardInputEnabled(false)
	self:ShowCloseButton(false)
	
	-- Close button
	local closeBtn = vgui.Create("DButton", self)
	closeBtn:SetPos(panelWidth - 35, 5)
	closeBtn:SetSize(30, 30)
	closeBtn:SetText("✕")
	closeBtn:SetFont("ZB_InterfaceMedium")
	closeBtn.DoClick = function()
		self:Close()
	end
	
	-- Scroll panel for players
	local scroll = vgui.Create("DScrollPanel", self)
	scroll:SetPos(10, 100)
	scroll:SetSize(panelWidth - 20, panelHeight - 110)
	
	-- Customize scrollbar
	local vbar = scroll:GetVBar()
	vbar:SetWide(8)
	vbar.Paint = function(self, w, h)
		surface.SetDrawColor(80, 80, 80, 100)
		surface.DrawRect(0, 0, w, h)
	end
	vbar.btnGrip.Paint = function(self, w, h)
		surface.SetDrawColor(150, 150, 150, 200)
		surface.DrawRect(0, 0, w, h)
	end
	
	-- Store reference to scroll panel
	self.ScrollPanel = scroll
	self.PlayerIndex = 0
	
	-- Paint function
	function self:Paint(w, h)
		BlurBackground(self)
		
		-- Background with transparency
		surface.SetDrawColor(30, 30, 40, 200)  -- Slightly transparent
		surface.DrawRect(0, 0, w, h)
		
		-- Border
		surface.SetDrawColor(100, 100, 150, 255)
		surface.DrawOutlinedRect(0, 0, w, h, 2)
		
		-- Title bar
		surface.SetDrawColor(50, 50, 70, 200)  -- Transparent title bar
		surface.DrawRect(0, 0, w, 90)
		
		-- Winner text
		if self.WinnerName then
			surface.SetFont("ZB_InterfaceLarge")
			surface.SetTextColor(255, 215, 0, 255)  -- Gold
			local text = self.WinnerName .. " Won!"
			local textW, textH = surface.GetTextSize(text)
			surface.SetTextPos((w - textW) / 2, 15)
			surface.DrawText(text)
		end
		
		-- Mode text
		if self.ModeName then
			surface.SetFont("ZB_InterfaceMedium")
			surface.SetTextColor(200, 200, 200, 255)
			local text = "Mode: " .. self.ModeName
			local textW, textH = surface.GetTextSize(text)
			surface.SetTextPos((w - textW) / 2, 50)
			surface.DrawText(text)
		end
	end
end

function PANEL:SetWinner(winnerName, modeName)
	self.WinnerName = winnerName or "Nobody"
	self.ModeName = modeName or "Unknown Mode"
end

function PANEL:AddPlayer(ply, role, isAlive, isWounded)
	if not IsValid(self.ScrollPanel) then return end
	
	self.PlayerIndex = (self.PlayerIndex or 0) + 1
	local patternIndex = ((self.PlayerIndex - 1) % 20) + 1
	local pattern = BACKGROUND_PATTERNS[patternIndex]
	
	local playerPanel = vgui.Create("DPanel", self.ScrollPanel)
	playerPanel:SetSize(self.ScrollPanel:GetWide() - 15, 90)
	playerPanel:Dock(TOP)
	playerPanel:DockMargin(5, 5, 5, 5)
	
	-- Store player data
	playerPanel.ply = ply
	playerPanel.role = role
	playerPanel.isAlive = isAlive
	playerPanel.isWounded = isWounded
	playerPanel.pattern = pattern
	playerPanel.createdTime = CurTime()
	
	-- Determine role color
	local roleColor = COLOR_CIVILIAN
	if string.lower(role):find("police") or string.lower(role):find("cop") then
		roleColor = COLOR_POLICE
	elseif string.lower(role):find("kill") or string.lower(role):find("murder") then
		roleColor = COLOR_KILLER
	elseif string.lower(role):find("civil") or string.lower(role):find("peace") then
		roleColor = COLOR_CIVILIAN
	end
	playerPanel.roleColor = roleColor
	
	-- Determine status color
	local statusColor = COLOR_DEAD
	if isAlive then
		statusColor = isWounded and COLOR_WOUNDED or COLOR_ALIVE
	end
	playerPanel.statusColor = statusColor
	
	-- Paint function with animated background and name
	function playerPanel:Paint(w, h)
		-- Background based on status with transparency
		surface.SetDrawColor(statusColor.r, statusColor.g, statusColor.b, 60)  -- More transparent
		surface.DrawRect(0, 0, w, h)
		
		-- Draw unique pattern background
		DrawPattern(pattern, 0, 0, w, h, CurTime() - self.createdTime, 180)
		
		-- Border
		surface.SetDrawColor(statusColor.r, statusColor.g, statusColor.b, 200)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		
		-- Status indicator bar on the right
		local barWidth = 25
		surface.SetDrawColor(statusColor.r, statusColor.g, statusColor.b, 200)
		surface.DrawRect(w - barWidth, 0, barWidth, h)
		
		-- Status text
		local statusText = isAlive and (isWounded and "WOUNDED" or "ALIVE") or "DEAD"
		surface.SetFont("ZB_InterfaceSmall")
		surface.SetTextColor(255, 255, 255, 200)
		local textW, textH = surface.GetTextSize(statusText)
		surface.SetTextPos(w - barWidth + (barWidth - textW) / 2, h / 2 - textH / 2)
		surface.DrawText(statusText)
		
		-- Role line indicator at the top (animated pulse)
		local pulse = math.sin(CurTime() * 2) * 0.3 + 0.7
		surface.SetDrawColor(roleColor.r, roleColor.g, roleColor.b, 255 * pulse)
		surface.DrawRect(0, 0, w - barWidth, 3)
	end
	
	-- Avatar/Steam icon (clickable)
	local avatar = vgui.Create("DButton", playerPanel)
	avatar:SetPos(10, 10)
	avatar:SetSize(50, 50)
	avatar:SetText("")
	avatar.ply = ply
	avatar.DoClick = function()
		if IsValid(ply) and not ply:IsBot() then
			gui.OpenURL("https://steamcommunity.com/profiles/" .. ply:SteamID64())
		end
	end
	avatar.Paint = function(self, w, h)
		-- Avatar background
		surface.SetDrawColor(50, 50, 60, 200)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(100, 100, 120, 255)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		
		-- Player avatar
		if IsValid(ply) then
			surface.SetMaterial(ply:GetAvatarMaterial("medium"))
			surface.SetDrawColor(255, 255, 255, 255)
			surface.DrawTexturedRect(2, 2, w - 4, h - 4)
		end
		
		-- Hover effect
		if self:IsHovered() then
			surface.SetDrawColor(150, 150, 200, 100)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(150, 150, 200, 255)
			surface.DrawOutlinedRect(0, 0, w, h, 2)
		end
	end
	
	-- Player name with animated color transition (white -> gray)
	local nameLabel = vgui.Create("DLabel", playerPanel)
	nameLabel:SetPos(70, 10)
	nameLabel:SetSize(200, 25)
	nameLabel:SetText(ply:GetPlayerName())
	nameLabel:SetFont("ZB_InterfaceMedium")
	
	-- Custom paint for animated name color
	function nameLabel:Paint(w, h)
		-- Smooth color transition: white to gray and back
		local t = (CurTime() - playerPanel.createdTime) * 0.5  -- Speed of transition
		local wave = math.sin(t) * 0.5 + 0.5  -- 0 to 1
		
		-- Interpolate between white and gray
		local r = math.Lerp(wave, 255, 150)
		local g = math.Lerp(wave, 255, 150)
		local b = math.Lerp(wave, 255, 150)
		
		surface.SetFont(self:GetFont())
		surface.SetTextColor(r, g, b, 255)
		local textW, textH = surface.GetTextSize(self:GetText())
		surface.SetTextPos((w - textW) / 2, (h - textH) / 2)
		surface.DrawText(self:GetText())
	end
	
	-- Frags display
	local fragsLabel = vgui.Create("DLabel", playerPanel)
	fragsLabel:SetPos(playerPanel:GetWide() - 80, 10)
	fragsLabel:SetSize(70, 25)
	fragsLabel:SetText("Frags: " .. (ply:Frags() or 0))
	fragsLabel:SetFont("ZB_InterfaceSmall")
	fragsLabel:SetTextColor(255, 200, 100, 255)
	fragsLabel:SetContentAlignment(TEXT_ALIGN_RIGHT)
	
	-- Role display with colored indicator
	local roleLabel = vgui.Create("DLabel", playerPanel)
	roleLabel:SetPos(70, 40)
	roleLabel:SetSize(200, 20)
	roleLabel:SetText(role)
	roleLabel:SetFont("ZB_InterfaceSmall")
	roleLabel:SetTextColor(roleColor.r, roleColor.g, roleColor.b, 255)
	
	-- Deaths display
	local deathsLabel = vgui.Create("DLabel", playerPanel)
	deathsLabel:SetPos(playerPanel:GetWide() - 80, 40)
	deathsLabel:SetSize(70, 20)
	deathsLabel:SetText("Deaths: " .. (ply:Deaths() or 0))
	deathsLabel:SetFont("ZB_InterfaceSmall")
	deathsLabel:SetTextColor(200, 100, 100, 255)
	deathsLabel:SetContentAlignment(TEXT_ALIGN_RIGHT)
	
	-- Steam ID display
	local steamLabel = vgui.Create("DLabel", playerPanel)
	steamLabel:SetPos(70, 60)
	steamLabel:SetSize(playerPanel:GetWide() - 90, 20)
	steamLabel:SetText("ID: " .. ply:SteamID())
	steamLabel:SetFont("ZB_InterfaceTiny")
	steamLabel:SetTextColor(150, 150, 150, 200)
end

function PANEL:PopulateFromGame()
	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end
		
		local role = "Civilian"
		local isAlive = ply:Alive()
		local isWounded = false
		
		-- Try to detect role (example for common gamemodes)
		if ply:GetNetVar("Role") then
			role = ply:GetNetVar("Role")
		elseif ply:GetTeam() == 1 then
			role = "Police"
		elseif ply:GetTeam() == 2 then
			role = "Killer"
		end
		
		-- Check if wounded
		if ply.organism and ply.organism.incapacitated then
			isWounded = true
		end
		
		self:AddPlayer(ply, role, isAlive, isWounded)
	end
end

function PANEL:Close()
	self:AlphaTo(0, 0.2, 0, function()
		self:Remove()
	end)
end

vgui.Register("ZB_RoundEndPanel", PANEL, "ZFrame")

-- Initialize and show the panel
function OpenRoundEndMenu(winnerName, modeName)
	if IsValid(zb.RoundEndPanel) then
		zb.RoundEndPanel:Remove()
	end
	
	zb.RoundEndPanel = vgui.Create("ZB_RoundEndPanel")
	zb.RoundEndPanel:SetWinner(winnerName or "Nobody", modeName or "Event")
	zb.RoundEndPanel:PopulateFromGame()
	
	return zb.RoundEndPanel
end
