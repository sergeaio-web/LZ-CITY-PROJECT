AddCSLuaFile()
ENT.Base = "base_nextbot"
ENT.Type = "nextbot"
ENT.AutomaticFrameAdvance = true
ENT.Category = "SCP CB Director's Cut"
ENT.Spawnable = false
ENT.Editable = false
ENT.AdminOnly = false
ENT.PrintName = "Base"
ENT.Author = ""
ENT.Contact = ""
ENT.PhysgunDisabled = false
ENT.IsSCPCBDCNextbot = true
ENT.SpawnHealth = 2000
ENT.Faction = {"FACTION_SCP"}
ENT.IsHatedBy = {["example_class"] = true, ["example_class2"] = true}
ENT.CollisionBounds = {Vector(-6.5, -6.5, 0), Vector(6.5, 6.5, 36)}
ENT.IsKillable = false
ENT.Model = ""
ENT.KillIcon = "HUD/killicons/default"
ENT.FOV = 180
ENT.VisionRange = 2048
ENT.Omniscience = false
ENT.HeadBone = ""
ENT.IsNeckSnappableBy173 = false
if SERVER then

util.AddNetworkString("SCPCBDCVoiceChat")
SCPCBDCNextbots = {}
SCPCBDCNextbotsSnappableNeck = {}
local average_room_length = 600
local teleporttoenemies = CreateConVar("scpcbdcnextbots_teleporttoenemies", 1, FCVAR_NONE, "", 0, 1)
local teleportonlytoplayer = CreateConVar("scpcbdcnextbots_teleportonlytoplayer", 1, FCVAR_NONE, "", 0, 1)
local chancetoteleport = CreateConVar("scpcbdcnextbots_chanceofteleport", 0.5, FCVAR_NONE, "", 0, 1)
local teleporttoclosest = CreateConVar("scpcbdcnextbots_teleporttoclosest", 0, FCVAR_NONE, "", 0, 1)
local patrolnearby = CreateConVar("scpcbdcnextbots_patrolnearby", 1, FCVAR_NONE, "", 0, 1)

function ENT:InitializePathfinding()

	self.MovePath = Path("Follow")
	self.MovePath:SetMinLookAheadDistance(10000)
	self.Goals = {}
	self.CurrentGoal = 2
	self.LastComputedPos = vector_origin
	self.ShouldRecompute = true
	self.ShouldCheckUnreachable = true
	self.ReachableEntities = {}
	
end

function ENT:InitializeMovement()

	self.MoveTime = CurTime()
	self.StuckCounter = 0
	self.TurningCoefficent = 0.1
	self.ForceObstacleAvoid = 0
	self.loco:SetDeathDropHeight(10)
	self.loco:SetClimbAllowed(false)
	self.loco:SetJumpGapsAllowed(false)	

end

function ENT:InitializePatrol()

	self.PatrolPos = vector_origin
	self.PatrolWait = CurTime()
	self.IsPatroling = false

end

function ENT:InitializeAnimations()

	self.LastAnimation = ""
	self.ForceAnimationTime = -1
	self.ForceAnimation = ""
	self.ForceAnimationPlaybackRate = 1
	self.ForceAnimationUniqueID = 0
	self.ForceAnimationLastFunc = function() end

end

function ENT:InitializeEnemy()

	self.CurrentEnemy = NULL
	self.LastSeenEnemyPosition = vector_origin
	self.IsCheckingEnemyPos = false

end

function ENT:InitializeSelf()

	self:SetModel(self.Model)
	self:SetName(self.PrintName)
	self:AddFlags(FL_OBJECT + FL_NPC)
	self:SetMaxHealth(self.SpawnHealth)
	self:SetHealth(self.SpawnHealth)
	self:SetCollisionBounds(self.CollisionBounds[1], self.CollisionBounds[2])
	self.Height = self.CollisionBounds[2].z - self.CollisionBounds[1].z
	self.DiagonalLength = self.CollisionBounds[2]:Distance2D(self.CollisionBounds[1])
	self.Length = self.DiagonalLength / math.sqrt(2)

end

function ENT:InitializeSounds()

	self.SoundChannelsPlaying = {}
	self.SoundChannels = {}

end

function ENT:InitializeVision()

	self:SetFOV(self.FOV)
	self:SetMaxVisionRange(self.VisionRange)

end

function ENT:InitializeDoor()

	self.LastDoor = NULL
	self.DoorCooldown = CurTime()

end

function ENT:Initialize()

	self:InitializePathfinding()
	self:InitializeMovement()
	self:InitializePatrol()
	self:InitializeAnimations()
	self:InitializeEnemy()
	self:InitializeSelf()
	self:InitializeSounds()
	self:InitializeVision()
	self:InitializeDoor()
	table.insert(SCPCBDCNextbots, self)
	if self.IsNeckSnappableBy173 then
		table.insert(SCPCBDCNextbotsSnappableNeck, self)
	end
	self:CallOnRemove("RemoveFromTable", function(ent) self:StopAllSoundChannels() table.RemoveByValue(SCPCBDCNextbots, self) table.RemoveByValue(SCPCBDCNextbotsSnappableNeck, self)  end)
	if isfunction(self.CustomInitialize) then self:CustomInitialize() end

