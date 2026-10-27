zb = zb or {}
include("shared.lua")
include("loader.lua")

if not ConVarExists("hg_newspectate") then
    CreateClientConVar("hg_newspectate", "1", true, false, "Enables smooth spectator camera transitions", 0, 1)
end

function CurrentRound()
	return zb.modes[zb.CROUND]
end

zb.ROUND_STATE = 0
--0 = players can join, 1 = round is active, 2 = endround
local vecZero = Vector(0.2, 0.2, 0.2)
local vecFull = Vector(1, 1, 1)
spect,prevspect,viewmode = nil,nil,1
local hullscale = Vector(0,0,0)
net.Receive("ZB_SpectatePlayer", function(len)
	spect = net.ReadEntity()
	prevspect = net.ReadEntity()
	viewmode = net.ReadInt(4)

	timer.Simple(0.1,function()
		-- LocalPlayer():BoneScaleChange()
		LocalPlayer():SetHull(-hullscale,hullscale)
		LocalPlayer():SetHullDuck(-hullscale,hullscale)

		if viewmode == 3 then
			LocalPlayer():SetMoveType(MOVETYPE_NOCLIP)
		end
	end)
end)

zb.ROUND_TIME = zb.ROUND_TIME or 400
zb.ROUND_START = zb.ROUND_START or CurTime()
zb.ROUND_BEGIN = zb.ROUND_BEGIN or CurTime() + 5

net.Receive("updtime",function()
	local time = net.ReadFloat()
	local time2 = net.ReadFloat()
	local time3 = net.ReadFloat()

	zb.ROUND_TIME = time
	zb.ROUND_START = time2
	zb.ROUND_BEGIN = time3
end)

local blur = Material("pp/blurscreen")
local blur2 = Material("effects/shaders/zb_blur" )
local blursettings = {}
local hg_potatopc
hg = hg or {}
function hg.DrawBlur(panel, amount, passes, alpha)
	if is3d2d then return end
	amount = amount or 5
	hg_potatopc = hg_potatopc or hg.ConVars.potatopc

	// old blur
	if(hg_potatopc:GetBool())then
		surface.SetDrawColor(0, 0, 0, alpha or (amount * 20))
		surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())
	else
		surface.SetMaterial(blur)
		surface.SetDrawColor(0, 0, 0, alpha or 125)
		surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())
		local x, y = panel:LocalToScreen(0, 0)
		if blursettings and blursettings[1] == amount and blursettings[2] == passes then
			render.UpdateScreenEffectTexture()
			surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
			return
		end
		blursettings = {amount, passes}
		for i = -(passes or 0.2), 1, 0.2 do
			blur:SetFloat("$blur", i * amount)
			blur:Recompute()

			render.UpdateScreenEffectTexture()
			surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
		end
	end

	--surface.SetMaterial(blur2)
	--surface.SetDrawColor(color_white)
	--local x, y = panel:LocalToScreen(0, 0)
--
	--// those are currently hardcoded cuz it would be too much of a hassle to change this
	--blur2:SetFloat("$c0_x", (amount or 5) * 2500) // density
	--blur2:SetFloat("$c0_y", (passes or 0.2) * 2000) // noise (inverted)
	--blur2:SetFloat("$c0_z", 1) // blending
--
	--render.UpdateScreenEffectTexture()
	--surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())

	-- surface.SetDrawColor(0, 0, 0, alpha or 125)
	-- surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())
end

BlurBackground = BlurBackground or hg.DrawBlur

local keydownattack
local keydownattack2
local keydownreload

hook.Add("HUDPaint","FUCKINGSAMENAMEUSEDINHOOKFUCKME",function()
    if LocalPlayer():Alive() then return end
	local spect = LocalPlayer():GetNWEntity("spect")
	if not IsValid(spect) then return end
	if viewmode == 3 then return end
	
	surface.SetFont("HomigradFont")
	surface.SetTextColor(255, 255, 255, 255)
	local txt = "Spectating player: "..spect:Name()
	local w, h = surface.GetTextSize(txt)
	surface.SetTextPos(ScrW() / 2 - w / 2, ScrH() / 8 * 7)
	surface.DrawText(txt)
	local txt = "In-game name: "..spect:GetPlayerName()
	local w, h = surface.GetTextSize(txt)
	surface.SetTextPos(ScrW() / 2 - w / 2, ScrH() / 8 * 7 + h)
	surface.DrawText(txt)
end)

hook.Add("HG_CalcView", "zzzzzzzUwU", function(ply, pos, angles, fov)
	if not lply:Alive() then
		if lply:KeyDown(IN_ATTACK) then
			if not keydownattack then
				keydownattack = true
				net.Start("ZB_ChooseSpecPly")
				net.WriteInt(IN_ATTACK,32)
				net.SendToServer()
			end
		else
			keydownattack = false
		end

		if lply:KeyDown(IN_ATTACK2) then
			if not keydownattack2 then
				keydownattack2 = true
				net.Start("ZB_ChooseSpecPly")
				net.WriteInt(IN_ATTACK2,32)
				net.SendToServer()
			end
		else
			keydownattack2 = false
		end

		if lply:KeyDown(IN_RELOAD) then
			if not keydownreload then
				keydownreload = true
				net.Start("ZB_ChooseSpecPly")
				net.WriteInt(IN_RELOAD,32)
				net.SendToServer()
			end
		else
			keydownreload = false
		end

		local spect = lply:GetNWEntity("spect",spect)
		if not IsValid(spect) then return end

		local viewmode = lply:GetNWInt("viewmode",viewmode)
		
		if viewmode == 3 then
			if lply:GetMoveType()!=MOVETYPE_NOCLIP then
				lply:SetMoveType(MOVETYPE_NOCLIP)
			end
			lply:SetObserverMode(OBS_MODE_ROAMING)
			return
		else
			lply:SetPos(spect:GetPos())
		end
		
		local ent = hg.GetCurrentCharacter(spect)
		if not IsValid(ent) then return end
		
		local headBone = ent:LookupBone("ValveBiped.Bip01_Head1") or ent:LookupBone("ValveBiped.Bip01_Spine1") or 1
		local bon = ent:GetBoneMatrix(headBone)
		
		if not bon then 
			local eyePos = ent:EyePos()
			if eyePos and eyePos ~= vector_origin then
				pos = eyePos
				ang = ent:EyeAngles()
			else
				pos = ent:GetPos() + Vector(0, 0, 64)
				ang = ent:GetAngles()
			end
		else
			pos, ang = bon:GetTranslation(), bon:GetAngles()
		end

		local eyePos, eyeAng = lply:EyePos(), lply:EyeAngles()
		
		local tr = {}
		tr.start = pos
		tr.endpos = pos + eyeAng:Forward() * -120
		tr.filter = {ent, lply, spect}
		tr.mins = Vector(-4, -4, -4)
		tr.maxs = Vector(4, 4, 4)
		tr = util.TraceHull(tr)

		if viewmode == 2 then
			pos = tr.HitPos + eyeAng:Forward() * 8
			ang = eyeAng
		elseif viewmode == 1 then
			if ent ~= spect and IsValid(ent) then
				local eyeAtt = ent:GetAttachment(ent:LookupAttachment("eyes"))
				if eyeAtt then
					ang = eyeAtt.Ang
				else
					ang = spect:EyeAngles()
				end
			else
				ang = spect:EyeAngles()
			end
			pos = pos + spect:EyeAngles():Forward() * 8
		else
			pos = eyePos
			ang = eyeAng
		end
		
		ang[3] = 0
		
		local view
		local hg_newspectate = GetConVar("hg_newspectate")
		if hg_newspectate and hg_newspectate:GetBool() then
			if not lply.spectLastPos then
				lply.spectLastPos = pos
				lply.spectLastAng = ang
			end
			
			local lerpFactor = FrameTime() * 10
			lply.spectLastPos = LerpVector(lerpFactor, lply.spectLastPos, pos)
			lply.spectLastAng = LerpAngle(lerpFactor, lply.spectLastAng, ang)

			view = {
				origin = lply.spectLastPos,
				angles = lply.spectLastAng,
				fov = fov,
			}
		else
			view = {
				origin = pos,
				angles = ang,
				fov = fov,
			}
		end

		return view
	else
		lply.spectLastPos = nil
		lply.spectLastAng = nil
		lply:SetObserverMode(OBS_MODE_NONE)
	end
end)

