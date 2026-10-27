local MODE = MODE

local VOTE_TIME = 12
local ROUND_TIME = 480

local HANDS_CLASS = "weapon_hands_sh"

--------------------------------------------------
-- PLAYER AND NEXTBOT SETTINGS
--------------------------------------------------

local PLAYER_WALK_SPEED = 180
local PLAYER_RUN_SPEED = 320

local NEXTBOT_PREP_TIME = 15

local SCP173_CLASS = "npc_scp_173_directorcut"


--------------------------------------------------
-- OPTIONS
--------------------------------------------------

local SCP_OPTIONS = {

    [1] = {
        id = 1,
        name = "SCP-173",
        description = "SCP-173 [Z-CITY SUPPORT]",
        class = SCP173_CLASS
    },


    [2] = {
        id = 2,
        name = "SCP-096",
        description = "[DrGBase] SCP-096:SL Nextbot",

        classes = {

            "drg_scp096",
            "drg_scp_096",
            "npc_scp096",
            "npc_scp_096",
            "drg_scp_096_sl",
            "drg_scp096_sl"

        }

    },


    [3] = {
        id = 3,
        name = "Кот в шляпе",
        description = "Cat in the Hat NextBot",
        class = "npc_cith_normal"
    },


    [4] = {
        id = 4,
        name = "Bon The Rabbit",
        description = "[Gentoi] Bon The Rabbit NextBot",

        classes = {

            "npc_drgbase_thebonwalten",
            "drg_bon_the_rabbit",
            "drg_bon_rabbit",
            "drg_bon",
            "npc_bon_the_rabbit",
            "npc_bon_rabbit",
            "npc_bon",
            "bon_the_rabbit",
            "bon_rabbit",
            "pill_bon_the_rabbit"

        }

    },


    [5] = {

        id = 5,

        name = "G-Man",

        description = "Chasing G-Man NextBot",

        class = "chasing_gman"

    }


}



--------------------------------------------------
-- NETWORK
--------------------------------------------------

util.AddNetworkString("nextbot_mode_vote")

util.AddNetworkString("nextbot_mode_vote_state")

util.AddNetworkString("nextbot_mode_result")

util.AddNetworkString("nextbot_mode_round_started")



--------------------------------------------------
-- MODE CHECK
--------------------------------------------------

local function IsNextbotMode()


    if not isfunction(CurrentRound) then
        return false
    end



    local ok,round = pcall(CurrentRound)



    if not ok or not round then
        return false
    end



    return round.name == "nextbot"


end



--------------------------------------------------
-- COUNT VOTES
--------------------------------------------------

local function CountVotes(self)


    local counts = {


        [1] = 0,

        [2] = 0,

        [3] = 0,

        [4] = 0,

        [5] = 0


    }



    for _,choice in pairs(self.Votes or {}) do


        if counts[choice] then

            counts[choice] =
                counts[choice] + 1

        end


    end



    return counts


end



--------------------------------------------------
-- SEND VOTE STATE
--------------------------------------------------

local function SendVoteState(self,recipient)


    local counts =
        CountVotes(self)



    net.Start(
        "nextbot_mode_vote_state"
    )


    net.WriteBool(
        self.VoteOpen == true
    )


    net.WriteFloat(
        self.VoteEndTime or 0
    )


    net.WriteUInt(
        counts[1],
        16
    )


    net.WriteUInt(
        counts[2],
        16
    )


    net.WriteUInt(
        counts[3],
        16
    )


    net.WriteUInt(
        counts[4],
        16
    )


    net.WriteUInt(
        counts[5],
        16
    )


    net.WriteString(

        self.SelectedNextbot
        and self.SelectedNextbot.name
        or ""

    )



    if IsValid(recipient) then

        net.Send(recipient)

    else

        net.Broadcast()

    end


end
--------------------------------------------------
-- ROUND START MESSAGE
--------------------------------------------------

