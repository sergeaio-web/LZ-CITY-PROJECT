AddCSLuaFile()
ENT.Base = "npc_scp_directorcut_base"
ENT.Type = "nextbot"
ENT.AutomaticFrameAdvance = true
ENT.Category = "SCP CB Director's Cut"
ENT.Spawnable = false
ENT.Editable = false
ENT.AdminOnly = false
ENT.PrintName = "SCP 173"
ENT.Author = ""
ENT.Contact = ""
ENT.PhysgunDisabled = false
ENT.SpawnHealth = 2000
ENT.Faction = {"FACTION_SCP"}
ENT.CollisionBounds = {Vector(-6.5, -6.5, 0), Vector(6.5, 6.5, 72)}
ENT.IsKillable = false
ENT.Model = "models/director_cut/173/173.mdl"
ENT.FOV = 360

if SERVER then

util.AddNetworkString("SCPDirectorCut173")
net.Receive("SCPDirectorCut173", function(len, ply)

	if !ply.SCPDCVisibilityTable then
		ply.SCPDCVisibilityTable = {}
	end
	local ent = net.ReadEntity()
	local visible = net.ReadBool()
	ply.SCPDCVisibilityTable[ent] = visible

end)

function ENT:CustomInitialize()

	self.TurningCoefficent = 0.8
	self.DragStone = CreateSound(self, "173/StoneDrag.wav")
	self.IsBeingBanishedBy = NULL
	self:SetBloodColor(-1)
	self.CoefficientGoCheckTime = CurTime()
	self.CoefficientGoCan = false

end


function ENT:GetTurningCoefficent()

	if IsValid(self.CurrentEnemy) and (!self:Visible(self.CurrentEnemy) or !self:CanReachEntity(self.CurrentEnemy, 0.1, true)) then return 0 end
	return self.TurningCoefficent

end

function ENT:OpenDoors()

	local trace = util.QuickTrace(self:WorldSpaceCenter(), self:GetForward()*96, self)
	if trace.Hit then
		if trace.Entity:GetClass() == "prop_door_rotating" then self:DestroyObstacles() return end
		self:DCOpenDoor(trace.Entity, nil, false)
	end

end

function ENT:GetPosForPatrol()

	return self:GetPos() + Vector(math.Rand(-1, 1), math.Rand(-1, 1), 0)*15000

end

function ENT:TurnHeadTo(pos)

	local forward = self:GetAngles()
	forward:Normalize()
	local dir = (pos - self:GetPos()):Angle()
	dir:Normalize()
	dir:Sub(forward)
	dir:Normalize()
	dir.p = dir.y
	dir.y = 0
	dir.r = math.Clamp(self:GetPos().z - pos.z, -25, 25)
	self:ManipulateBoneAngles(self:LookupBone("Bone_001"), dir)

end


function ENT:UpdateSounds()

	if self.MoveTime > CurTime() and IsValid(self.CurrentEnemy) then
		if !self.DragStone:IsPlaying() then
			self.DragStone:Play()
		end
	else
		if self.DragStone:IsPlaying() then
			self.DragStone:Stop()
		end
	end

end
function ENT:FindEnemy()

	local out = {}
	for k, v in pairs(ents.GetAlive()) do
		if !self:IsValidEnemy( v ) then continue end
		if !v:Visible(self) then continue end
		table.insert(out, v)	
	end
	return table.GetClosestEntity(out, self:GetPos())

end

function ENT:FindEnemies()

	local out = {}
	for k, v in pairs(ents.GetAlive()) do
		if !self:IsValidEnemy( v ) then continue end
		if !v:IsPlayer() and !self:CanSeeEntity( v ) then continue end
		table.insert(out, v)	
	end
	return out

end

function ENT:WhoIsLookingAtMe()

	local out = {}
	for k, v in ipairs(self:FindEnemies()) do
		if v:IsPlayer() and (istable(v.SCPDCVisibilityTable) and v.SCPDCVisibilityTable[self]) then table.insert(out,v) end
			if v.IsDrGNextbot then
				if v:IsInSight(self) then table.insert(out,v) end
			elseif v:IsNextBot() then
				local fov = v:GetFOV()
				local range = v:GetMaxVisionRange()
				if util.IsPointInCone( self:GetPos(), v:EyePos(), v:GetForward(), math.cos( math.rad( fov / 2) ), range ) then table.insert(out,v) end
			end
			if v:IsNPC() and v:IsInViewCone(self) then table.insert(out,v) end
	end
	return out