zb.fade = zb.fade or 0

hook.Add("RenderScreenspaceEffects", "huyhuyUwU", function()
	if zb.fade > 0 then
		zb.fade = math.Approach(zb.fade, 0, FrameTime() * 1)

		surface.SetDrawColor(0, 0, 0, 255 * math.min(zb.fade, 1))
		surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1 )
	end
end)

zb.ROUND_STATE = 0
net.Receive("RoundInfo", function()
	local rnd = net.ReadString()
	
	hook.Run("RoundInfoCalled", rnd)

	if zb.CROUND ~= rnd then
		if hg.DynaMusic then
			hg.DynaMusic:Stop()
		end
	end

	zb.CROUND = rnd

	zb.ROUND_STATE = net.ReadInt(4)
	
	if zb.ROUND_STATE == 0 then
		zb.fade = 7
	end

	if zb.CROUND ~= "" then
		if CurrentRound() then
			if zb.ROUND_STATE == 3 then
				if CurrentRound().EndRound then
					CurrentRound():EndRound()
				end
			elseif zb.ROUND_STATE == 1 then
				if CurrentRound().RoundStart then
					CurrentRound():RoundStart()
				end
			end
		end
	end
end)

if IsValid(scoreBoardMenu) then
	scoreBoardMenu:Remove()
	scoreBoardMenu = nil
end

hook.Add("Player Disconnected","retrymenu",function(data)
	if IsValid(scoreBoardMenu) then
		scoreBoardMenu:Remove()
		scoreBoardMenu = nil
	end
end)

--local hg_coolvetica = ConVarExists("hg_coolvetica") and GetConVar("hg_coolvetica") or CreateClientConVar("hg_coolvetica", "0", true, false, "changes every text to coolvetica because its good", 0, 1)
local hg_font = ConVarExists("hg_font") and GetConVar("hg_font") or CreateClientConVar("hg_font", "Bahnschrift", true, false, "Change UI text font")
local font = function() -- hg_coolvetica:GetBool() and "Coolvetica" or "Bahnschrift"
    local usefont = "Bahnschrift"

    if hg_font:GetString() != "" then
        usefont = hg_font:GetString()
    end

    return usefont
end

surface.CreateFont("ZB_InterfaceSmall", {
    font = font(),
    size = ScreenScale(6),
    weight = 400,
    antialias = true,
	extended = true
})

surface.CreateFont("ZB_InterfaceMedium", {
    font = font(),
    size = ScreenScale(10),
    weight = 400,
    antialias = true,
	extended = true
})

surface.CreateFont("ZB_ScrappersMedium", {
    font = font(),
    size = ScreenScale(10),
    weight = 400,
    antialias = true,
	extended = true
})

surface.CreateFont("ZB_InterfaceMediumLarge", {
    font = font(),
    size = 35,
    weight = 400,
    antialias = true,
	extended = true
})

surface.CreateFont("ZB_InterfaceLarge", {
    font = font(),
    size = ScreenScale(20),
    weight = 400,
    antialias = true,
	extended = true
})

surface.CreateFont("ZB_InterfaceHumongous", {
    font = font(),
    size = 200,
    weight = 400,
    antialias = true,
	extended = true
})

hg.playerInfo = hg.playerInfo or {}

local function addToPlayerInfo(ply, muted, volume)
	hg.playerInfo[ply:SteamID()] = {muted and true or false, volume}

	local json = util.TableToJSON(hg.playerInfo)
	file.Write("zcity_muted.txt", json)

	if file.Exists("zcity_muted.txt", "DATA") then
		local json = file.Read("zcity_muted.txt", "DATA")

		if json then
			hg.playerInfo = util.JSONToTable(json)
		end
	end

	//PrintTable(hg.playerInfo)
end

gameevent.Listen("player_connect")
hook.Add("player_connect", "zcityhuy", function(data)
	local ply = Player(data.userid)
	if IsValid(ply) and ply.SetMuted and hg.playerInfo and hg.playerInfo[data.networkid] then
		ply:SetMuted(hg.playerInfo[data.networkid][1])
		ply:SetVoiceVolumeScale(hg.playerInfo[data.networkid][2])
	end
end)

hook.Add("InitPostEntity", "furryhuy", function()
	if file.Exists("zcity_muted.txt", "DATA") then
		local json = file.Read("zcity_muted.txt", "DATA")

		if json then
			hg.playerInfo = util.JSONToTable(json)
		end

		if hg.playerInfo then
			for i, ply in player.Iterator() do
				if not istable(hg.playerInfo[ply:SteamID()]) then
					local muted = hg.playerInfo[ply:SteamID()]
					hg.playerInfo[ply:SteamID()] = {}
					hg.playerInfo[ply:SteamID()][1] = muted
					hg.playerInfo[ply:SteamID()][2] = 1
				end//compatibility with old json

				if hg.playerInfo[ply:SteamID()] then
					ply:SetMuted(hg.playerInfo[ply:SteamID()][1])
					ply:SetVoiceVolumeScale(hg.playerInfo[ply:SteamID()][2])
				end
			end	
		end
	end
end)

local colGray = Color(122,122,122,255)
local colBlue = Color(130,10,10)
local colBlueUp = Color(160,30,30)
local col = Color(255,255,255,255)

local colSpect1 = Color(75,75,75,255)
local colSpect2 = Color(85,85,85,255)

local colorBG = Color(55,55,55,255)
local colorBGBlacky = Color(40,40,40,255)

hg.muteall = false
hg.mutespect = false

local function OpenPlayerSoundSettings(selfa, ply)
	local Menu = DermaMenu()
	
	if not hg.playerInfo[ply:SteamID()] or not istable(hg.playerInfo[ply:SteamID()]) then addToPlayerInfo(ply, false, 1) end

	local mute = Menu:AddOption( "Mute", function(self)
		if hg.muteall || hg.mutespect then return end
		
		self:SetChecked(not ply:IsMuted())
		ply:SetMuted( not ply:IsMuted() )
		selfa:SetImage(not ply:IsMuted() && "icon16/sound.png" || "icon16/sound_mute.png")
		addToPlayerInfo(ply, ply:IsMuted(), hg.playerInfo[ply:SteamID()][2])
	end ) -- get your stupid one line ass outta here

	mute:SetIsCheckable( true )
	mute:SetChecked( ply:IsMuted() )
	local volumeSlider = vgui.Create("DSlider", Menu)
	volumeSlider:SetLockY( 0.5 )
	volumeSlider:SetTrapInside( true )
	volumeSlider:SetSlideX(hg.playerInfo[ply:SteamID()][2]) 
	volumeSlider.OnValueChanged = function(self, x, y)
		if not IsValid(ply) then return end
		if hg.muteall or (hg.mutespect && !ply:Alive()) then return end
		hg.playerInfo[ply:SteamID()][2] = x
		ply:SetVoiceVolumeScale(hg.playerInfo[ply:SteamID()][2])
		addToPlayerInfo(ply, ply:IsMuted(), hg.playerInfo[ply:SteamID()][2])
	end

	function volumeSlider:Paint(w,h)
		draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0 ) )
		draw.RoundedBox( 0, 0, 0, w*self:GetSlideX(), h, Color( 255, 0, 0 ) )
		draw.DrawText( ( math.Round( 100*self:GetSlideX(), 0 ) ).."%", "DermaDefault", w/2, h/4, color_white, TEXT_ALIGN_CENTER )
	end
	function volumeSlider.Knob.Paint(self) end

	Menu:AddPanel(volumeSlider)
	Menu:Open()