local function SendRoundStarted()

    net.Start(
        "nextbot_mode_round_started"
    )

    net.Broadcast()

end



--------------------------------------------------
-- FIND SCP-096
--------------------------------------------------

local function FindSCP096Class()


    for _,className in ipairs(
        SCP_OPTIONS[2].classes
    ) do


        if scripted_ents.GetStored(className) then

            return className

        end


    end



    for className in pairs(
        scripted_ents.GetList() or {}
    ) do


        if not isstring(className) then
            continue
        end



        local lower =
            string.lower(className)



        if string.find(lower,"096",1,true)
        and (
            string.find(lower,"scp",1,true)
            or
            string.find(lower,"drg",1,true)
        )
        and scripted_ents.GetStored(className)
        then

            return className

        end


    end



    return nil


end



--------------------------------------------------
-- FIND BON
--------------------------------------------------

local function FindBonClass()


    local option =
        SCP_OPTIONS[4]



    for _,className in ipairs(
        option.classes or {}
    ) do


        if scripted_ents.GetStored(className) then

            return className

        end


    end



    for className in pairs(
        scripted_ents.GetList() or {}
    ) do


        if not isstring(className) then
            continue
        end



        local lower =
            string.lower(className)



        if
            (
                string.find(lower,"bon",1,true)
                or
                string.find(lower,"rabbit",1,true)
            )
            and
            scripted_ents.GetStored(className)
        then

            return className

        end


    end



    return nil


end



--------------------------------------------------
-- SPAWN POSITION
--------------------------------------------------