end

function ENT:SnapSCPNeck()

	//local tab = table.Add(ents.FindByClass("npc_scp_049_directorcut"), ents.FindByClass("npc_scp_106_directorcut"))
	//local tab = ents.FindByFunction(function(scp) if scp.IsNeckSnappableBy173 then return true end return false end)
	//local ent = table.GetClosestEntity(tab, self:GetPos(), 96)
	local ent = table.GetClosestEntity(SCPCBDCNextbotsSnappableNeck, self:GetPos(), 96)
	if !IsValid(ent) or ent:IsFlagSet(FL_NOTARGET) then return end
	self:SnapNeck(ent)

end

function ENT:SnapNeck(ent)

	if ent:IsPlayer() then
		hg.BreakNeck(ent)
	elseif ent.IsNeckSnappableBy173 then
		ent:OnNeckSnapped(self)
	else
		local dmg = DamageInfo()
		dmg:SetDamageType(bit.bor(268435456, 2048))
		dmg:SetDamage(math.huge)
		dmg:SetAttacker(self)
		dmg:SetDamageForce(vector_origin)
		ent:TakeDamageInfo(dmg)
		if IsAliveEntity(ent) then return end
		self:EmitSound("173/NeckSnap"..math.random(1,5)..".ogg")
	end

end

function ENT:PostThink()

	if IsValid(self.IsBeingBanishedBy) then return end
	if math.random(500) == 1 then
		if math.random(2) == 1 then
			self:OpenDoors()
		else
			self:DestroyObstacles()
		end
	end	
	if !IsValid(self.CurrentEnemy) then
		if CurTime() > self.PatrolWait and !self.IsPatroling then
			self.IsPatroling = true
			local canteleport, chance = self:CanTeleport()
			if canteleport and chance >= math.random() then
				self:TeleportToEnemy(2)
			end		
			self.PatrolPos = self:GetPosForPatrol()			
			self.StuckCounter = 0
		elseif CurTime() <= self.PatrolWait and !self.IsPatroling then
			local enemy = self:FindEnemy()
			if IsValid(enemy) then
				self.StuckCounter = 0
				self.CurrentEnemy = enemy
			end
		elseif self.IsPatroling and CurTime() > self.PatrolWait then
			local res, res2 = self:ComputeAndMove(self.PatrolPos, 1000, 25, 1000, function()
				if self.StuckCounter > 100 then 
					return "stuck" 
				end
				local enemy = self:FindEnemy()
				if IsValid(enemy) then
					return "enemy", enemy
				end
				local viewers = self:WhoIsLookingAtMe()
				if !table.IsEmpty(viewers) then
					return "eyecontact"
				end				
			end, true)
			if res == "reached" or res == "stuck" or res == "unreachable" or res == "no path" then
				self.IsPatroling = false
				self.PatrolWait = CurTime() + math.random(10, 60)
				self.ShouldRecompute = true
				self.IsCheckingEnemyPos = false
			elseif res == "moving" then
			elseif res == "enemy" then
				self.CurrentEnemy = res2
			end
		end
	else
		local res, res2 = self:ComputeAndMove(self.CurrentEnemy:GetPos(), 1000, 5, 80, function()
			if self.StuckCounter > 100 then 
				return "stuck" 
			end
			local enemy = self:FindEnemy()
			if IsValid(enemy) then
				if enemy != self.CurrentEnemy then
					self.CurrentEnemy = enemy
				end
			end
			local viewers = self:WhoIsLookingAtMe()
			if !table.IsEmpty(viewers) then
				local closestenemy = table.GetClosestEntity(viewers, self:GetPos())
				local trace = self:TraceHullAccurately(closestenemy:GetPos())
				if !trace.Hit or trace.Entity == closestenemy then self.LastSeenEnemyPosition = closestenemy:GetPos() end
				return "eyecontact"
			end
			if !self.LastSeenEnemyPosition:IsZero() then
				self:PointAtVectorSmooth(self.LastSeenEnemyPosition, 1, true)
			end
			self.LastSeenEnemyPosition = vector_origin
			if !self:IsValidEnemy(self.CurrentEnemy) then
				return "patrol"
			end
			self:TurnHeadTo(self.CurrentEnemy:GetPos())
			if self:GetRangeTo(self.CurrentEnemy) < 15 then
				return "ereached"
			end
		end, true)
		if res == "stuck" then
			self.PatrolWait = CurTime() + math.random(5, 30)
			self.IsPatroling = false
			self.ShouldRecompute = true
			self.CurrentEnemy = NULL
			self.StuckCounter = 0
		elseif res == "patrol" then
			self.IsCheckingEnemyPos = false
			self.CurrentEnemy = NULL
			self.ShouldRecompute = true
			self.PatrolPos = self:GetPosForPatrol()
		elseif res == "ereached" then
			self:SnapNeck(self.CurrentEnemy)
		elseif res == "moving" then
			self:SnapSCPNeck()
		end
	end

