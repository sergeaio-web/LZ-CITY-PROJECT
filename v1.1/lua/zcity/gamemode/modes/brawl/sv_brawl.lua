MODE.name = "brawl"
MODE.PrintName = "Бравл"
local MODE = MODE
MODE.ForBigMaps = true
MODE.OverideSpawnPos = true
MODE.LootSpawn = false

local cv_chance = CreateConVar("brawl_chance", "0.03", FCVAR_ARCHIVE, "Шанс запуска режима Brawl (от 0.0 до 1.0)")
local cv_round_time = CreateConVar("brawl_round_time", "316", FCVAR_ARCHIVE, "Длительность раунда в секундах")
local cv_max_lives = CreateConVar("brawl_max_lives", "5", FCVAR_ARCHIVE, "Количество жизней у игроков")
local cv_respawn_delay = CreateConVar("brawl_respawn_delay", "4", FCVAR_ARCHIVE, "Задержка перед возрождением (в секундах)")
local cv_melee_pick_time = CreateConVar("brawl_melee_pick_time", "10", FCVAR_ARCHIVE, "Время на выбор оружия ближнего боя (в секундах)")
local cv_berserk_after_deaths = CreateConVar("brawl_berserk_after_deaths", "2", FCVAR_ARCHIVE, "Необходимое количество смертей для получения роли Берсерка")
local cv_second_bonus_chance = CreateConVar("brawl_second_bonus_chance", "0.35", FCVAR_ARCHIVE, "Шанс получить второй бонусный предмет (от 0.0 до 1.0)")
local cv_armor_drop_chance = CreateConVar("brawl_armor_drop_chance", "0.16", FCVAR_ARCHIVE, "Шанс выдачи брони при спавне (от 0.0 до 1.0)")
local cv_berserk_chance = CreateConVar("brawl_berserk_chance", "0.3", FCVAR_ARCHIVE, "Шанс появления Берсерка в матче Brawl (от 0.0 до 1.0)")

MODE.Chance = cv_chance:GetFloat()
resource.AddSingleFile("sound/" .. (MODE.RoundMusic or "brawl/round_loop.ogg"))

for _, v in pairs({"start", "roundend", "melee_options", "pick_melee", "berserk_notice", "berserk_died", "screen_text"}) do
    util.AddNetworkString("brawl_" .. v)
end

local pI, TS, CR, IV, tS, mR, mr = player.Iterator, TEAM_SPECTATOR, CurrentRound, IsValid, timer.Simple, math.Rand, math.random
local T_W = {"weapon_hg_wrench", "weapon_hammer", "weapon_pocketknife", "weapon_hg_mug", "weapon_hg_cinderblock", "weapon_hg_cuestick", "weapon_hg_glassshard_taped", "weapon_screwdriver", "weapon_hg_razor", "weapon_brick", "weapon_hg_bottle", "weapon_table_leg"}
local T_M = {"weapon_hg_axe", "weapon_hatchet", "weapon_hatchethmcd", "weapon_hg_cleaver", "weapon_leadpipe", "weapon_hg_tonfa", "weapon_hg_pickaxe", "weapon_hg_pitchfork", "weapon_hg_extinguisher", "weapon_hg_shovel", "weapon_pan", "weapon_golfclub", "weapon_bayonet"}
local T_I = {"weapon_tomahawk", "weapon_tomahawkasspocket", "weapon_hg_spear", "weapon_hg_fireaxe", "weapon_batmetal"}

local BP = {
    {id = "high", w = 55, i = {"weapon_painkillers", "weapon_tourniquet", "weapon_bigbandage_sh"}},
    {id = "medium", w = 30, i = {"weapon_fentanyl", "weapon_morphine", "weapon_medkit_sh", "weapon_betablock"}},
    {id = "grenade", w = 15, i = {"weapon_hg_mk2_tpik", "weapon_hg_f1_tpik", "weapon_hg_rgd_tpik", "weapon_hg_molotov_tpik", "weapon_hg_flashbang_tpik", "weapon_bombvest", "weapon_hg_grenade_tpik"}}
}
local AP = {
    {c = "ent_armor_helmet7", w = 18}, {c = "ent_armor_helmet3", w = 18}, {c = "ent_armor_helmet2", w = 18},
    {c = "ent_armor_vest8", w = 18}, {c = "ent_armor_vest2", w = 18}, {c = "ent_armor_mask1", w = 9}, {c = "ent_armor_mask3", w = 1}
}