local function GetSpawnPosition()


    local spawnPos



    if zb and isfunction(zb.GetRandomSpawn) then


        local ok,result =
            pcall(
                function()

                    return zb:GetRandomSpawn()

                end
            )


        if ok then

            spawnPos = result

        end


    end



    if IsValid(spawnPos)
    and spawnPos.GetPos
    then

        spawnPos =
            spawnPos:GetPos()

    end



    if isvector(spawnPos) then

        return spawnPos +
        Vector(0,0,12)

    end



    local spawnClasses = {


        "info_player_start",

        "info_player_deathmatch",

        "info_player_rebel",

        "info_player_counterterrorist",

        "gmod_player_start"


    }



    local positions = {}



    for _,className in ipairs(
        spawnClasses
    ) do


        for _,ent in ipairs(
            ents.FindByClass(className)
        ) do


            if IsValid(ent) then

                positions[#positions+1] =
                    ent:GetPos()

            end


        end


    end



    if #positions == 0 then

        return nil

    end



    return table.Random(positions)
    +
    Vector(0,0,12)


end



--------------------------------------------------
-- CREATE ENTITY
--------------------------------------------------

local function TrySpawnClass(className,pos)


    if not isstring(className)
    or className == ""
    then

        return nil

    end



    local ent =
        ents.Create(className)



    if not IsValid(ent) then


        ErrorNoHalt(

            "[Nextbot Mode] Failed create "
            ..
            className
            ..
            "\n"

        )


        return nil

    end



    local ok,err =
        pcall(
            function()


                ent:SetPos(pos)

                ent:Spawn()

                ent:Activate()


            end
        )



    if not ok then


        ErrorNoHalt(

            "[Nextbot Mode] Spawn error "
            ..
            tostring(err)
            ..
            "\n"

        )


        if IsValid(ent) then

            ent:Remove()

        end



        return nil

    end



    if not IsValid(ent) then

        return nil

    end



    return ent


end
--------------------------------------------------
-- SPAWN SELECTED NEXTBOT
--------------------------------------------------

local function SpawnChosenNextbot(self)


    local selected =
        self.SelectedNextbot
        or SCP_OPTIONS[1]



    local spawnPos =
        GetSpawnPosition()



    if not spawnPos then


        self.ActiveNextbot = nil

        self.RoundEndReason =
            "spawn_failed"



        ErrorNoHalt(
            "[Nextbot Mode] No spawn position found.\n"
        )


        return false


    end



    local ent



    --------------------------------------------------
    -- SCP 096
    --------------------------------------------------

    if selected.id == 2 then



        local className =
            FindSCP096Class()



        if className then

            ent =
                TrySpawnClass(
                    className,
                    spawnPos
                )

        end



        if not IsValid(ent) then


            PrintMessage(

                HUD_PRINTTALK,

                "[Нексбот] SCP-096 недоступен. Используется SCP-173."

            )



            ent =
                TrySpawnClass(
                    SCP173_CLASS,
                    spawnPos
                )



            selected =
                SCP_OPTIONS[1]


        end



    --------------------------------------------------
    -- CAT
    --------------------------------------------------

    elseif selected.id == 3 then



        ent =
            TrySpawnClass(

                SCP_OPTIONS[3].class,

                spawnPos

            )



    --------------------------------------------------
    -- BON
    --------------------------------------------------

    elseif selected.id == 4 then



        local className =
            FindBonClass()



        if className then


            ent =
                TrySpawnClass(
                    className,
                    spawnPos
                )


        end



    --------------------------------------------------
    -- G-MAN
    --------------------------------------------------

    elseif selected.id == 5 then



        ent =
            TrySpawnClass(

                SCP_OPTIONS[5].class,

                spawnPos

            )



    --------------------------------------------------
    -- SCP 173 DEFAULT
    --------------------------------------------------

    else



        ent =
            TrySpawnClass(

                SCP173_CLASS,

                spawnPos

            )



    end





    if not IsValid(ent) then



        self.ActiveNextbot = nil

        self.RoundEndReason =
            "spawn_failed"



        ErrorNoHalt(

            "[Nextbot Mode] Could not spawn selected nextbot.\n"

        )


        return false


    end





    self.ActiveNextbot =
        ent

--------------------------------------------------
-- NEXTBOT PREPARATION TIME
--------------------------------------------------

ent:SetNWBool(
    "NextbotPreparing",
    true
)


ent:SetNotSolid(true)


ent:SetMoveType(
    MOVETYPE_NONE
)



PrintMessage(
    HUD_PRINTCENTER,
    "Нексбот появился! У вас есть 15 секунд."
)



timer.Simple(
    NEXTBOT_PREP_TIME,
    function()


        if not IsValid(ent) then
            return
        end



        ent:SetNWBool(
            "NextbotPreparing",
            false
        )


        ent:SetNotSolid(false)


        ent:SetMoveType(
    MOVETYPE_NONE
)


ent:SetNotSolid(false)

if ent.Activate then
    ent:Activate()
end



        PrintMessage(
            HUD_PRINTCENTER,
            "ОХОТА НАЧАЛАСЬ!"
        )


    end
)

    self.SelectedNextbot =
        selected




    ent:SetNWString(
        "NextbotModeName",
        selected.name
    )


    ent:SetNWBool(
        "NextbotModeEntity",
        true
    )



    print(

        "[Nextbot Mode] Spawned "
        ..
        selected.name
        ..
        " ("
        ..
        ent:GetClass()
        ..
        ")"

    )



    return true


end





--------------------------------------------------
-- FINISH VOTE
--------------------------------------------------

local function FinishVote(self)


    if not self.VoteOpen then

        return

    end



    self.VoteOpen = false



    timer.Remove(
        "nextbot_mode_vote_timeout"
    )



    local counts =
        CountVotes(self)



    local highest =
        math.max(

            counts[1],

            counts[2],

            counts[3],

            counts[4],

            counts[5]

        )



    local winners = {}



    for _,option in ipairs(
        SCP_OPTIONS
    ) do



        if counts[option.id] == highest then


            winners[#winners+1] =
                option


        end


    end



    self.SelectedNextbot =
        table.Random(winners)



    SendVoteState(self)



    PrintMessage(

        HUD_PRINTTALK,

        "[Нексбот] Выбран "
        ..
        self.SelectedNextbot.name
        ..
        ". Раунд длится 8 минут!"

    )


end





--------------------------------------------------
-- MODE
--------------------------------------------------

function MODE:CanLaunch()

    return true

end



function MODE:Intermission()


    timer.Remove(
        "nextbot_mode_vote_timeout"
    )



    self.Votes = {}

    self.VoteOpen = true


    self.VoteEndTime =
        CurTime()+VOTE_TIME



    self.SelectedNextbot = nil

    self.ActiveNextbot = nil


    self.RoundEndReason = nil

    self.RoundStartTime = nil




    for _,ply in player.Iterator() do


        if not IsValid(ply) then

            continue

        end



        if ply:Team()
        ==
        TEAM_SPECTATOR
        then

            continue

        end



        ply:SetupTeam(0)


    end




    SendVoteState(self)





    timer.Create(

        "nextbot_mode_vote_timeout",

        VOTE_TIME,

        1,

        function()



            if not IsNextbotMode() then

                return

            end



            FinishVote(self)



        end

    )



end
--------------------------------------------------
-- EQUIPMENT
--------------------------------------------------

function MODE:GiveEquipment()

end



function MODE:GiveWeapons()

end



--------------------------------------------------
-- HANDS + PLAYER SPEED
--------------------------------------------------

local function GiveHands(ply)

    if not IsValid(ply)
    or not ply:IsPlayer()
    then
        return
    end


    if not ply:Alive() then
        return
    end



    timer.Simple(0.2,function()

        if not IsValid(ply)
        or not ply:Alive()
        then
            return
        end



        -----------------------------------
        -- REMOVE OLD WEAPONS
        -----------------------------------

        ply:StripWeapons()
        ply:StripAmmo()



        -----------------------------------
        -- GIVE ZCITY HANDS
        -----------------------------------

        local hands = ply:Give(
            HANDS_CLASS
        )


        if IsValid(hands) then

            ply:SelectWeapon(
                HANDS_CLASS
            )

        else

            print(
                "[Nextbot] ERROR: weapon_hands_sh не выдан!"
            )

        end



        -----------------------------------
        -- SPEED
        -----------------------------------

        ply:SetWalkSpeed(
            PLAYER_WALK_SPEED
        )


        ply:SetRunSpeed(
            PLAYER_RUN_SPEED
        )



    end)

end





--------------------------------------------------
-- ROUND START
--------------------------------------------------

function MODE:RoundStart()


    self.RoundStartTime =
        CurTime()



    self.RoundEndReason = nil




    if self.VoteOpen then

        FinishVote(self)

    end




    if not self.SelectedNextbot then


        self.SelectedNextbot =
            table.Random(
                SCP_OPTIONS
            )


    end




    for _,ply in player.Iterator() do


    if not IsValid(ply) then
        continue
    end


    if not ply:Alive() then
        continue
    end


    if ply:Team() == TEAM_SPECTATOR then
        continue
    end



    GiveHands(ply)


    ply:Freeze(false)


    ply:SetWalkSpeed(
        PLAYER_WALK_SPEED
    )


    ply:SetRunSpeed(
        PLAYER_RUN_SPEED
    )


end   -- ВОТ ЭТОГО НЕ ХВАТАЛО



SendRoundStarted()



SpawnChosenNextbot(self)



end





--------------------------------------------------
-- RESPAWN
--------------------------------------------------

function MODE:PlayerSpawn(ply)


    if not IsNextbotMode() then

        return

    end



    timer.Simple(

        0.5,

        function()



            if not IsValid(ply)
            or not ply:IsPlayer()
            then

                return

            end




            if not IsNextbotMode() then

                return

            end




            if not ply:Alive()
            then

                return

            end





            GiveHands(ply)



        end

    )


end





--------------------------------------------------
-- ALIVE PLAYERS
--------------------------------------------------

function MODE:CheckAlivePlayers()


    local alive = {}



    for _,ply in player.Iterator() do



        if not IsValid(ply) then

            continue

        end



        if not ply:Alive() then

            continue

        end



        if ply:Team()
        ==
        TEAM_SPECTATOR
        then

            continue

        end



        alive[#alive+1] =
            ply



    end



    return alive



end





--------------------------------------------------
-- ROUND END
--------------------------------------------------

function MODE:ShouldRoundEnd()



    if self.RoundEndReason ==
    "spawn_failed"
    then

        return true

    end




    if not self.RoundStartTime then

        return nil

    end





    local survivors =
        self:CheckAlivePlayers()



    if #survivors <= 0 then


        self.RoundEndReason =
            "nextbot"


        return true


    end




    if not IsValid(
        self.ActiveNextbot
    )
    then


        self.RoundEndReason =
            "survivors"



        return true


    end



    return nil


end





function MODE:RoundThink()



    if not self.RoundStartTime then

        return

    end




    if not IsValid(
        self.ActiveNextbot
    )
    then


        self.RoundEndReason =
            "survivors"


    end



end





function MODE:PlayerDeath(ply)

end





--------------------------------------------------
-- PICKUPS
--------------------------------------------------

function MODE:PlayerCanPickupWeapon()

    if IsNextbotMode()
    and zb.ROUND_STATE == 1
    then

        return false

    end

end



function MODE:PlayerCanPickupItem()

    if IsNextbotMode()
    and zb.ROUND_STATE == 1
    then

        return false

    end

end



function MODE:PlayerCanDropWeapon()

    if IsNextbotMode()
    and zb.ROUND_STATE == 1
    then

        return false

    end

end





--------------------------------------------------
-- RECEIVE VOTES
--------------------------------------------------

net.Receive(

"nextbot_mode_vote",

function(_,ply)



    if not IsValid(ply)
    or not IsNextbotMode()
    then

        return

    end




    local round =
        CurrentRound()



    if not round
    or not round.VoteOpen
    then

        return

    end





    local choice =
        net.ReadUInt(3)




    if choice < 1
    or choice > 5
    then

        return

    end




    local id =
        ply:SteamID64()



    round.Votes =
        round.Votes or {}



    round.Votes[id] =
        choice




    SendVoteState(round)



end

)





--------------------------------------------------
-- LATE JOIN
--------------------------------------------------

hook.Add(

"PlayerInitialSpawn",

"NextbotMode_SendVoteState",

function(ply)



    timer.Simple(

        2,

        function()



            if not IsValid(ply)
            or not IsNextbotMode()
            then

                return

            end




            local round =
                CurrentRound()



            if round then


                SendVoteState(
                    round,
                    ply
                )


            end



        end

    )

end

)





--------------------------------------------------
-- REMOVE DROPPED WEAPONS
--------------------------------------------------

hook.Add(

"PlayerDroppedWeapon",

"NextbotMode_RemoveDroppedWeapons",

function(ply,wep)



    if not IsNextbotMode() then

        return

    end




    if IsValid(wep)
    and zb.ROUND_STATE == 1
    then


        SafeRemoveEntity(wep)


    end



end

)





--------------------------------------------------
-- END ROUND
--------------------------------------------------

function MODE:EndRound()


    timer.Remove(
        "nextbot_mode_vote_timeout"
    )



    if IsValid(
        self.ActiveNextbot
    )
    then

        self.ActiveNextbot:Remove()

    end



    self.ActiveNextbot = nil



    self.VoteOpen = false



    self.RoundStartTime = nil




    net.Start(
        "nextbot_mode_result"
    )


    net.WriteString(
        self.RoundEndReason
        or
        "survivors"
    )


    net.Broadcast()




    self.SelectedNextbot = nil



    self.RoundEndReason = nil



end





print(
"[Nextbot] sv_nextbot.lua loaded with G-Man support."
)