end

function ENT:OnRemove()

	self.DragStone:Stop()

end

end
if CLIENT then

local mat = Material("ambulance/amb_blu")

local function IsValidPlayer()

	local ent = LocalPlayer()
	if !IsValid(ent) then return false end
	if !ent:Alive() then return false end
	if ent:IsFlagSet(FL_NOTARGET) then return false end
	if GetConVar("ai_ignoreplayers"):GetBool() then return false end
	return true

end

-- === Blink mechanic ===
-- Every 15-30 seconds (randomised), the player's "eyes" close for a short
-- moment. While blinking, we tell the server the player can't see any
-- SCP-173 instance, which lets it move even if you were staring at it.
local SCP173_BLINK_MIN = 15
local SCP173_BLINK_MAX = 30
local SCP173_AUTO_BLINK_DURATION = 0.5 -- how long an automatic blink lasts, in seconds

local NextAutoBlinkTime = CurTime() + math.Rand(SCP173_BLINK_MIN, SCP173_BLINK_MAX)
local AutoBlinkEndTime = 0
local IsAutoBlinking = false
local IsManualBlinking = false

local function IsSCP173Spawned()
	return #ents.FindByClass("npc_scp_173_directorcut") > 0
end

-- The effective blink state. Even if the raw flags are set, blinking only
-- actually does anything while at least one SCP-173 exists on the map.
local function SCP173IsBlinking()
	if !IsSCP173Spawned() then return false end
	return IsAutoBlinking or IsManualBlinking
end

hook.Add("Think", "SCP173BlinkController", function()

	if !IsValidPlayer() then return end
	if !IsSCP173Spawned() then return end

	if !IsAutoBlinking and CurTime() >= NextAutoBlinkTime then
		IsAutoBlinking = true
		AutoBlinkEndTime = CurTime() + SCP173_AUTO_BLINK_DURATION
	elseif IsAutoBlinking and CurTime() >= AutoBlinkEndTime then
		IsAutoBlinking = false
		NextAutoBlinkTime = CurTime() + math.Rand(SCP173_BLINK_MIN, SCP173_BLINK_MAX)
	end

end)

-- Manual blink: hold the key to keep your eyes shut, release to open them.
-- Bind with, e.g.  bind b +scp173_blink
concommand.Add("+scp173_blink", function()

	if !IsValidPlayer() then return end
	if !IsSCP173Spawned() then return end
	IsManualBlinking = true
	-- push the automatic timer back so it doesn't stack right on release
	NextAutoBlinkTime = CurTime() + math.Rand(SCP173_BLINK_MIN, SCP173_BLINK_MAX)

end)

concommand.Add("-scp173_blink", function()

	IsManualBlinking = false

end)

hook.Add("HUDPaint", "SCP173BlinkOverlay", function()

	if !SCP173IsBlinking() then return end
	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawRect(0, 0, ScrW(), ScrH())

end)

function ENT:CustomInitialize()

	self.PixVisLegs = util.GetPixelVisibleHandle()
	self.PixVisMiddle = util.GetPixelVisibleHandle()
	self.PixVisNeck = util.GetPixelVisibleHandle()
	self.PixVisHead2 = util.GetPixelVisibleHandle()
	self.PixVisLeftArm = util.GetPixelVisibleHandle()
	self.PixVisRightArm = util.GetPixelVisibleHandle()
	self.PreviouslySeenTime = 0
	self.PreviouslySeenDistance = 0
	self.IsCurrentlyBeingSeen = false
	self.VisibilityCheckCooldown = CurTime() + 0.01
	self.VisibilityStopCheck = 0