end



hook.Add("Player Getup", "nomorespect", function(ply)
	if not hg.mutespect then return end

	//ply:SetMuted(ply.oldmutedspect)
	ply:SetVoiceVolumeScale(!hg.muteall and (hg.playerInfo[ply:SteamID()] and hg.playerInfo[ply:SteamID()][2] or 1) or 0)
	//ply.oldmutedspect = nil

	//if IsValid(ply.soundButton) then
		//ply.soundButton:SetImage(not ply:IsMuted() && "icon16/sound.png" || "icon16/sound_mute.png")
	//end
end)

hook.Add("Player_Death", "fixSpectatorVoiceMute", function(ply)
	if not hg.mutespect then return end

	//ply.oldmutedspect = ply:IsMuted()
	//ply:SetMuted(hg.mutespect)
	ply:SetVoiceVolumeScale(0)
	//if IsValid(ply.soundButton) then
		//ply.soundButton:SetImage(not ply:IsMuted() && "icon16/sound.png" || "icon16/sound_mute.png")
	//end
end)

hook.Add("Player_Death", "fixSpectatorVoiceEffect", function(ply)
	if eightbit and eightbit.EnableEffect and ply.UserID then
		eightbit.EnableEffect(ply:UserID(), 0)
	end
end)

-- LZ-City TAB / Scoreboard replacement
-- Replace the block in gamemode/cl_init.lua starting at:
-- local SCOREBOARD_PINK = Color(...)
-- and ending after function GM:ScoreboardHide().
-- Keep all code before and after that block unchanged.

local SCOREBOARD_PINK = Color(200, 142, 155) -- #C88E9B
local SCOREBOARD_WHITE = Color(245, 242, 243)
local SCOREBOARD_GRAY = Color(177, 164, 167)
local SCOREBOARD_DARK = Color(41, 41, 41) -- #292929
local SCOREBOARD_PANEL = Color(33, 33, 33, 245)
local SCOREBOARD_PANEL_HOVER = Color(58, 47, 50, 248)

local function ScoreboardAnimatedColor(offset, speed)
    speed = speed or 1
    local progress = (math.sin(CurTime() * speed + offset) + 1) * 0.5

    return Color(
        Lerp(progress, SCOREBOARD_GRAY.r, SCOREBOARD_PINK.r),
        Lerp(progress, SCOREBOARD_GRAY.g, SCOREBOARD_PINK.g),
        Lerp(progress, SCOREBOARD_GRAY.b, SCOREBOARD_PINK.b),
        255
    )
end

local function ScoreboardOutlineColor(offset)
    local progress = (math.sin(CurTime() * 1.8 + offset) + 1) * 0.5

    return Color(
        Lerp(progress, SCOREBOARD_DARK.r, SCOREBOARD_PINK.r),
        Lerp(progress, SCOREBOARD_DARK.g, SCOREBOARD_PINK.g),
        Lerp(progress, SCOREBOARD_DARK.b, SCOREBOARD_PINK.b),
        245
    )
end

local function DrawScoreboardOutline(x, y, w, h, thickness)
    thickness = thickness or 2
    surface.SetDrawColor(ScoreboardOutlineColor(x * 0.01 + y * 0.01))

    for i = 0, thickness - 1 do
        surface.DrawOutlinedRect(x + i, y + i, w - i * 2, h - i * 2)
    end
end

local function DrawScoreboardGradientText(text, fontName, x, y, offset, alignX, alignY)
    text = tostring(text or "")
    surface.SetFont(fontName)

    local fullWidth = surface.GetTextSize(text)
    local drawX = x

    if alignX == TEXT_ALIGN_CENTER then
        drawX = x - fullWidth * 0.5
    elseif alignX == TEXT_ALIGN_RIGHT then
        drawX = x - fullWidth
    end

    local characterCount = utf8.len(text) or #text
    for i = 1, characterCount do
        local character = utf8.sub(text, i, i)
        if character and character ~= "" then
            local characterWidth = surface.GetTextSize(character)
            draw.SimpleText(
                character,
                fontName,
                drawX,
                y,
                ScoreboardAnimatedColor(offset + i * 0.12, 1.7),
                TEXT_ALIGN_LEFT,
                alignY or TEXT_ALIGN_TOP
            )
            drawX = drawX + characterWidth
        end
    end
end

local function GetScoreboardPlayerRole(ply)
    if not IsValid(ply) then return "" end

    local userGroup = ""
    if ply.GetUserGroup then
        userGroup = string.lower(tostring(ply:GetUserGroup() or ""))
    end

    local translatedRoles = {
        superadmin = "СУПЕРАДМИН",
        super_admin = "СУПЕРАДМИН",
        ["super-admin"] = "СУПЕРАДМИН",
        admin = "АДМИН",
        moderator = "МОДЕРАТОР",
        mod = "МОДЕРАТОР",
        helper = "ПОМОЩНИК",
        owner = "ВЛАДЕЛЕЦ",
        developer = "РАЗРАБОТЧИК",
        user = "",
        guest = ""
    }

    if userGroup == "superadmin"
    or userGroup == "super_admin"
    or userGroup == "super-admin"
    or ply:IsSuperAdmin() then
        return "СУПЕРАДМИН"
    end

    if translatedRoles[userGroup] ~= nil then
        return translatedRoles[userGroup]
    end
    if userGroup ~= "" and userGroup ~= "user" and userGroup ~= "guest" then
        return string.upper(userGroup)
    end
    if ply:IsAdmin() then return "АДМИН" end
    return ""
end

local function GetScoreboardPlayerName(ply)
    if not IsValid(ply) then return "Неизвестный игрок" end

    local playerName = ply:Nick() or ply:Name() or "Неизвестный игрок"
    local role = GetScoreboardPlayerRole(ply)
    if role ~= "" then
        playerName = playerName .. "  [" .. role .. "]"
    end
    return playerName
end