local function IsB() local r = CR and CR() return r and r.name == "brawl" end
local function IsSB(t) local r = CR and CR() return r and r.name == "brawl" and r.BrawlRoundToken == t end

local function WP(e)
    local t = 0
    for _, v in ipairs(e) do t = t + (v.w or 1) end
    if t <= 0 then return end
    local r, a = mR(0, t), 0
    for _, v in ipairs(e) do
        a = a + (v.w or 1)
        if r <= a then return v end
    end
    return e[#e]
end

local function CU(l, c)
    local t, o, m = table.Copy(l), {}, math.min(c, #l)
    for i = 1, m do
        local x = mr(#t)
        o[#o + 1] = t[x]
        table.remove(t, x)
    end
    return o
end

local function IsBA()
    for _, p in pI() do
        if p:Alive() and p:GetNWBool("BrawlActiveBerserk", false) then return true end
    end
    return false
end

local function GLC()
    local c = 0
    for _, p in pI() do
        if p:Alive() and (p.BrawlIsCop or p.BrawlIsVigilante) then c = c + 1 end
    end
    return c
end

local function HPL()
    for _, p in pI() do
        if p:Team() ~= TS and p:GetNWInt("BrawlLivesLeft", 0) == 1 then return true end
    end
    return false
end

local function EP(v)
    if isvector(v) then return v, Angle(0, 0, 0) end
    if istable(v) then return v.pos or v[1], v.ang or v[2] or Angle(0, 0, 0) end
end

function MODE.GuiltCheck() return 0, false end
function MODE:CanLaunch() return true end

local cached_spawns = nil
function MODE:GetSpawnPointRaw()
    if not cached_spawns then
        cached_spawns = ents.FindByClass("info_player_start")
        table.Add(cached_spawns, ents.FindByClass("info_player_deathmatch"))
        table.Add(cached_spawns, ents.FindByClass("info_player_terrorist"))
        table.Add(cached_spawns, ents.FindByClass("info_player_counterterrorist"))
        table.Add(cached_spawns, ents.FindByClass("info_player_rebel"))
        table.Add(cached_spawns, ents.FindByClass("info_player_combine"))
    end

    if cached_spawns and #cached_spawns > 0 then
        local sp = cached_spawns[mr(#cached_spawns)]
        if IsValid(sp) then
            return sp:GetPos(), sp:GetAngles()
        end
    end

    local f = zb.GetRandomSpawn and zb:GetRandomSpawn()
    if f then return EP(f) end
    return Vector(0,0,0), Angle(0,0,0)
end

function MODE:TeleportToRandomSpawn(p)
    local pos, ang = self:GetSpawnPointRaw()
    if not pos then return end
    tS(0, function()
        if not IV(p) or not p:Alive() or not IsB() then return end
        if hg and hg.tpPlayer then
            hg.tpPlayer(pos, p, 1, 0)
        else
            p:SetPos(pos)
        end
        if ang then p:SetEyeAngles(ang) end
    end)
end

function MODE:GetPlySpawn() return self:GetSpawnPointRaw() end

function MODE:GetTeamSpawn()
    local pos = self:GetSpawnPointRaw()
    if pos then return {pos}, {pos} end
    return {Vector(0,0,0)}, {Vector(0,0,0)}
end

function MODE:UpdateAliveCounter()
    local c = 0
    for _, p in pI() do
        if p:Team() ~= TS and p:Alive() then c = c + 1 end
    end
    SetGlobalInt("BrawlAliveCount", c)
end

function MODE:GetContenders()
    local c = {}
    for _, p in pI() do
        if p:Team() ~= TS and (p:Alive() or p:GetNWInt("BrawlLivesLeft", 0) > 0 or p.BrawlQueuedRespawn) then
            c[#c + 1] = p
        end
    end
    return c
end

function MODE:PickBonusCategory(ex)
    local p = {}
    for _, c in ipairs(BP) do
        if not ex[c.id] then p[#p + 1] = c end
    end
    return WP(p)
end

function MODE:GiveRandomBonusItems(p)
    local c = (mR(0, 1) <= cv_second_bonus_chance:GetFloat()) and 2 or 1
    local ex = {}
    for i = 1, c do
        local ctg = self:PickBonusCategory(ex)
        if not ctg then break end
        ex[ctg.id] = true
        local it = table.Random(ctg.i)
        if it then p:Give(it) end
    end
end

function MODE:GiveRandomArmor(p)
    if mR(0, 1) > cv_armor_drop_chance:GetFloat() or not hg or not hg.AddArmor then return end
    local pk = WP(AP)
    if pk then hg.AddArmor(p, pk.c) end
end

function MODE:ApplyMeleeChoice(p, wc)
    if not IV(p) or not p:Alive() or not IsB() or p.BrawlPickedMelee or not table.HasValue(p.BrawlMeleeOptions or {}, wc) then return end
    p.BrawlPickedMelee = true
    if not p:HasWeapon(wc) then p:Give(wc) end
    if p:HasWeapon(wc) then p:SelectWeapon(wc) end
end

function MODE:SendMeleeMenu(p)
    if not IV(p) or not p:Alive() then return end
    local l, o = p:GetNWInt("BrawlLivesLeft", cv_max_lives:GetInt()), nil
    o = CU(l <= 1 and T_I or (l <= 3 and T_M or T_W), 3)
    p.BrawlMeleeOptions = o
    p.BrawlPickedMelee = false

    local pick_time = cv_melee_pick_time:GetInt()

    net.Start("brawl_melee_options")
    net.WriteUInt(#o, 3)
    for _, c in ipairs(o) do net.WriteString(c) end
    net.WriteUInt(pick_time, 8)
    net.Send(p)

    local t, d = self.BrawlRoundToken, o[1]
    tS(pick_time, function()
        if IV(p) and p:Alive() and IsSB(t) and not p.BrawlPickedMelee then
            local r = CR()
            if r and r.name == "brawl" then r:ApplyMeleeChoice(p, d) end
        end
    end)
end

function MODE:TryAssignBerserk()
    if not self.BerserkEnabled or self.BerserkAssigned then return end
    local e = {}
    local required_deaths = cv_berserk_after_deaths:GetInt()
    for _, p in pI() do
        if p:Team() ~= TS and not p.BrawlQueuedBerserk and not p.BrawlHadBerserk and p:GetNWInt("BrawlLivesLeft", 0) > 0 then
            local d = p:GetNWInt("BrawlDeaths", 0)
            if d >= required_deaths then e[#e + 1] = {p = p, w = math.max(1, d)} end
        end
    end
    if #e > 0 then
        local pk = WP(e)
        if pk and IV(pk.p) then
            self.BerserkAssigned = true
            pk.p.BrawlQueuedBerserk = true
        end
    end
end

function MODE:SetupPlayerForBrawlSpawn(p, ir)
    if not IV(p) or not p:Alive() then return end
    p:SetSuppressPickupNotices(true)
    p.noSound = true
    p:StripWeapons()
    p:StripAmmo()
    p:SetPlayerClass("default")
    zb.GiveRole(p, "Brawler", Color(210, 170, 70))
    
    local inv = p:GetNetVar("Inventory", {})
    inv.Weapons = inv.Weapons or {}
    p:SetNetVar("Inventory", inv)
    if p.organism then p.organism.allowholster = true end

    self:TeleportToRandomSpawn(p)
    self:GiveRandomBonusItems(p)
    self:GiveRandomArmor(p)
    
    p.BrawlIsCop = false
    p.BrawlIsVigilante = false
    local hs = false

    if p.BrawlQueuedBerserk and not p.BrawlHadBerserk then
        if hg and hg.AddArmor then hg.AddArmor(p, "ent_armor_mask3") end
        p.BrawlQueuedBerserk, p.BrawlHadBerserk = false, true
        p:SetNWBool("BrawlActiveBerserk", true)
        p:SetPlayerClass("berserk")
        if p.organism then p.organism.berserk = 1 end
        
        p:SetNWString("BrawlRoleDesc", self:L("role_berserk"))
        
        net.Start("brawl_berserk_notice")
        net.WriteEntity(p)
        net.Broadcast()
        
        p:Give("weapon_hg_sledgehammer")
        hs = true
    else
        p:Give("weapon_hands_sh")
        p:SetNWString("BrawlRoleDesc", self:L("role_survivor"))
    end

    if not hs and IsBA() and GLC() == 0 and not p:GetNWBool("BrawlActiveBerserk", false) then
        local l = p:GetNWInt("BrawlLivesLeft", 0)
        if l == 1 then
            hs, p.BrawlIsCop = true, true
            p:SetPlayerClass("police")
            p:Give("weapon_hands_sh")
            p:Give("weapon_tranquilizer")
            p:Give("weapon_handcuffs")
            p:Give("weapon_handcuffs_key")
            p:Give("weapon_hg_tonfa")
            p:SetNWString("BrawlRoleDesc", self:L("role_cop"))
            
            net.Start("brawl_screen_text")
            net.WriteString(self:L("screen_cop_title"))
            net.WriteString(self:L("screen_cop_sub"))
            net.WriteFloat(6)
            net.Send(p)
        elseif l == 2 and not HPL() then
            hs, p.BrawlIsVigilante = true, true
            p:Give("weapon_hands_sh")
            p:Give("weapon_doublebarrel_short")
            p:SetNWString("BrawlRoleDesc", self:L("role_vigilante"))
            
            net.Start("brawl_screen_text")
            net.WriteString(self:L("screen_vigilante_title"))
            net.WriteString(self:L("screen_vigilante_sub"))
            net.WriteFloat(6)
            net.Send(p)
        end
    end

    if not hs then self:SendMeleeMenu(p) end
    p:SetNWFloat("BrawlRespawnAt", 0)

    tS(0, function()
        if IV(p) and p:Alive() then
            if p:GetNWBool("BrawlActiveBerserk", false) and p:HasWeapon("weapon_hg_sledgehammer") then
                p:SelectWeapon("weapon_hg_sledgehammer")
            elseif p:HasWeapon("weapon_hands_sh") then
                p:SelectWeapon("weapon_hands_sh")
            end
        end
    end)
    
    tS(0.1, function()
        if IV(p) then
            p.noSound = false
            p:SetSuppressPickupNotices(false)
        end
    end)
end

function MODE:Intermission()
    game.CleanUpMap()
    cached_spawns = nil 

    self.BrawlEnded = false
    self.BrawlRoundToken = (self.BrawlRoundToken or 0) + 1
    self.BrawlRoundStart = 0
    self.BrawlRoundEnd = 0
    self.NextAliveCounterUpdate = 0
    self.NextKillsUpdate = 0
    
    SetGlobalBool("BrawlEnded", false)
    SetGlobalFloat("BrawlRoundEnd", 0)
    SetGlobalInt("BrawlAliveCount", 0)
    
    self.BerserkEnabled = (mR(0, 1) <= cv_berserk_chance:GetFloat())
    self.BerserkAssigned = false

    local max_lives = cv_max_lives:GetInt()

    for _, p in pI() do
        if p:Team() ~= TS then p:SetupTeam(0) end
        p.BrawlQueuedRespawn, p.BrawlQueuedBerserk, p.BrawlHadBerserk, p.BrawlMeleeOptions, p.BrawlPickedMelee, p.BrawlIsCop, p.BrawlIsVigilante = false, false, false, nil, false, false, false
        p:SetNWBool("BrawlActiveBerserk", false)
        p:SetNWInt("BrawlLivesLeft", max_lives)
        p:SetNWInt("BrawlDeaths", 0)
        p:SetNWInt("BrawlKills", 0)
        p:SetNWFloat("BrawlRespawnAt", 0)
        p:SetNWString("BrawlRoleDesc", self:L("role_survivor"))
        p.BrawlHandcuffedTime = nil
    end
end

function MODE:RoundStart()
    self.BrawlRoundStart = CurTime()
    self.BrawlRoundEnd = CurTime() + cv_round_time:GetInt()
    SetGlobalFloat("BrawlRoundEnd", self.BrawlRoundEnd)
    SetGlobalBool("BrawlEnded", false)
    for _, p in pI() do p:Freeze(false) end
    net.Start("brawl_start")
    net.Broadcast()
    self:UpdateAliveCounter()
end

function MODE:GiveEquipment()
    tS(0.1, function()
        if not IsB() then return end
        local r = CR()
        if r and r.name == "brawl" then
            for _, p in pI() do
                if p:Alive() then r:SetupPlayerForBrawlSpawn(p, false) end
            end
            r:UpdateAliveCounter()
        end
    end)
end

function MODE:RoundThink()
    if self.BrawlEnded then return end

    if (self.NextAliveCounterUpdate or 0) <= CurTime() then
        self:UpdateAliveCounter()
        self.NextAliveCounterUpdate = CurTime() + 0.5 
    end

    if self.BerserkEnabled and not self.BerserkAssigned then
        self:TryAssignBerserk()
    end

    for _, p in pI() do
        if p:Alive() and p:GetNWBool("BrawlActiveBerserk", false) then
            if p.organism then p.organism.berserk = 1 end
            if p:HasWeapon("weapon_hands_sh") then
                p:StripWeapon("weapon_hands_sh")
            end

            if p:GetNetVar("handcuffed", false) then
                p.BrawlHandcuffedTime = p.BrawlHandcuffedTime or CurTime()
                if CurTime() - p.BrawlHandcuffedTime >= 10 then
                    p.BrawlHandcuffedTime = nil
                    p:SetNWInt("BrawlLivesLeft", 0)
                    p:Kill()
                    PrintMessage(HUD_PRINTTALK, self:L("cuffed", p:Nick()))
                end
            else
                p.BrawlHandcuffedTime = nil
            end
        end
    end
end

function MODE:ShouldRoundEnd()
    if self.BrawlEnded then return false end
    if self.BrawlRoundEnd > 0 and CurTime() >= self.BrawlRoundEnd then
        self.BrawlEndReason = "time"
        return true
    end
    if #self:GetContenders() <= 1 then
        self.BrawlEndReason = "last_survivor"
        return true
    end
    return false
end

function MODE:EndRound()
    if self.BrawlEnded then return end
    self.BrawlEnded = true
    SetGlobalBool("BrawlEnded", true)

    local c = self:GetContenders()
    local w = (#c == 1 and c[1]) or nil
    local d = not IV(w)

    local mvp_player
    local max_kills = 0

    for _, ply in pI() do
        local kills = ply:GetNWInt("BrawlKills", 0)
        if kills > max_kills then
            max_kills = kills
            mvp_player = ply
        end
    end

    if IV(mvp_player) and max_kills > 0 then
        PrintMessage(HUD_PRINTTALK, self:L("mvp_chat", mvp_player:Nick(), max_kills))
    end

    tS(0.5, function()
        net.Start("brawl_roundend")
        net.WriteBool(d)
        net.WriteString(IV(w) and w:Nick() or "")
        net.Broadcast()
    end)

    if IV(w) then
        w:GiveExp(mr(20, 35))
        w:GiveSkill(mR(0.12, 0.18))
    end
end

function MODE:PlayerDeath(p, i, a)
    if not IV(p) then return end
    if self.BrawlEnded then return end 

    local wasBerserk = p:GetNWBool("BrawlActiveBerserk", false) 

    if wasBerserk then
        p:SetNWBool("BrawlActiveBerserk", false) 
        net.Start("brawl_berserk_died")
        net.WriteString(p:Nick())
        net.Broadcast()

        tS(0.1, function()
            if not self.BrawlEnded then
                for _, cop in pI() do
                    if cop:Alive() and (cop.BrawlIsCop or cop.BrawlIsVigilante) then
                        cop.BrawlIsCop = false
                        cop.BrawlIsVigilante = false
                        cop:Spawn()
                        local r = CR()
                        if r and r.name == "brawl" then
                            r:SetupPlayerForBrawlSpawn(cop, true)
                        end
                    end
                end
            end
        end)
    end

    p.BrawlIsCop, p.BrawlIsVigilante, p.BrawlMeleeOptions, p.BrawlPickedMelee = false, false, nil, false
    
    local d = p:GetNWInt("BrawlDeaths", 0) + 1
    local l = math.max(p:GetNWInt("BrawlLivesLeft", cv_max_lives:GetInt()) - 1, 0)
    
    if wasBerserk then
        l = 0
    end

    p:SetNWInt("BrawlDeaths", d)
    p:SetNWInt("BrawlLivesLeft", l)
    p:SetNWFloat("BrawlRespawnAt", 0)

    if l > 0 then
        local delay = cv_respawn_delay:GetInt()
        local ra, t = CurTime() + delay, self.BrawlRoundToken
        p.BrawlQueuedRespawn = true
        p:SetNWFloat("BrawlRespawnAt", ra)
        
        tS(delay, function()
            if not IV(p) or not IsSB(t) then return end
            local r = CR()
            if not r or r.name ~= "brawl" or r.BrawlEnded or p:GetNWInt("BrawlLivesLeft", 0) <= 0 or p:Alive() then return end
            p.BrawlQueuedRespawn = false
            p:Spawn()
            tS(0, function()
                if IV(p) and p:Alive() and IsSB(t) then
                    local r2 = CR()
                    if r2 and r2.name == "brawl" then
                        r2:SetupPlayerForBrawlSpawn(p, true)
                        r2:UpdateAliveCounter()
                    end
                end
            end)
        end)
    else
        p.BrawlQueuedRespawn = false
        p:SetNWString("BrawlRoleDesc", self:L("out_of_round"))
    end

    if self.BerserkEnabled and not self.BerserkAssigned then self:TryAssignBerserk() end
    self:UpdateAliveCounter()
end

function MODE:CanSpawn() end

net.Receive("brawl_pick_melee", function(_, p)
    if not IV(p) or not IsB() then return end
    local r = CR()
    if r and r.name == "brawl" then
        local wc = net.ReadString()
        if wc and wc ~= "" then r:ApplyMeleeChoice(p, wc) end
    end
end)

hook.Add("HomigradDamage", "Brawl_KillRegistration", function(ply, dmgInfo, hitgroup, ent)
    local round = CurrentRound and CurrentRound()
    if not round or round.name ~= "brawl" then return end
    if GetGlobalBool("BrawlEnded", false) then return end

    local attacker, victim = dmgInfo:GetAttacker(), ply
    if !attacker or !IsValid(attacker) or (IsValid(attacker) and !attacker:IsPlayer()) then
        attacker = ply:GetPhysicsAttacker()
    end

    if not IsValid(attacker) or not attacker:IsPlayer() then return end
    if not IsValid(victim) or not victim:IsPlayer() then return end
    if attacker == victim then return end

    timer.Simple(0, function()
        if IsValid(attacker) and IsValid(victim) and not victim:Alive() then
            local current_kills = attacker:GetNWInt("BrawlKills", 0)
            attacker:SetNWInt("BrawlKills", current_kills + 1)
        end
    end)
end)