end

local size = 32
local size2 = 16
local legsoffset = vector_up*15 - Vector(5, 0, 0)
local middleoffset = legsoffset + vector_up*size
local headoffset = middleoffset + vector_up*size
local headoffset2 = headoffset + vector_up*size2
local neckoffset = middleoffset + vector_up*size2

local rightarmlocal = Vector(5.724532, -6.480856, 54.215820)
local leftarmlocal = Vector(5.724532, 8.480856, 54.215820)

sound.Add( {
	name = "SCP173Jumpscare",
	channel = -1,
	volume = 1.0,
	level = 80,
	pitch = 100,
	sound = {"horror/Horror1.ogg","horror/Horror2.ogg","horror/Horror9.ogg","horror/Horror10.ogg","horror/Horror14.ogg", "horror/Horror17.ogg"}
} )

function ENT:Think()

	if !IsValidPlayer() then return end

	if SCP173IsBlinking() then
		if self.IsCurrentlyBeingSeen then
			self.IsCurrentlyBeingSeen = false
			net.Start("SCPDirectorCut173")
			net.WriteEntity(self)
			net.WriteBool(false)
			net.SendToServer()
		end
		return
	end

	local legsvis = util.PixelVisible(self:LocalToWorld(legsoffset), size, self.PixVisLegs)
	local middlevis = util.PixelVisible(self:LocalToWorld(middleoffset), size, self.PixVisMiddle)
	local headvis2 = util.PixelVisible(self:LocalToWorld(headoffset2), size2, self.PixVisHead2)
	local neckvis = util.PixelVisible(self:LocalToWorld(neckoffset), size2, self.PixVisNeck)
	local leftarm = util.PixelVisible(self:LocalToWorld(leftarmlocal), size2, self.PixVisLeftArm)
	local rightarm = util.PixelVisible(self:LocalToWorld(rightarmlocal), size2, self.PixVisRightArm)
	if CurTime() > self.VisibilityCheckCooldown then
		self.VisibilityCheckCooldown = CurTime() + 0.01
		local range = self:GetPos():Distance(LocalPlayer():GetPos())
		local sumvisibility = legsvis * middlevis * headvis2 * neckvis
		if self.VisibilityStopCheck > CurTime()  and (!self:IsItDark(self:GetPos()) or !self:IsItDark(self:GetPos()+middleoffset) or !self:IsItDark(self:GetPos()+headoffset)) and (legsvis > 0.1 or leftarm > 0.1 or rightarm > 0.1 or headvis2 > 0.1 or neckvis > 0.1 or middlevis > 0.1) then
			if range < 350 and CurTime() - self.PreviouslySeenTime > 60 and sumvisibility > 0.05 then
				surface.PlaySound("horror/Horror"..math.random(3,4)..".ogg")
				self.PreviouslySeenTime = CurTime()
			end
			if range < 150 and math.random(1, 700) == 1 then
				self:EmitSound("173/Rattle"..math.random(1,3)..".ogg")
			end
			if range < 150 and self.PreviouslySeenDistance > 200 then
				surface.PlaySound("SCP173Jumpscare")
			end
			self.PreviouslySeenDistance = range
			if !self.IsCurrentlyBeingSeen then
				self.IsCurrentlyBeingSeen = true
				net.Start("SCPDirectorCut173")
				net.WriteEntity(self)
				net.WriteBool(true)
				net.SendToServer()
			end
		elseif self.IsCurrentlyBeingSeen then
			self.IsCurrentlyBeingSeen = false
			net.Start("SCPDirectorCut173")
			net.WriteEntity(self)
			net.WriteBool(false)
			net.SendToServer()
		end
	end
end

function ENT:Draw()

	self:DrawModel()
	self.VisibilityStopCheck = CurTime() + 1.1868520530304 * RealFrameTime() * 10

end


end
list.Set("NPC", "npc_scp_173_directorcut", {
	Name = "SCP 173",
	Class = "npc_scp_173_directorcut",
	Category = "SCP CB Director's Cut",
	AdminOnly = false
})