local function CopyPlayerAppearanceToPreview(ply, modelPanel)
    if not IsValid(ply) or not IsValid(modelPanel) then return end

    local modelPath = ply:GetModel()
    if not isstring(modelPath) or modelPath == "" or not util.IsValidModel(modelPath) then
        modelPath = "models/player/kleiner.mdl"
    end

    modelPanel:SetModel(modelPath)
    modelPanel:SetFOV(36)
    modelPanel:SetCamPos(Vector(100, 0, 56))
    modelPanel:SetLookAt(Vector(0, 0, 42))
    modelPanel:SetDirectionalLight(BOX_TOP, Color(255, 220, 224))
    modelPanel:SetDirectionalLight(BOX_FRONT, Color(205, 164, 171))
    modelPanel:SetDirectionalLight(BOX_RIGHT, Color(200, 142, 155))
    modelPanel:SetDirectionalLight(BOX_LEFT, Color(120, 96, 101))
    modelPanel:SetAmbientLight(Color(105, 86, 90, 255))

    local ent = modelPanel:GetEntity()
    if not IsValid(ent) then return end

    ent:SetSkin(ply:GetSkin() or 0)
    ent:SetColor(ply:GetColor() or color_white)
    ent:SetMaterial(ply:GetMaterial() or "")

    if ent.SetPlayerColor and ply.GetPlayerColor then
        ent:SetPlayerColor(ply:GetPlayerColor())
    end

    local playerBodyGroups = ply:GetBodyGroups() or {}
    for _, bodyGroup in ipairs(playerBodyGroups) do
        if bodyGroup.id ~= nil then
            ent:SetBodygroup(bodyGroup.id, ply:GetBodygroup(bodyGroup.id))
        end
    end

    -- Copy Z-City's per-player clothing submaterials to the preview entity.
    local materials = ply:GetMaterials() or {}
    for slot = 0, #materials - 1 do
        local subMaterial = ply:GetSubMaterial(slot)
        if isstring(subMaterial) and subMaterial ~= "" then
            ent:SetSubMaterial(slot, subMaterial)
        end
    end

    -- Keep the target's model color available to Z-City-style accessories.
    ent.ScoreboardPreviewPlayerColor = ply.GetPlayerColor and ply:GetPlayerColor() or Vector(1, 1, 1)
    ent.ScoreboardPreviewSourceModel = modelPath

    local sequence = ent:LookupSequence("idle_suitcase")
    if sequence < 0 then sequence = ent:LookupSequence("idle_all_01") end
    if sequence < 0 then sequence = ent:LookupSequence("idle_subtle") end
    if sequence >= 0 then
        ent:ResetSequence(sequence)
        ent:SetCycle(0)
    end
end

local function BuildScoreboardPreviewAccessories(ply, modelPanel, previewFrame)
    if not IsValid(ply) or not IsValid(modelPanel) or not hg.Accessories then return end
    local accessoryList = ply.GetNetVar and ply:GetNetVar("Accessories", {}) or {}

    if isstring(accessoryList) then
        if accessoryList == "" or accessoryList == "none" then
            accessoryList = {}
        else
            accessoryList = { accessoryList }
        end
    end
    if not istable(accessoryList) then return end

    local previewEntity = modelPanel:GetEntity()
    if not IsValid(previewEntity) then return end

    local sourceModel = string.lower(ply:GetModel() or "")
    local isFemale = string.find(sourceModel, "female", 1, true) ~= nil
    local attachments = {}
    previewFrame.ScoreboardPreviewAccessories = attachments

    for _, accessoryName in ipairs(accessoryList) do
        local data = hg.Accessories[accessoryName]
        if data and not data.needcoolRender then
            local positionData = isFemale and data.fempos or data.malepos
            local modelPath = (isFemale and data.femmodel) or data.model

            if modelPath and positionData and positionData[1] and positionData[2] and data.bone then
                local accessoryModel = ClientsideModel(modelPath, RENDERGROUP_OPAQUE)
                if IsValid(accessoryModel) then
                    accessoryModel:SetNoDraw(true)
                    accessoryModel:SetModelScale(positionData[3] or 1)
                    accessoryModel:SetBodyGroups(data.bodygroups or "")

                    local accessorySkin = data.skin or 0
                    if isfunction(accessorySkin) then
                        local ok, result = pcall(accessorySkin, ply)
                        accessorySkin = ok and result or 0
                    end
                    if isnumber(accessorySkin) then accessoryModel:SetSkin(accessorySkin) end
                    if data.SubMat then accessoryModel:SetSubMaterial(0, data.SubMat) end
                    if data.bonemerge then accessoryModel:AddEffects(EF_BONEMERGE) end

                    attachments[#attachments + 1] = {
                        model = accessoryModel,
                        data = data,
                        bone = data.bone,
                        offsetPos = positionData[1],
                        offsetAng = positionData[2],
                        accessoryName = accessoryName
                    }
                end
            end
        end
    end

    modelPanel.PostDrawModel = function(self, entity)
        if not IsValid(entity) then return end

        for _, attachment in ipairs(attachments) do
            local accessoryModel = attachment.model
            local data = attachment.data
            if IsValid(accessoryModel) then
                local boneIndex = entity:LookupBone(attachment.bone)
                if boneIndex then
                    local boneMatrix = entity:GetBoneMatrix(boneIndex)
                    if boneMatrix then
                        local bonePos = boneMatrix:GetTranslation()
                        local boneAng = boneMatrix:GetAngles()
                        local drawPos, drawAng = LocalToWorld(
                            attachment.offsetPos,
                            attachment.offsetAng,
                            bonePos,
                            boneAng
                        )

                        if entity.ScoreboardPreviewSourceModel == "models/player/group01/male_06.mdl"
                        and (data.placement == "head" or data.placement == "face") then
                            drawPos, drawAng = LocalToWorld(
                                Vector(0.4, 0, 0.4), angle_zero, drawPos, drawAng
                            )
                        end

                        accessoryModel:SetRenderOrigin(drawPos)
                        accessoryModel:SetRenderAngles(drawAng)
                        accessoryModel:SetupBones()

                        if data.bSetColor then
                            local colorVector = data.vecColorOveride or entity.ScoreboardPreviewPlayerColor or Vector(1, 1, 1)
                            render.SetColorModulation(colorVector.x or colorVector[1] or 1, colorVector.y or colorVector[2] or 1, colorVector.z or colorVector[3] or 1)
                        end

                        accessoryModel:DrawModel()

                        if data.bSetColor then
                            render.SetColorModulation(1, 1, 1)
                        end
                    end
                end
            end
        end
    end
end

