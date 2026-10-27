ENT.Base = "base_brush"
ENT.Type = "brush"

-- Called when the entity first spawns
function ENT:Initialize()
	local w = self.max.x - self.min.x
	local l = self.max.y - self.min.y
	local h = self.max.z - self.min.z
	self.PointName = self.PointName or "Alpha"

	local min = Vector(0 - (w / 2), 0 - (l / 2), 0 - (h / 2))
	local max = Vector(w / 2, l / 2, h / 2)

	self:DrawShadow(false)
	self:SetCollisionBounds(min, max)
	self:SetSolid(SOLID_BBOX)
	self:SetCollisionGroup(COLLISION_GROUP_WORLD)
	self:SetMoveType(0)
	self:SetTrigger(true)
end

hg = hg or {}
hg.smo = hg.smo or {}

-- Called when an entity touches me
function ENT:StartTouch(ent)
	local ent = ent:IsRagdoll() and hg.RagdollOwner(ent) or ent
	--print("Лизнул яйца ")
	if IsValid(ent) and ent:IsPlayer() and ent:Alive() then
		hg.smo[self.PointName] = hg.smo[self.PointName] or {}
		hg.smo[self.PointName][ent] = ent
	end
end

function ENT:EndTouch(ent)
	local ent = ent:IsRagdoll() and hg.RagdollOwner(ent) or ent
	--print("не любит яйца")
	if IsValid(ent) and ent:IsPlayer() and ent:Alive() then
		hg.smo[self.PointName] = hg.smo[self.PointName] or {}
		hg.smo[self.PointName][ent] = nil
	end
end