end

-- UTILS --

local function IsAIDisabled()

	return GetConVar("ai_disabled"):GetBool() or GetConVar("nb_stop"):GetBool() or false

end

function ENT:IsAIDisabled()

	return IsAIDisabled()

end

function ENT:GetRooms(n)

	return average_room_length * n

end

function ENT:GetTurningCoefficent()

	return self.TurningCoefficent

end

function ENT:CanTeleport()

	return teleporttoenemies:GetBool(), chancetoteleport:GetFloat()

end

function ENT:FindEntityToTeleport(minroom, maxroom)

	local entstotp = ents.FindByFunction(function(ent)
		if !self:IsValidEnemy(ent) then return false end 
		if teleportonlytoplayer:GetBool() and !ent:IsPlayer() then return false end
		local range = self:GetRangeTo(ent)
		if range < self:GetRooms(minroom) then return false end
		if maxroom and range > self:GetRooms(maxroom) then return false end
		return true
	end)
	if entstotp[1] == nil then return end
	if teleporttoclosest:GetBool() then 
		return table.GetClosestEntity(entstotp, self:GetPos()) 
	else 
		return entstotp[math.random(#entstotp)] 
	end

end

function ENT:GetSpotToTeleport(ent)

	local spots = self:FindSpots({type = "hiding", pos = ent:GetPos(), radius = 1250, stepup = 200, stepdown = 200})
	if spots[1] == nil then return end
	for k, v in ipairs(spots) do
		local spot = v.vector
		local spotdistance = self:GetRangeTo(spot)
		if !self:TraceHullAccuratelyFrom(spot, spot).Hit and spotdistance > average_room_length and ent:GetPos():Distance(spot) > average_room_length and !ent:IsLineOfSightClear(spot) and !ent:VisibleVec(spot) and !ent:IsLineOfSightClear(spot + vector_up*self.CollisionBounds[2].z) and !ent:VisibleVec(spot + vector_up*self.CollisionBounds[2].z) then return spot end
	end

end

function ENT:TeleportToEnemy(minroom, maxroom)

	local enttotp = self:FindEntityToTeleport(minroom, maxroom)
	if !IsValid(enttotp) then return end
	local spotpos = self:GetSpotToTeleport(enttotp)
	if !spotpos then return end
	self:SetPos(spotpos)

end

function ENT:Timer(time, func)

	timer.Simple(time, function()
		if !IsValid(self) then return end
		func()
	end)

end

function ENT:CBEyePos()

	local bone = self:LookupBone(self.HeadBone)
	if !isnumber(bone) then return self:WorldSpaceCenter() end
	return self:GetBoneMatrix(bone):GetTranslation()

end

function ENT:CanSeeEntity(ent)

	if self.Omniscience then return true end
	if !self:Visible(ent) then return false end
	local fov = self:GetFOV()
	local range = self:GetMaxVisionRange()
	return util.IsPointInCone( ent:GetPos(), self:CBEyePos(), self:GetForward(), math.cos( math.rad( fov / 2) ), range )

end

function ENT:CanGoToPos(pos)

	local length = self.Length / 2
	local dis = self:GetPos():Distance(pos)
	if dis <= length then return true end
	local step = vector_up*self.loco:GetStepHeight()
	local dir = (pos-self:GetPos()):GetNormalized()
	for i = length, dis, length do
		local newpos = self:GetPos() + dir*i
		local groundcheck = self:TraceWalkableLineFrom(newpos+step, newpos-step)
		if !groundcheck.Hit then return false end
	end
	return true

end

function ENT:CanGoToPosNewFrom(pos1, pos2)

	local length = self.Length / 2
	local dis = pos1:Distance2D(pos2)
	if dis <= length then return true end
	local step = vector_up*self.loco:GetStepHeight()
	local zoffset = self.loco:GetStepHeight()
	local dir = (Vector(pos2.x, pos2.y, pos1.z)-pos1):GetNormalized()
	local finalpos
	for i = length, dis, length do
		local newpos = pos1 + dir*i + vector_up*zoffset
		local groundcheck = self:TraceWalkableLineFrom(newpos, newpos-step*2)
		if !groundcheck.Hit then
			return false
		end
		if groundcheck.StartSolid and groundcheck.HitWorld then
			if self:TraceWalkableLineFrom(newpos, newpos).HitWorld then return false end
		else
			zoffset = zoffset + (groundcheck.StartSolid and 0 or (self.loco:GetStepHeight() - groundcheck.StartPos:Distance(groundcheck.HitPos)) )
		end
		finalpos = groundcheck.HitPos
	end
	if finalpos:Distance2D(pos2) > self.Length or math.abs(finalpos.z - pos2.z) > self.loco:GetStepHeight() then
		return false
	end
	return true

end

function ENT:CanGoToPosNew(pos)

	return self:CanGoToPosNewFrom(self:GetPos(), pos)

end

function ENT:CanGoToEntityFrom(pos, ent)

	local length = self.Length / 2
	local pos2 = ent:GetPos()
	local dis = pos:Distance2D(pos2)
	if dis <= length then return true end
	local step = vector_up*self.loco:GetStepHeight()
	local zoffset = self.loco:GetStepHeight()
	local dir = (Vector(pos2.x, pos2.y, pos.z)-pos):GetNormalized()
	local finalpos
	for i = length, dis, length do
		local newpos = pos + dir*i + vector_up*zoffset
		if ent:IsPointInBounds(newpos) then return true end
		local groundcheck = self:TraceWalkableLineFrom(newpos, newpos-step*2)
		if !groundcheck.Hit then
			return false
		end
		if groundcheck.StartSolid and groundcheck.HitWorld then
			if self:TraceWalkableLineFrom(newpos, newpos).HitWorld then return false end
		else
			zoffset = zoffset + (groundcheck.StartSolid and 0 or (self.loco:GetStepHeight() - groundcheck.StartPos:Distance(groundcheck.HitPos)) )
		end
		finalpos = groundcheck.HitPos
	end
	if finalpos:Distance2D(pos2) > self.Length or math.abs(finalpos.z - pos2.z) > self.loco:GetStepHeight() then
		return false
	end
	return true

end

function ENT:CanGoToEntity(ent)

	return self:CanGoToEntityFrom(self:GetPos(), ent)
	
end

function ENT:CanReachEntity(ent, cooldown, randomoffset)

	if !cooldown then return self:CanGoToEntity(ent) end
	if !self.ReachableEntities[ent] or CurTime() - self.ReachableEntities[ent][2] >= cooldown then
		self.ReachableEntities[ent] = {self:CanGoToEntity(ent), (randomoffset and (cooldown / 10 * math.random(-1, 1)) or 0) + CurTime()}
	end
	return self.ReachableEntities[ent][1]
	
end

function ENT:GetPosOnNav(pos)

	local area = navmesh.GetNearestNavArea(pos)
	if !IsValid(area) then return pos end
	return area:GetClosestPointOnArea(pos)

end

function ENT:GetPosForPatrol()

	if patrolnearby:GetBool() then return self:GetPosOnNav(self:GetPos() + VectorRand(-1250, 1250)) end
	local area = navmesh.GetAllNavAreas()[math.random(#navmesh.GetAllNavAreas())]
	if !IsValid(area) then return self:GetPos() + VectorRand(-2000, 2000) end
	local pos = area:GetCenter()
	return pos

end

function ENT:TraceHullAccurately(pos, scale)

	return self:TraceHullAccuratelyFrom(self:GetPos(), pos, scale)

end

function ENT:TraceHullAccuratelyFrom(pos1, pos2, scale)

    scale = scale or 1
    local bound1, bound2 = self:GetCollisionBounds()
	local bound1z = bound1.z
	local bound2z = bound2.z
    local step = vector_up*self.loco:GetStepHeight()
	bound1 = bound1 * scale
	bound2 = bound2 * scale
	bound1.z = bound1z
    bound2.z = bound2z - self.loco:GetStepHeight()
    return util.TraceHull( {
    start = pos1+step,
    endpos = pos2+step,
    mins = bound1,
    maxs = bound2,
    filter = self,
    mask = self:GetSolidMask(),
    collisiongroup = self:GetCollisionGroup()
    } )

end
function ENT:TraceWalkableLineFrom(pos1, pos2, ...)

	return util.TraceLine( {
    start = pos1,
    endpos = pos2,
    filter = {self, ...},
    mask = self:GetSolidMask(),
    collisiongroup = self:GetCollisionGroup()
    } )
	
end

function ENT:TraceWalkableLine(pos, ...)

	return self:TraceWalkableLineFrom(self:GetPos(), pos, ...)
	
end

function ENT:IsValidEnemy( ent, includeprops )

	if !IsValid(ent) then return false end
	if !isstring(ent:GetModel()) or !string.find(ent:GetModel(), ".mdl") then return false end	
	if istable(ent.Faction) and ent.Faction[1] == self.Faction[1] and (!istable(ent.IsHatedBy) or !ent.IsHatedBy[self:GetClass()]) then return false end
	if (!includeprops or ent:IsLivingEntity()) and !IsAliveEntity(ent) then return false end
	if ent:IsFlagSet(FL_NOTARGET) then return false end
	if ent:IsPlayer() and GetConVar("ai_ignoreplayers"):GetBool() then return false end
	return true

end

function ENT:FindEnemy()

	local out = {}
	for k, v in pairs(ents.GetAlive()) do
		if !self:IsValidEnemy( v ) then continue end
		if !self:CanSeeEntity( v ) then continue end
		table.insert(out, v)	
	end
	return table.GetClosestEntity(out, self:GetPos())

end

-- UTILS --

-- MOVEMENT --

function ENT:OnLandOnGround()

	self.ShouldRecompute = true

end

function ENT:ShouldCompute(pos)

    if self.ShouldRecompute then return true end
	local goal = self.Goals[self.CurrentGoal]
	if istable(goal) then
	    local lastgoaltype = goal.type
        if lastgoaltype == 0 and !self.loco:IsOnGround() then return false end
	end	
	return self:GetRangeTo(pos) * 4 <= self.LastComputedPos:DistToSqr(pos) / 4

end

function ENT:ShouldComputeThrough(pos)

    if self.ShouldRecompute then return true end
	local goal = self.Goals[self.CurrentGoal-1]
	if istable(goal) then
	    local lastgoaltype = goal.type
        if lastgoaltype == 2 or lastgoaltype == 1 then return false end
	end
	local goal = self.Goals[self.CurrentGoal]
	if istable(goal) then
	    local lastgoaltype = goal.type
        if lastgoaltype == 0 and !self.loco:IsOnGround() then return false end
	end
	return self:GetRangeTo(pos) * 4  <= self.LastComputedPos:DistToSqr(pos) / 4

end

function ENT:Recompute(pos)

    self.ShouldRecompute = false
	self.LastComputedPos = pos
	self.MovePath:Compute(self, pos)
	self.Goals = {}
	self.CurrentGoal = 2
	self.ShouldCheckUnreachable = true
	local allsegments = self.MovePath:GetAllSegments()
	if !istable(allsegments) then return end
	for k, v in ipairs(allsegments) do
		table.insert(self.Goals, v)
	end

end

function ENT:ComputeAndMove(pos, speed, distancehoriz, distancevertical, stopfunc, ignore)

	if isfunction(stopfunc) then
		local res, amount = table.Pack(stopfunc())
		if amount > 0 then return unpack(res) end
	end
    distancehoriz = distancehoriz or 10
	distancevertical = distancevertical or distancehoriz
	speed = speed * engine.TickInterval()
    local disxy = self:GetPos():Distance2D(pos)
	local disz = math.abs(self:GetPos().z - pos.z)
	if disxy <= distancehoriz and disz <= distancevertical then return "reached" end
    if !ignore and self:ShouldCompute(pos) then
		self:Recompute(pos) 
	end
	if !ignore and table.IsEmpty(self.Goals) and navmesh.IsLoaded() then return "no path" end
	//self.MovePath:Draw()
	local goaltype
	local goalpos
	local goaldirnoz
	local isgoingdown = false
	local isgoingup = false
	local isfinalgoal = false
	if self.CurrentGoal > #self.Goals or ignore then
	    goaltype = 0
	    goalpos = pos
		isfinalgoal = true
	else
	    goaltype = self.Goals[self.CurrentGoal].type
	    goalpos = self.Goals[self.CurrentGoal]["pos"]	
	end
	local lastgoal = self.Goals[self.CurrentGoal-1]
	if istable(lastgoal) then
		if !ignore and self.ShouldCheckUnreachable and !self:CanGoToPosNewFrom(lastgoal.pos, goalpos) then return "unreachable" end
	    if lastgoal.type == 1 then
		    isgoingdown = true
		elseif lastgoal.type == 2 then
		    isgoingup = true
		end
	end
	goaldirnoz = goalpos - self:GetPos()
	goaldirnoz.z = 0
	goaldirnoz = goaldirnoz:GetNormalized()
	self.ShouldCheckUnreachable = false
	local shouldslowrotating = !ignore and self:TraceHullAccurately(goalpos, 0.1).HitWorld
	local turncoefficent = self:GetTurningCoefficent()
	local fixangle = vector_origin
	local forcefixangle = nil
	local truelength = self.Length / 2
	local leftcheck = self:GetPos()+goaldirnoz:Right()*truelength + goaldirnoz*truelength
	local rightcheck = self:GetPos()-goaldirnoz:Right()*truelength + goaldirnoz*truelength
	local lefttrace = self:TraceHullAccuratelyFrom(leftcheck, leftcheck)
	local righttrace = self:TraceHullAccuratelyFrom(rightcheck, rightcheck)
	if lefttrace.Hit then fixangle = fixangle - goaldirnoz:Right() end
	if righttrace.Hit then 
		fixangle = fixangle + goaldirnoz:Right() 
		if fixangle:IsZero() and !isfinalgoal and ( (IsDoor(lefttrace.Entity) and lefttrace.Entity:IsOpened()) or (IsDoor(righttrace.Entity) and righttrace.Entity:IsOpened()) ) then
			self.ForceObstacleAvoid = CurTime() + (1 / speed)
		end
	end
	if self.ForceObstacleAvoid > CurTime() then
		local dir = self.Goals[self.CurrentGoal].forward
		local dirright = dir:Right()
		local mult = self:GetPos():Distance2D(goalpos)
		for i = 1, 8 do
			local backcheck = goalpos-dir*i*mult
			if !self:TraceHullAccurately(backcheck, 0.25).Hit and !self:TraceHullAccuratelyFrom(goalpos, backcheck, 0.25).Hit then forcefixangle = -dir break end
			local rightcheck = goalpos+dirright*i*mult
			if !self:TraceHullAccurately(rightcheck, 0.25).Hit and !self:TraceHullAccuratelyFrom(goalpos, rightcheck, 0.25).Hit then forcefixangle = dirright break end
			local leftcheck = goalpos-dirright*i*mult
			if !self:TraceHullAccurately(leftcheck, 0.25).Hit and !self:TraceHullAccuratelyFrom(goalpos, leftcheck, 0.25).Hit then forcefixangle = -dirright break end
		end	
	end
	self:PointAtVectorSmooth(forcefixangle and (self:GetPos()+forcefixangle*10) or (goalpos+fixangle*100) , shouldslowrotating and (turncoefficent / 10) or turncoefficent, true)
	self:AdvanceForward(speed)
	local goaldisxy = self:GetPos():Distance2D(goalpos)
	local goaldisz = math.abs(self:GetPos().z - goalpos.z)
	if goaldisxy <= speed / turncoefficent and goaldisz <= self.Height then 
		self.CurrentGoal = self.CurrentGoal + 1 
		self.ShouldCheckUnreachable = true 
		self.ForceObstacleAvoid = 0
	end
	return "moving"

end

function ENT:ComputeAndMoveThrough(pos, speed, distancehoriz, distancevertical, stopfunc, ignore)

	if isfunction(stopfunc) then
		local res, amount = table.Pack(stopfunc())
		if amount > 0 then return unpack(res) end
	end
    distancehoriz = distancehoriz or 10
	distancevertical = distancevertical or distancehoriz
	speed = speed * engine.TickInterval()
    local disxy = self:GetPos():Distance2D(pos)
	local disz = math.abs(self:GetPos().z - pos.z)
	if disxy <= distancehoriz and disz <= distancevertical then return "reached" end
    if self:ShouldComputeThrough(pos) and !ignore then
	    self:Recompute(pos)
	end
	if !ignore and table.IsEmpty(self.Goals) and navmesh.IsLoaded() then return "no path" end
	//self.MovePath:Draw()
	local goaltype
	local goalpos
	local goaldir
	local isgoingdown = false
	local isgoingup = false
	local isfinalgoal = false
	local isairborne = false
	if self.CurrentGoal > #self.Goals or ignore then
	    goaltype = 0
	    goalpos = pos
		isfinalgoal = true
	else
	    goaltype = self.Goals[self.CurrentGoal].type
	    goalpos = self.Goals[self.CurrentGoal]["pos"]
	end
	local lastgoal = self.Goals[self.CurrentGoal-1]
	if istable(lastgoal) then
	    if lastgoal.type == 1 then
		    isgoingdown = true
		elseif lastgoal.type == 2 then
		    isgoingup = true
		end
	end
	isairborne = goaltype == 0 and !self.loco:IsOnGround() and !isgoingup
	goaldir = (goalpos - self:GetPos()):GetNormalized()
	local turncoefficent = self:GetTurningCoefficent()
	self:PointAtVectorSmooth(goalpos, turncoefficent, true)
	self.loco:SetVelocity(vector_origin)
	self:SetVelocity(vector_origin)
	self:SetAbsVelocity(vector_origin)
	local truestepheight = math.Clamp( 20 * (1 - math.abs(goaldir.z) ) , 0, 20)
	self.loco:SetStepHeight(truestepheight)
	self.MoveTime = CurTime() + 0.1
	if isairborne then
		if math.abs(goalpos.z - self:GetPos().z) > truestepheight and !self:VisibleVec(goalpos+vector_up*self.loco:GetStepHeight()) then
			self:SetPos( self:GetPos() + (vector_up*goaldir.z):GetNormalized()*speed )
		else
			self:SetPos( self:GetPos() + self:GetForward()*speed + (vector_up*goaldir.z):GetNormalized()*speed )
		end
	else
		self:SetPos( self:GetPos() + self:GetForward()*speed + (vector_up*goaldir.z):GetNormalized()*speed )
	end
	self:SetGroundEntity(game.GetWorld())
	local goaldisxy = self:GetPos():Distance2D(goalpos)
	local goaldisz = math.abs(self:GetPos().z - goalpos.z)
	if goaldisxy <= speed / turncoefficent and goaldisz <= self.Height then self.CurrentGoal = self.CurrentGoal + 1 end
	return "moving"

end

local function BooltoNum(bool)

	if bool == true then return 1 end
	return 0

end

function ENT:AdvanceForward(speed)

    self.MoveTime = CurTime() + 0.1
	local step = vector_up*self.loco:GetStepHeight()
	local trace = self:TraceHullAccurately(self:GetPos()+self:GetForward()*speed)
	if trace.Hit then
		self.StuckCounter = math.Clamp(self.StuckCounter + 1, 0, 300)
		--[[ Pushes objects away. Disabled for now because of greatest physics engine of all time Havok. Why when you push an object with little force it goes fucking backwards???
		local physobj = trace.Entity:GetPhysicsObjectNum(trace.PhysicsBone)
		if IsValid(physobj) then
			//local forceoffset, angleoffset = physobj:CalculateForceOffset(self:GetForward() * 39.37 * speed * physobj:GetMass() / math.log(physobj:GetMass()*2), trace.HitPos)
			local forceoffset, angleoffset = physobj:CalculateForceOffset(self:GetForward() * 39.37 * speed, trace.HitPos)
			print(forceoffset, angleoffset)
			physobj:ApplyForceCenter(forceoffset)
			physobj:ApplyTorqueCenter(physobj:LocalToWorldVector(angleoffset))
		end
		]]
	else
		self.StuckCounter = math.Clamp(self.StuckCounter - 2, 0, 300)
	end
	local mult = speed / 1.3
	local pos = trace.HitPos - step + trace.HitNormal * mult * math.abs(trace.HitNormal:Dot(trace.Normal))
	if trace.StartSolid then
		local length = self.Length
		local stuckfixadd = vector_origin
		local fromrighttoleft = self:TraceHullAccuratelyFrom(self:GetPos()+self:GetRight()*length, self:GetPos()-self:GetRight()*length)
		local fromlefttoright = self:TraceHullAccuratelyFrom(self:GetPos()-self:GetRight()*length, self:GetPos()+self:GetRight()*length)
		local fromforwardtoback = self:TraceHullAccuratelyFrom(self:GetPos()+self:GetForward()*length, self:GetPos()-self:GetForward()*length)
		local frombacktoforward = self:TraceHullAccuratelyFrom(self:GetPos()-self:GetForward()*length, self:GetPos()+self:GetForward()*length)
		pos = pos + fromrighttoleft.HitNormal * mult + fromlefttoright.HitNormal * mult + fromforwardtoback.HitNormal * mult + frombacktoforward.HitNormal * mult
	end
	self:SetPos(pos)
	return trace.Hit

end

-- MOVEMENT --

-- INTERACTIONS --

function ENT:IsDynamicDoorClosed(door)

	if door:LookupSequence("Closed") == -1 then return false end
	if door:GetSequence() != door:LookupSequence("Closed") and door:GetSequence() != door:LookupSequence("Idle")  then return false end
	return true

end

function ENT:OpenDynamicDoor(door)

	local button = door.SCPCBDCIsOpenedBy
	if !IsValid(button) then return end
	if !self:IsDynamicDoorClosed(door) then return end
	button:Use(self, self)
	for k, v in pairs(door.SCPCBDCIsOpenedByMult) do
		k:Fire("Lock")
	end
	door:ResetSequence("Closed")
	self:Timer(0, function() door:ResetSequence("Closed") door:SetPlaybackRate(0) button:Fire("Lock") end)
	self:Timer(door:SequenceDuration(door:LookupSequence("Open")) + 0.05, function()
		door:ResetSequence("Closed") 
		door:SetPlaybackRate(0)
		for k, v in pairs(door.SCPCBDCIsOpenedByMult) do
			k:Fire("Lock")
		end		
	end)
	
end

function ENT:DestroyDoor(door)

	if IsDoor(door) then
		local doeshavemodel = string.find(door:GetModel(), ".mdl") or string.StartsWith(door:GetModel(), "*")
		local pos = door:GetPos()
		local angles = door:GetAngles()
		local doeshavechildren = IsValid(door:GetChildren()[1])
		local model = (doeshavemodel and door:GetModel()) or (doeshavechildren and door:GetChildren()[1]:GetModel()) or nil
		if !model then return end
		local skin = (doeshavemodel and door:GetSkin()) or (doeshavechildren and door:GetChildren()[1]:GetSkin()) or 0			
		SafeRemoveEntity(door)
		local prop = ents.Create("prop_physics")
		prop:SetPos(pos)
		prop:SetAngles(angles)
		prop:SetModel(model)
		prop:SetSkin(skin)
		prop:Spawn()
		prop:SetCollisionGroup(2)
		for i = 0, prop:GetPhysicsObjectCount() - 1 do
			local phys = prop:GetPhysicsObjectNum(i)
			phys:EnableMotion(true)
			phys:ApplyForceCenter(self:GetForward() * phys:GetMass() * 39.37 * 10)
		end		
	elseif door:GetClass() == "prop_dynamic" and IsValid(door.SCPCBDCIsOpenedBy) and !door.SCPDC096Destroyed and self:IsDynamicDoorClosed(door) then
		local snap = (door:GetPos() - self:GetPos()):Angle():SnapTo("y", 90)
		local pos = door:GetPos() + snap:Forward()*75 + vector_up
		if !util.IsInWorld( pos ) then return end
		door:SetAngles(snap)
		door:EmitSound("173/DoorSparks.ogg")
		door:EmitSound("096/DoorBang.ogg")
		local hookname = "096DCDoorBush"..door:EntIndex()
		local startangle = snap
		local endangle = snap + Angle(90, 0, 0)
		hook.Add("Think", hookname, function()
			if !IsValid(door) or util.QuickTrace(door:GetPos()+door:GetUp()*96-door:GetForward()*4, door:GetForward()*6, door).HitWorld then hook.Remove("Think", hookname) return end
			door:SetAngles(door:GetAngles()+Angle(6, 0, 0))
		end)
		self:OpenDynamicDoor(door)
		door:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
		door.SCPDC096Destroyed = true
	end

end

function ENT:DestroyObstacles(radius)

	radius = radius or 16
	for k, v in ipairs(ents.FindInSphere( self:WorldSpaceCenter(), radius )) do
		if v:IsLivingEntity() then continue end
		v:TakeDamage(math.huge, self, self)
		self:DestroyDoor(v)
		constraint.RemoveAll( v )
		for i = 0, v:GetPhysicsObjectCount() - 1 do
			local phys = v:GetPhysicsObjectNum(i)
			phys:EnableMotion(true)
			phys:ApplyForceCenter(self:GetForward() * phys:GetMass() * 39.37 * 10)
		end
	end
	
end

function ENT:DCOpenDoor(door, speed, unlock, closeafter)

	if door:GetClass() == "prop_dynamic" then
		if IsValid(door:GetParent()) and IsDoor(door:GetParent()) then
			if CurTime() > self.DoorCooldown or door != self.LastDoor then
				self.LastDoor = door
				self.DoorCooldown = CurTime() + 1
				local button = door:GetParent().SCPCBDCIsOpenedBy
				if !IsValid(button) then 
					button = door:GetParent() 
					self:RLOpenDoor(button, speed, unlock, closeafter) 
				end
				if unlock then
					button:Fire("UnLock")
				end
				button:Fire("Press", nil, 0, self, self)
				if !closeafter then return end
				self:Timer(closeafter, function()
					if !IsValid(button) then return end
					button:Fire("Press", nil, 0, self, self)
				end)
			end
		elseif IsValid(door.SCPCBDCIsOpenedBy) then
			local button = door.SCPCBDCIsOpenedBy
			if unlock then
				button:Fire("UnLock")
			end				
			button:Use(self, self)
			if !closeafter then return end				
			self:Timer(closeafter, function()
				if !IsValid(button) then return end
				button:Use(self, self)
			end)			
		end
	end
	self:RLOpenDoor(door, speed, unlock, closeafter)

end

-- INTERACTIONS --

-- SOUNDS --

function ENT:UpdateSounds() end

function ENT:RegisterSoundChannel(channel, sounds)

	self.SoundChannels[channel] = sounds
	self.SoundChannelsPlaying[channel] = 0

end

function ENT:IsSoundChannelPlaying(channel)

	return self.SoundChannelsPlaying[channel] > CurTime()

end

function ENT:PlaySoundChannel(channel, ignore, interrupt, ...)

	if !ignore and self:IsSoundChannelPlaying(channel) then return end
	if interrupt then self:StopSoundChannel(channel) end
	local sound = self.SoundChannels[channel][math.random(#self.SoundChannels[channel])]
	self.SoundChannelsPlaying[channel] = CurTime() + SoundDuration(sound)
	self:EmitSound(sound, ...)

end

function ENT:StopSoundChannel(channel)

	for k, v in ipairs(self.SoundChannels[channel]) do
		self:StopSound(v)
		self.SoundChannelsPlaying[channel] = 0
	end

end

function ENT:StopAllSoundChannels()

	for channel, sounds in pairs(self.SoundChannels) do
		self:StopSoundChannel(channel)
	end

end

hook.Add("EntityEmitSound", "SCPCBDCHearing", function(data)

	for k, v in ipairs(SCPCBDCNextbots) do
		if isfunction(v.OnSound) then v:OnSound(data) end
	end

end)

net.Receive("SCPCBDCVoiceChat", function(len, ply)

	for k, v in ipairs(SCPCBDCNextbots) do
		if isfunction(v.OnVoiceChatHeard) then v:OnVoiceChatHeard(ply) end
	end

end)

-- SOUNDS --

-- ANIMATIONS --

function ENT:CustomAnimations() end

function ENT:UpdateAnimations()

	local anim, playbackrate, forcecycle = self:CustomAnimations()
	playbackrate = playbackrate or 1
	forcecycle = forcecycle or -1
	if self:IsPlayingAnimations() then
		anim = self.ForceAnimation
		playbackrate = self.ForceAnimationPlaybackRate
		forcecycle = -1
	end
	if !anim then return end
	self:SetPlaybackRate(playbackrate)	
	self:SetSequence(self:LookupSequence(anim))	
    if self.LastAnimation != anim then
		if (self:SequenceDuration(self:LookupSequence(self.LastAnimation)) != self:SequenceDuration(self:LookupSequence(anim))) or self:GetAnimInfo(self:LookupSequence(anim)).flags != 1 or self:GetAnimInfo(self:LookupSequence(self.LastAnimation)).flags != 1 then
			self:ResetSequenceInfo()
			self:SetCycle(0)
		end		
		self.LastAnimation = anim
    end
	if forcecycle != -1 then
		self:SetCycle(forcecycle)
	end

end

function ENT:ForcePlayAnimation(anim, playbackrate, time, func)

	playbackrate = playbackrate or 1
	local animtime = self:SequenceDuration(self:LookupSequence(anim)) / playbackrate
	time = (istable(time) and animtime * time[1]) or time or animtime
	self.ForceAnimation = anim
	self.ForceAnimationTime = CurTime() + time
	self.ForceAnimationPlaybackRate = playbackrate
	self.ShouldRecompute = true
	if isfunction(func) then
		self:Timer(time, func)
	end

end

function ENT:IsPlayingAnimation(anim)

	return self:IsPlayingAnimations() and self.ForceAnimation == anim
	
end

function ENT:IsPlayingAnimations()

	return self.ForceAnimationTime > CurTime()
	
end

function ENT:StopAnimations()

	self.ForceAnimationTime = -1
	self.ForceAnimation = ""
	self.ForceAnimationPlaybackRate = 1
	if isfunction(self.ForceAnimationLastFunc) then self.ForceAnimationLastFunc() end
	self.ForceAnimationLastFunc = function() end

end

-- ANIMATIONS --

-- BEHAVIOUR --

function ENT:PreThink() end

function ENT:AnimationThink() end

function ENT:PostThink() end

function ENT:Think()

	self:UpdateAnimations()
	self:UpdateSounds()
	self:PreThink()
	if IsAIDisabled() then return end
	self:AnimationThink()
	if self:IsPlayingAnimations() then return end
	self:PostThink()
	
end

function ENT:RunBehaviour() end

-- BEHAVIOUR --

-- DAMAGE --

function ENT:OnInjured(dmginfo)

	self:CustomOnInjured(dmginfo)
	local att = dmginfo:GetAttacker()
	if IsValid(att) and ((att:GetClass() == "trigger_hurt" and string.find(att:GetName(), "tesla")) or att:GetClass() == "sent_tesla_gate") then self:OnTeslaHit(dmginfo) end
	if !self.IsKillable then
		self:SetHealth(self:GetMaxHealth())
		dmginfo:SetDamage(0)
		self:SetHealth(self:GetMaxHealth())
	end
	
end


function ENT:OnKilled( dmginfo )

	hook.Call( "OnNPCKilled", GAMEMODE, self, dmginfo:GetAttacker(), dmginfo:GetInflictor() )
	
	self:OnDeath(dmginfo)

end

function ENT:OnDeath(dmginfo) end

function ENT:OnNeckSnapped(scp173) end

function ENT:CustomOnInjured(dmginfo) end

function ENT:OnTeslaHit(dmginfo) end

-- DAMAGE --

end
if CLIENT then

hook.Add("PostRender", "STOPHIDING", function()

	if !system.HasFocus() then return end
	if !gui.IsGameUIVisible() then return end
	if math.random(1, 10000) != 1 then return end
	local ent = table.GetClosestEntity(ents.FindByFunction(function(ent) if ent.IsSCPCBDCNextbot then return true end return false end), LocalPlayer():GetPos(), 175)
	if !IsValid(ent) then return end
	RunConsoleCommand("gamemenucommand",  "resumegame")
	LocalPlayer():PrintMessage( 4, "STOP HIDING." )
	surface.PlaySound("horror/Horror15.ogg")
	
end)


hook.Add("PlayerStartVoice", "SCPCBDCListening", function(ply, plyindex)

	if ply == LocalPlayer() then
		timer.Create("SCPCBDCListening", 0.1, 0, function()
			if LocalPlayer():VoiceVolume() >= 0.25 then
				net.Start("SCPCBDCVoiceChat")
				net.SendToServer()
			end
		end)
	end

end)

hook.Add("PlayerEndVoice", "SCPCBDCListening", function(ply)

	if ply == LocalPlayer() then
		timer.Remove("SCPCBDCListening")
	end

end)

function ENT:IsItDark(vec)

	if LocalPlayer():FlashlightIsOn() and IsPointInFlashlight(vec) then return false end
	for k, v in ipairs(RLibraryProjectedTextures) do
		if IsValid(v) and v:GetBrightness() > 0 and v:IsPointInside(vec) then return false end
	end
	for k, v in ipairs(ents.FindByClass("gmod_lamp")) do
		if v:GetOn() and v:GetBrightness() > 0 and util.IsPointInCone( vec, v:GetPos(), v:GetForward(), math.cos( math.rad( v:GetLightFOV() / 2) ), v:GetDistance() ) then return false end
	end
	local number = 0
	for k, v in pairs(GetLightColor(vec)) do
        if v <= 0.00033 then
            number = number + 1
        end
    end
    if number < 6 then return false end
	return true

end

function ENT:AddKillIcon()

	killicon.Add( self.ClassName, self.KillIcon, Color( 255, 80, 0, 255 ) )

end

function ENT:AddLanguage()

	language.Add( self.ClassName, self.Language or self.PrintName)

end

function ENT:Initialize()

	self:AddKillIcon()
	self:AddLanguage()
	if isfunction(self.CustomInitialize) then self:CustomInitialize() end

end

end

function SCPCBDCAddNPC(ENTdata)

	list.Set("NPC", string.Replace(ENT.Folder, "entities/", ""), {
	Name = ENT.PrintName,
	Class = string.Replace(ENT.Folder, "entities/", ""),
	Category = "SCP CB Director's Cut",
	AdminOnly = false
	})

end