local function OpenScoreboardPlayerPreview(ply)
    if not IsValid(ply) then return end

    local playerName = ply:Nick() or "Неизвестный игрок"
    local steamID = ply:SteamID() or "BOT"
    local steamID64 = ply:SteamID64() or ""
    local ping = tostring(ply:Ping() or 0)
    local role = GetScoreboardPlayerRole(ply)

    local frame = vgui.Create("DFrame")
    frame:SetTitle("")
    frame:SetDraggable(false)
    frame:ShowCloseButton(false)
    frame:SetSize(math.min(ScrW() * 0.62, 1000), math.min(ScrH() * 0.76, 790))
    frame:Center()
    frame:SetAlpha(0)
    frame:MakePopup()
    frame:AlphaTo(255, 0.18, 0)

    frame.Paint = function(self, w, h)
        draw.RoundedBox(5, 0, 0, w, h, Color(41, 41, 41, 250))
        draw.RoundedBox(5, 1, 1, w - 2, ScreenScaleH(36), Color(48, 45, 46, 255))
        surface.SetDrawColor(SCOREBOARD_PINK)
        surface.DrawRect(0, ScreenScaleH(36), w, ScreenScaleH(2))
        DrawScoreboardOutline(0, 0, w, h, 2)
        DrawScoreboardGradientText(
            "ПРОСМОТР ИГРОКА",
            "ZB_InterfaceLarge",
            ScreenScaleH(14),
            ScreenScaleH(18),
            13,
            TEXT_ALIGN_LEFT,
            TEXT_ALIGN_CENTER
        )
    end

    local closeButton = vgui.Create("DButton", frame)
    closeButton:SetText("")
    closeButton:SetSize(ScreenScaleH(72), ScreenScaleH(22))
    closeButton:SetPos(frame:GetWide() - ScreenScaleH(80), ScreenScaleH(7))
    closeButton.Paint = function(self, w, h)
        local color = self:IsHovered() and SCOREBOARD_PINK or SCOREBOARD_PANEL
        draw.RoundedBox(3, 0, 0, w, h, color)
        surface.SetDrawColor(SCOREBOARD_PINK)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("ЗАКРЫТЬ", "ZB_InterfaceSmall", w / 2, h / 2, self:IsHovered() and SCOREBOARD_DARK or SCOREBOARD_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    closeButton.DoClick = function()
        if IsValid(frame) then
            frame:AlphaTo(0, 0.14, 0, function()
                if IsValid(frame) then frame:Remove() end
            end)
        end
    end

    local preview = vgui.Create("DModelPanel", frame)
    preview:SetPos(ScreenScaleH(12), ScreenScaleH(46))
    preview:SetSize(frame:GetWide() * 0.57, frame:GetTall() - ScreenScaleH(60))
    CopyPlayerAppearanceToPreview(ply, preview)
    BuildScoreboardPreviewAccessories(ply, preview, frame)

    function preview:LayoutEntity(entity)
        entity:SetAngles(Angle(0, 0, 0))
        self:RunAnimation()
    end

    preview.PaintOver = function(self, w, h)
        surface.SetDrawColor(SCOREBOARD_PINK.r, SCOREBOARD_PINK.g, SCOREBOARD_PINK.b, 90)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        surface.SetDrawColor(SCOREBOARD_PINK.r, SCOREBOARD_PINK.g, SCOREBOARD_PINK.b, 18)
        surface.DrawRect(0, h - ScreenScaleH(3), w, ScreenScaleH(3))
    end

    local details = vgui.Create("DPanel", frame)
    details:SetPos(frame:GetWide() * 0.60, ScreenScaleH(48))
    details:SetSize(frame:GetWide() * 0.36, frame:GetTall() - ScreenScaleH(62))
    details.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, SCOREBOARD_PANEL)
        DrawScoreboardOutline(0, 0, w, h, 1)
        DrawScoreboardGradientText("ИНФОРМАЦИЯ", "ZB_InterfaceMediumLarge", ScreenScaleH(12), ScreenScaleH(18), 16, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(SCOREBOARD_PINK.r, SCOREBOARD_PINK.g, SCOREBOARD_PINK.b, 70)
        surface.DrawRect(ScreenScaleH(12), ScreenScaleH(34), w - ScreenScaleH(24), 1)
    end

    local nameLabel = vgui.Create("DLabel", details)
    nameLabel:SetPos(ScreenScaleH(12), ScreenScaleH(48))
    nameLabel:SetSize(details:GetWide() - ScreenScaleH(24), ScreenScaleH(48))
    nameLabel:SetFont("ZB_InterfaceMediumLarge")
    nameLabel:SetTextColor(SCOREBOARD_WHITE)
    nameLabel:SetText(playerName)
    nameLabel:SetWrap(true)
    nameLabel:SetAutoStretchVertical(false)

    local roleLabel = vgui.Create("DLabel", details)
    roleLabel:SetPos(ScreenScaleH(12), ScreenScaleH(104))
    roleLabel:SetSize(details:GetWide() - ScreenScaleH(24), ScreenScaleH(25))
    roleLabel:SetFont("ZB_InterfaceMedium")
    roleLabel:SetTextColor(SCOREBOARD_PINK)
    roleLabel:SetText(role ~= "" and ("Роль: " .. role) or "Обычный игрок")

    local pingLabel = vgui.Create("DLabel", details)
    pingLabel:SetPos(ScreenScaleH(12), ScreenScaleH(136))
    pingLabel:SetSize(details:GetWide() - ScreenScaleH(24), ScreenScaleH(25))
    pingLabel:SetFont("ZB_InterfaceMedium")
    pingLabel:SetTextColor(SCOREBOARD_WHITE)
    pingLabel:SetText("Пинг: " .. ping .. " мс")

    local steamLabel = vgui.Create("DLabel", details)
    steamLabel:SetPos(ScreenScaleH(12), ScreenScaleH(168))
    steamLabel:SetSize(details:GetWide() - ScreenScaleH(24), ScreenScaleH(40))
    steamLabel:SetFont("ZB_InterfaceSmall")
    steamLabel:SetTextColor(SCOREBOARD_GRAY)
    steamLabel:SetText("Steam ID: " .. steamID)
    steamLabel:SetWrap(true)

    local steamButton = vgui.Create("DButton", details)
    steamButton:SetPos(ScreenScaleH(12), ScreenScaleH(222))
    steamButton:SetSize(details:GetWide() - ScreenScaleH(24), ScreenScaleH(30))
    steamButton:SetText("")
    steamButton.Paint = function(self, w, h)
        local hovered = self:IsHovered()
        draw.RoundedBox(3, 0, 0, w, h, hovered and SCOREBOARD_PINK or SCOREBOARD_PANEL_HOVER)
        DrawScoreboardOutline(0, 0, w, h, 1)
        draw.SimpleText("ОТКРЫТЬ ПРОФИЛЬ STEAM", "ZB_InterfaceSmall", w / 2, h / 2, hovered and SCOREBOARD_DARK or SCOREBOARD_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    steamButton.DoClick = function()
        if not IsValid(ply) or ply:IsBot() or steamID64 == "" then
            chat.AddText(SCOREBOARD_PINK, "У этого игрока нет Steam-профиля.")
            return
        end
        gui.OpenURL("https://steamcommunity.com/profiles/" .. steamID64)
    end

    -- Сохраняем действие открытия аккаунта, которое раньше было в контекстном меню.
    if zb.Experience and zb.Experience.AccountMenu then
        local accountButton = vgui.Create("DButton", details)
        accountButton:SetPos(ScreenScaleH(12), ScreenScaleH(260))
        accountButton:SetSize(details:GetWide() - ScreenScaleH(24), ScreenScaleH(30))
        accountButton:SetText("")
        accountButton.Paint = function(self, w, h)
            local hovered = self:IsHovered()
            draw.RoundedBox(3, 0, 0, w, h, hovered and SCOREBOARD_PINK or SCOREBOARD_PANEL_HOVER)
            DrawScoreboardOutline(0, 0, w, h, 1)
            draw.SimpleText("АККАУНТ ИГРОКА", "ZB_InterfaceSmall", w / 2, h / 2, hovered and SCOREBOARD_DARK or SCOREBOARD_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        accountButton.DoClick = function()
            if IsValid(ply) and zb.Experience and zb.Experience.AccountMenu then
                zb.Experience.AccountMenu(ply)
            end
        end
    end

    local copySteamButton = vgui.Create("DButton", details)
    copySteamButton:SetPos(ScreenScaleH(12), ScreenScaleH(298))
    copySteamButton:SetSize(details:GetWide() - ScreenScaleH(24), ScreenScaleH(30))
    copySteamButton:SetText("")
    copySteamButton.Paint = function(self, w, h)
        local hovered = self:IsHovered()
        draw.RoundedBox(3, 0, 0, w, h, hovered and SCOREBOARD_PINK or SCOREBOARD_PANEL_HOVER)
        DrawScoreboardOutline(0, 0, w, h, 1)
        draw.SimpleText("КОПИРОВАТЬ STEAM ID", "ZB_InterfaceSmall", w / 2, h / 2, hovered and SCOREBOARD_DARK or SCOREBOARD_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    copySteamButton.DoClick = function()
        if IsValid(ply) then
            SetClipboardText(ply:SteamID())
            chat.AddText(SCOREBOARD_PINK, "Steam ID скопирован.")
        end
    end

    frame.OnRemove = function(self)
        for _, attachment in ipairs(self.ScoreboardPreviewAccessories or {}) do
            if IsValid(attachment.model) then attachment.model:Remove() end
        end
    end
end

local function PaintScoreboardPlayer(button, ply, isSpectator)
    button.Paint = function(self, w, h)
        if not IsValid(ply) then return end

        local target = self:IsHovered() and 1 or 0
        self.ScoreboardHover = Lerp(FrameTime() * 8, self.ScoreboardHover or 0, target)
        local progress = self.ScoreboardHover
        local backgroundColor = SCOREBOARD_PANEL:Lerp(SCOREBOARD_PANEL_HOVER, progress)

        if isSpectator then
            backgroundColor = backgroundColor:Lerp(Color(51, 51, 51, 245), 0.35)
        end

        surface.SetDrawColor(backgroundColor)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(SCOREBOARD_PINK.r, SCOREBOARD_PINK.g, SCOREBOARD_PINK.b, 80 + progress * 100)
        surface.DrawRect(0, h - ScreenScaleH(2), w, ScreenScaleH(2))
        DrawScoreboardOutline(0, 0, w, h, 1)

        local textY = h * 0.5
        local playerFont = "ZB_InterfaceMediumLarge"
        DrawScoreboardGradientText(
            GetScoreboardPlayerName(ply),
            playerFont,
            self.ScoreboardTextLeft or ScreenScaleH(8),
            textY,
            ply:EntIndex(),
            TEXT_ALIGN_LEFT,
            TEXT_ALIGN_CENTER
        )

        DrawScoreboardGradientText(
            tostring(ply:Ping() or 0),
            "ZB_InterfaceSmall",
            w - ScreenScaleH(42),
            textY,
            ply:EntIndex() + 10,
            TEXT_ALIGN_RIGHT,
            TEXT_ALIGN_CENTER
        )
    end
end

local function AddScoreboardPlayer(parent, ply, isSpectator)
    local button = vgui.Create("DButton", parent)
    button:SetSize(100, ScreenScaleH(24))
    button:Dock(TOP)
    button:DockMargin(8, 5, 8, 0)
    button:SetText("")

    local avatarSize = math.min(ScreenScaleH(17), button:GetTall() - ScreenScaleH(5))
    button.ScoreboardTextLeft = avatarSize + ScreenScaleH(12)

    local avatar = vgui.Create("AvatarImage", button)
    avatar:SetSize(avatarSize, avatarSize)
    avatar:SetPos(ScreenScaleH(4), (button:GetTall() - avatarSize) / 2)
    if not ply:IsBot() then
        avatar:SetPlayer(ply, 64)
    end
    avatar:SetMouseInputEnabled(false)
    avatar:SetKeyboardInputEnabled(false)
    avatar.PaintOver = function(self, w, h)
        surface.SetDrawColor(SCOREBOARD_PINK.r, SCOREBOARD_PINK.g, SCOREBOARD_PINK.b, 180)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    local soundButton = vgui.Create("DImageButton", button)
    soundButton:Dock(RIGHT)
    soundButton:SetSize(ScreenScaleH(18), 0)
    soundButton:DockMargin(0, ScreenScaleH(4), ScreenScaleH(6), ScreenScaleH(4))
    soundButton:SetImage(not ply:IsMuted() and "icon16/sound.png" or "icon16/sound_mute.png")
    soundButton.DoClick = function(self)
        OpenPlayerSoundSettings(self, ply)
    end
    ply.soundButton = soundButton

    PaintScoreboardPlayer(button, ply, isSpectator)

    button:SetTooltip("ЛКМ — профиль Steam; ПКМ — просмотр модели игрока")

    -- ЛКМ сохраняет привычное действие: открыть Steam-профиль.
    button.DoClick = function()
        if not IsValid(ply) then return end

        if ply:IsBot() or not ply:SteamID64() or ply:SteamID64() == "" then
            chat.AddText(SCOREBOARD_PINK, "У этого игрока нет Steam-профиля.")
            return
        end

        gui.OpenURL("https://steamcommunity.com/profiles/" .. ply:SteamID64())
    end

    -- ПКМ сразу открывает модель игрока в стиле Z-City.
    function button:DoRightClick()
        if IsValid(ply) then
            OpenScoreboardPlayerPreview(ply)
        end
    end

    parent:AddItem(button)
    return button
end

local function PaintScoreboardScrollPanel(panel)
    panel.Paint = function(self, w, h)
        surface.SetDrawColor(41, 41, 41, 230)
        surface.DrawRect(0, 0, w, h)
        DrawScoreboardOutline(0, 0, w, h, 2)
    end
end

-- Prevent consecutive openings from using the same edge when possible.
-- ZFrame has its own delayed First() animation that always moves the frame
-- vertically; it conflicts with the scoreboard's random-edge animation.
local lastScoreboardEntrySide = nil

function GM:ScoreboardShow()
    if IsValid(scoreBoardMenu) then
        scoreBoardMenu:Remove()
        scoreBoardMenu = nil
    end

    Dynamic = 0
    scoreBoardMenu = vgui.Create("ZFrame")

    -- ZFrame schedules self:First() from Init(). Override it before that
    -- zero-delay timer runs, otherwise ZFrame replaces our chosen direction
    -- with its own fixed bottom-to-top animation.
    scoreBoardMenu.First = function(self)
        -- Intentionally empty: the scoreboard controls its own animation below.
    end

    local sizeX, sizeY = ScrW() / 1.3, ScrH() / 1.2
    local posX, posY = ScrW() / 2 - sizeX / 2, ScrH() / 2 - sizeY / 2
    scoreBoardMenu:SetSize(sizeX, sizeY)

    -- Choose a random screen edge. Avoid repeating the previous edge so
    -- repeated quick openings visibly rotate through all four directions.
    local entrySide
    if lastScoreboardEntrySide then
        local roll = math.random(1, 3)
        if roll >= lastScoreboardEntrySide then
            roll = roll + 1
        end
        entrySide = roll
    else
        entrySide = math.random(1, 4)
    end
    lastScoreboardEntrySide = entrySide

    local startX, startY = posX, posY
    if entrySide == 1 then
        startY = -sizeY - ScreenScaleH(20)
    elseif entrySide == 2 then
        startY = ScrH() + ScreenScaleH(20)
    elseif entrySide == 3 then
        startX = -sizeX - ScreenScaleH(20)
    else
        startX = ScrW() + ScreenScaleH(20)
    end

    scoreBoardMenu:SetPos(startX, startY)
    scoreBoardMenu:SetAlpha(0)
    scoreBoardMenu:MakePopup()
    scoreBoardMenu:SetKeyboardInputEnabled(false)
    scoreBoardMenu:ShowCloseButton(false)
    local thisScoreboard = scoreBoardMenu
    thisScoreboard:MoveTo(posX, posY, 0.34, 0, 0.2, function()
        if IsValid(thisScoreboard) then thisScoreboard:SetPos(posX, posY) end
    end)
    thisScoreboard:AlphaTo(255, 0.25, 0)

    local muteAllButton = vgui.Create("DButton", scoreBoardMenu)
    local buttonW, buttonH = ScreenScale(47), ScreenScale(8)
    muteAllButton:SetPos(scoreBoardMenu:GetWide() - buttonW * 2.15, scoreBoardMenu:GetTall() - buttonH * 1.6)
    muteAllButton:SetSize(buttonW, buttonH)
    muteAllButton:SetText("")
    muteAllButton.Paint = function(self, w, h)
        surface.SetDrawColor(32, 32, 32, 230)
        surface.DrawRect(0, 0, w, h)
        DrawScoreboardOutline(0, 0, w, h, 2)
        DrawScoreboardGradientText(
            hg.muteall and "ВСЕМ: ВКЛ ЗВУК" or "ВСЕМ: ВЫКЛ ЗВУК",
            "ZB_InterfaceSmall", w / 2, h / 2, 1, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER
        )
    end
    muteAllButton.DoClick = function()
        hg.muteall = not hg.muteall
        for _, ply in player.Iterator() do
            if hg.muteall then
                ply:SetVoiceVolumeScale(0)
            else
                ply:SetVoiceVolumeScale(
                    (not hg.mutespect or ply:Alive())
                    and ((hg.playerInfo[ply:SteamID()] and hg.playerInfo[ply:SteamID()][2]) or 1)
                    or 0
                )
            end
        end
    end

    local muteSpectatorsButton = vgui.Create("DButton", scoreBoardMenu)
    muteSpectatorsButton:SetPos(scoreBoardMenu:GetWide() - buttonW * 1.05, scoreBoardMenu:GetTall() - buttonH * 1.6)
    muteSpectatorsButton:SetSize(buttonW, buttonH)
    muteSpectatorsButton:SetText("")
    muteSpectatorsButton.Paint = function(self, w, h)
        surface.SetDrawColor(32, 32, 32, 230)
        surface.DrawRect(0, 0, w, h)
        DrawScoreboardOutline(0, 0, w, h, 2)
        DrawScoreboardGradientText(
            hg.mutespect and "НАБЛ.: ВКЛ ЗВУК" or "НАБЛ.: ВЫКЛ ЗВУК",
            "ZB_InterfaceSmall", w / 2, h / 2, 2, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER
        )
    end
    muteSpectatorsButton.DoClick = function()
        hg.mutespect = not hg.mutespect
        for _, ply in player.Iterator() do
            if not ply:Alive() then
                if hg.mutespect then
                    ply:SetVoiceVolumeScale(0)
                else
                    ply:SetVoiceVolumeScale(
                        not hg.muteall
                        and ((hg.playerInfo[ply:SteamID()] and hg.playerInfo[ply:SteamID()][2]) or 1)
                        or 0
                    )
                end
            end
        end
    end

    local serverName = GetHostName() or "LZ-City | Игровой сервер"
    scoreBoardMenu.PaintOver = function(self, w, h)
        DrawScoreboardOutline(0, 0, w, h, 3)
        DrawScoreboardGradientText(serverName, "ZB_InterfaceLarge", w / 2, 10, 3, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        DrawScoreboardGradientText("ИГРОКИ", "ZB_InterfaceMediumLarge", w / 4, ScreenScale(25), 4, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        DrawScoreboardGradientText("ТИКРЕЙТ СЕРВЕРА: " .. math.Round(1 / engine.ServerFrameTime()), "ZB_InterfaceMediumLarge", w / 2, ScreenScale(25), 5, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        DrawScoreboardGradientText("НАБЛЮДАТЕЛИ", "ZB_InterfaceMediumLarge", w * 0.75, ScreenScale(25), 6, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        DrawScoreboardGradientText("Версия LZ-City: " .. tostring(hg.Version or "неизвестно"), "ZB_InterfaceSmall", w * 0.01, h - ScreenScale(5), 7, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
    end

    if LocalPlayer():Team() ~= TEAM_SPECTATOR then
        local spectateButton = vgui.Create("DButton", scoreBoardMenu)
        spectateButton:SetPos(sizeX * 0.925, sizeY * 0.095)
        spectateButton:SetSize(ScrW() / 20, ScrH() / 30)
        spectateButton:SetText("")
        spectateButton.DoClick = function()
            net.Start("ZB_SpecMode")
                net.WriteBool(true)
            net.SendToServer()
            scoreBoardMenu:Remove()
            scoreBoardMenu = nil
        end
        spectateButton.Paint = function(self, w, h)
            surface.SetDrawColor(32, 32, 32, 230)
            surface.DrawRect(0, 0, w, h)
            DrawScoreboardOutline(0, 0, w, h, 2)
            DrawScoreboardGradientText("НАБЛЮДАТЬ", "ZB_InterfaceMedium", w / 2, h / 2, 8, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    if LocalPlayer():Team() == TEAM_SPECTATOR then
        local playingButton = vgui.Create("DButton", scoreBoardMenu)
        playingButton:SetPos(sizeX * 0.010, sizeY * 0.095)
        playingButton:SetSize(ScrW() / 20, ScrH() / 30)
        playingButton:SetText("")
        playingButton.DoClick = function()
            net.Start("ZB_SpecMode")
                net.WriteBool(false)
            net.SendToServer()
            scoreBoardMenu:Remove()
            scoreBoardMenu = nil
        end
        playingButton.Paint = function(self, w, h)
            surface.SetDrawColor(32, 32, 32, 230)
            surface.DrawRect(0, 0, w, h)
            DrawScoreboardOutline(0, 0, w, h, 2)
            DrawScoreboardGradientText("В ИГРУ", "ZB_InterfaceMedium", w / 2, h / 2, 9, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    local playersPanel = vgui.Create("DScrollPanel", scoreBoardMenu)
    playersPanel:SetPos(10, ScreenScaleH(58))
    playersPanel:SetSize(sizeX / 2 - 10, sizeY - ScreenScaleH(72))
    PaintScoreboardScrollPanel(playersPanel)

    local disappearance = lply:GetNetVar("disappearance", nil)
    for _, ply in player.Iterator() do
        if ply:Team() ~= TEAM_SPECTATOR then
            if CurrentRound() and CurrentRound().name == "fear" and not ply:Alive() then
                -- Hide eliminated players for this round mode.
            elseif disappearance and ply ~= lply then
                -- Keep the existing disappearance visibility rule.
            else
                AddScoreboardPlayer(playersPanel, ply, false)
            end
        end
    end

    local spectatorsPanel = vgui.Create("DScrollPanel", scoreBoardMenu)
    spectatorsPanel:SetPos(sizeX / 2 + 5, ScreenScaleH(58))
    spectatorsPanel:SetSize(sizeX / 2 - 15, sizeY - ScreenScaleH(72))
    PaintScoreboardScrollPanel(spectatorsPanel)

    for _, ply in player.Iterator() do
        if ply:Team() == TEAM_SPECTATOR then
            if CurrentRound() and CurrentRound().name == "fear" and not ply:Alive() then
                -- Keep the existing spectator visibility rule.
            elseif disappearance and ply ~= lply then
                -- Keep the existing disappearance visibility rule.
            else
                AddScoreboardPlayer(spectatorsPanel, ply, true)
            end
        end
    end

    return true
end

function GM:ScoreboardHide()
    if IsValid(scoreBoardMenu) then
        scoreBoardMenu:Close()
        scoreBoardMenu = nil
    end
end


-- свет от молнии а саму молнию я не сделал skill issue
if CLIENT then
	net.Receive("PunishLightningEffect", function()
		local target = net.ReadEntity()
		if not IsValid(target) then return end
		local dlight = DynamicLight(target:EntIndex())
		if dlight then
			dlight.pos = target:GetPos()
			dlight.r = 126
			dlight.g = 139
			dlight.b = 212
			dlight.brightness = 1
			dlight.Decay = 1000
			dlight.Size = 500
			dlight.DieTime = CurTime() + 1
		end
	end)
end

/*  -- а кстати зачем здесь нэт, это же можно было на клиенте полностью сделать...
	if CLIENT then
		net.Receive("PluvCommand", function()
			local specialSteamID = "STEAM_0:1:81850653" 
			local playerSteamID = LocalPlayer():SteamID() 

			local imageURLs = {"https://sadsalat.github.io/salatis/music/boof.gif", "https://i.ibb.co/drt1Lks/KtvCLSs.webp", "https://media.tenor.com/kG4PmVvJuRIAAAAC/rain-world-rain-world-saint.gif"} 
			local soundURLs = {"https://sadsalat.github.io/salatis/music/sus-rock.mp3", "https://sadsalat.github.io/salatis/music/tiktok-raaaah-scream.mp3", "https://sadsalat.github.io/salatis/music/sus-rock.mp3"} 

			local chosenImage = imageURLs[math.random(#imageURLs)]
			local chosenSound = soundURLs[math.random(#soundURLs)]

			sound.PlayURL(chosenSound, "", function(station)
				if IsValid(station) then
					station:Play()
				else
					print("Unable to play the sound.")
				end
			end)

			local html = vgui.Create("HTML")
			html:OpenURL(chosenImage)
			html:SetSize(ScrW(), ScrH())
			html:Center()
			html:MakePopup()

			timer.Simple(3, function()
				if IsValid(html) then
					html:Remove()
				end
			end)
		end)
	end
*/

local lightningMaterial = Material("sprites/lgtning")

net.Receive("AnotherLightningEffect", function()
    local target = net.ReadEntity()
	if not IsValid(target) then return end
    local points = {}
    for i = 1, 27 do
        points[i] = target:GetPos() + Vector(0, 0, i * 50) + Vector(math.Rand(-20,20),math.Rand(-20,20),math.Rand(-20,20))
    end
    hook.Add( "PreDrawTranslucentRenderables", "LightningExample", function(isDrawingDepth, isDrawingSkybox)
        if isDrawingDepth or isDrawingSkybox then return end
        local uv = math.Rand(0, 1)
        render.OverrideBlend( true, BLEND_SRC_COLOR, BLEND_SRC_ALPHA, BLENDFUNC_ADD, BLEND_ONE, BLEND_ZERO, BLENDFUNC_ADD )
        render.SetMaterial(lightningMaterial)
        render.StartBeam(27)
        for i = 1, 27 do
            render.AddBeam(points[i], 20, uv * i, Color(255,255,255,255))
        end
        render.EndBeam()
        render.OverrideBlend( false )
    end )
    timer.Simple(0.1, function()
        hook.Remove("PreDrawTranslucentRenderables", "LightningExample")
    end)
end)

function GM:AddHint( name, delay )
	return false
end

local snakeGameOpen = false

concommand.Add("zb_snake", function() -- вот как здесь!
    if snakeGameOpen then
        print("[Snake Game] Игра уже запущена!")
        return
    end

    local frame = vgui.Create("ZFrame")
    frame:SetTitle("Snake Game")
    frame:SetSize(400, 400)
    frame:Center()
    frame:MakePopup()
    frame:SetDeleteOnClose(true)  
    snakeGameOpen = true  

    local gridSize = 20
    local gridWidth = 19  
    local gridHeight = 19  
    local snakePanel = vgui.Create("DPanel", frame)
    snakePanel:SetSize(380, 380)
    snakePanel:SetPos(10, 10)

    
    frame:SetDraggable(true)
    frame:ShowCloseButton(true)

    local snake = {
        {x = 10, y = 10},
    }
	
    local snakeDirection = "RIGHT"
    local food = nil
    local score = 0
    local gameRunning = true

  
    local function spawnFood()
        local validPosition = false
        while not validPosition do
            local newFood = {
                x = math.random(0, gridWidth - 1), 
                y = math.random(0, gridHeight - 1)
            }
            validPosition = true

        
            for _, segment in ipairs(snake) do
                if segment.x == newFood.x and segment.y == newFood.y then
                    validPosition = false  
                    break
                end
            end

            
            if validPosition then
                food = newFood
            end
        end
    end

    
    local function drawSnake()
        surface.SetDrawColor(0, 255, 0, 255)
        for _, segment in ipairs(snake) do
            surface.DrawRect(segment.x * gridSize, segment.y * gridSize, gridSize - 1, gridSize - 1)
        end
    end

  
    local function drawFood()
        if food then
            surface.SetDrawColor(255, 0, 0, 255)
            surface.DrawRect(food.x * gridSize, food.y * gridSize, gridSize - 1, gridSize - 1)
        end
    end

   
    local function moveSnake()
        if not gameRunning then return end

        local head = table.Copy(snake[1])

        if snakeDirection == "UP" then
            head.y = head.y - 1
        elseif snakeDirection == "DOWN" then
            head.y = head.y + 1
        elseif snakeDirection == "LEFT" then
            head.x = head.x - 1
        elseif snakeDirection == "RIGHT" then
            head.x = head.x + 1
        end

        
        if head.x < 0 or head.x >= gridWidth or head.y < 0 or head.y >= gridHeight then
            gameRunning = false
        end

       
        for _, segment in ipairs(snake) do
            if segment.x == head.x and segment.y == head.y then
                gameRunning = false
            end
        end

       
        table.insert(snake, 1, head)

        if food and head.x == food.x and head.y == food.y then
            score = score + 1
            spawnFood()  
        else
            table.remove(snake)
        end
    end


    local function resetGame()
        snake = {{x = 10, y = 10}}
        snakeDirection = "RIGHT"
        score = 0
        gameRunning = true
        spawnFood()  
    end


    function snakePanel:Paint(w, h)
        surface.SetDrawColor(50, 50, 50, 255)
        surface.DrawRect(0, 0, w, h)

        if gameRunning then
            drawSnake()
            drawFood()
        else
            draw.SimpleText("Game Over! Press R to restart", "DermaDefault", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        draw.SimpleText("Score: " .. score, "DermaDefault", 10, 10, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end


    function frame:OnKeyCodePressed(key) -- ФУРИ МУВ теперь понятно почему лагает змейка
        if key == KEY_W and snakeDirection ~= "DOWN" then
            snakeDirection = "UP"
        elseif key == KEY_S and snakeDirection ~= "UP" then
            snakeDirection = "DOWN"
        elseif key == KEY_A and snakeDirection ~= "RIGHT" then
            snakeDirection = "LEFT"
        elseif key == KEY_D and snakeDirection ~= "LEFT" then
            snakeDirection = "RIGHT"
        elseif key == KEY_R then
            resetGame()
        end
    end


    timer.Create("SnakeGameTimer", 0.2, 0, function()
        if gameRunning then
            moveSnake()
        end
        snakePanel:InvalidateLayout(true)
    end)


    frame.OnClose = function()
        timer.Remove("SnakeGameTimer")
        snakeGameOpen = false  
        print("[Snake Game] Игра закрыта.") -- НЕ РАБОТАЕТ
    end


    resetGame()
end)

hook.Add("Player Spawn", "GuiltKnown",function(ply)
	if ply == LocalPlayer() then
		system.FlashWindow()
	end
end)