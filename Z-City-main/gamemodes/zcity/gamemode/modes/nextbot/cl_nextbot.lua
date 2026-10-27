local MODE = MODE

local voteFrame
local voteEndTime = 0

local votes173 = 0
local votes096 = 0
local votesCith = 0
local votesBon = 0
local votesGman = 0

local voteOpen = false
local selectedName = ""
local introActive = false

local voteButtons = {}

--------------------------------------------------
-- OPTIONS
--------------------------------------------------

local OPTIONS = {

    {
        id = 1,
        name = "SCP-173",
        subtitle = "Z-CITY SUPPORT",
        model = "models/scp/173.mdl",
        accent = Color(255,100,190),

        camPos = Vector(100,0,40),
        lookAt = Vector(0,0,38),
        fov = 30
    },


    {
        id = 2,
        name = "SCP-096",
        subtitle = "DrGBase NextBot",
        model = "models/scp_096/scp_096_final.mdl",
        accent = Color(255,65,145),

        camPos = Vector(145,0,72),
        lookAt = Vector(0,0,73),
        fov = 35
    },


    {
        id = 3,
        name = "Кот в шляпе",
        subtitle = "Cat in the Hat NextBot",
        class = "npc_cith_normal",

        model = nil,

        accent = Color(255,155,70),

        camPos = Vector(145,0,65),
        lookAt = Vector(0,0,62),
        fov = 35
    },


    {
        id = 4,
        name = "Bon The Rabbit",
        subtitle = "[Gentoi] Bon The Rabbit",

        classes = {
            "drg_bon_the_rabbit",
            "drg_bon_rabbit",
            "drg_bon",
            "npc_bon_the_rabbit",
            "npc_bon_rabbit",
            "npc_bon",
            "bon_the_rabbit",
            "bon_rabbit",
            "pill_bon_the_rabbit"
        },

        model = nil,

        accent = Color(100,170,255),

        camPos = Vector(145,0,65),
        lookAt = Vector(0,0,62),
        fov = 35
    },


    {
        id = 5,
        name = "G-Man",
        subtitle = "Chasing G-Man NextBot",

        class = "chasing_gman",

        model = "models/player/gman_high.mdl",

        accent = Color(80,150,255),

        camPos = Vector(100,0,65),
        lookAt = Vector(0,0,55),
        fov = 40
    }

}


--------------------------------------------------
-- FONTS
--------------------------------------------------

surface.CreateFont("NextbotMode_Title", {
    font = "Roboto",
    size = 30,
    weight = 800,
    antialias = true
})


surface.CreateFont("NextbotMode_Button", {
    font = "Roboto",
    size = 22,
    weight = 700,
    antialias = true
})


surface.CreateFont("NextbotMode_Small", {
    font = "Roboto",
    size = 18,
    weight = 500,
    antialias = true
})


surface.CreateFont("NextbotMode_ModelLabel", {
    font = "Roboto",
    size = 14,
    weight = 700,
    antialias = true
})


--------------------------------------------------
-- CLOSE
--------------------------------------------------

local function CloseVote()

    if IsValid(voteFrame) then
        voteFrame:Remove()
    end

    voteFrame = nil
    voteButtons = {}

end


--------------------------------------------------
-- SEND VOTE
--------------------------------------------------

local function SendVote(choice)

    if not voteOpen then
        return
    end


    surface.PlaySound("buttons/button14.wav")


    net.Start("nextbot_mode_vote")

        net.WriteUInt(choice,3)

    net.SendToServer()

end


--------------------------------------------------
-- COUNT
--------------------------------------------------

local function GetVoteCount(id)

    if id == 1 then
        return votes173

    elseif id == 2 then
        return votes096

    elseif id == 3 then
        return votesCith

    elseif id == 4 then
        return votesBon

    end


    return votesGman

end


--------------------------------------------------
-- BUTTON UPDATE
--------------------------------------------------

local function UpdateVoteButtons()

    for _,button in ipairs(voteButtons) do

        if IsValid(button) then
            button:SetEnabled(voteOpen)
        end

    end

end
--------------------------------------------------
-- MODEL FINDER
--------------------------------------------------

local function GetRegisteredNPCModel(className)

    if not isstring(className) or className == "" then
        return nil
    end


    if scripted_ents and scripted_ents.GetStored then

        local stored = scripted_ents.GetStored(className)


        if istable(stored) and istable(stored.t) then

            local data = stored.t


            if isstring(data.Model)
            and data.Model ~= ""
            and file.Exists(data.Model,"GAME")
            then
                return data.Model
            end


            if istable(data.Models) then

                for _,mdl in ipairs(data.Models) do

                    if isstring(mdl)
                    and file.Exists(mdl,"GAME")
                    then
                        return mdl
                    end

                end

            end

        end

    end


    return nil

end



local function GetOptionModel(option)

    if isstring(option.model)
    and option.model ~= ""
    and file.Exists(option.model,"GAME")
    then
        return option.model
    end


    if option.class then

        local modelPath =
            GetRegisteredNPCModel(option.class)

        if modelPath then
            return modelPath
        end

    end



    for _,className in ipairs(option.classes or {}) do


        local modelPath =
            GetRegisteredNPCModel(className)


        if modelPath then
            return modelPath
        end


    end



    -- поиск Bon
    if option.id == 4
    and scripted_ents
    and scripted_ents.GetList
    then


        for className in pairs(
            scripted_ents.GetList() or {}
        ) do


            if isstring(className) then


                local lower =
                    string.lower(className)



                if string.find(lower,"bon",1,true)
                or string.find(lower,"rabbit",1,true)
                then


                    local modelPath =
                        GetRegisteredNPCModel(className)



                    if modelPath then
                        return modelPath
                    end


                end

            end

        end

    end



    -- поиск через NPC список
    if list and list.Get then


        for _,npcData in pairs(
            list.Get("NPC") or {}
        ) do


            if istable(npcData) then


                local class =
                    npcData.Class



                for _,known in ipairs(option.classes or {}) do


                    if class == known then


                        local mdl =
                            npcData.Model



                        if isstring(mdl)
                        and file.Exists(mdl,"GAME")
                        then

                            return mdl

                        end

                    end


                end


            end


        end


    end



    return nil

end


--------------------------------------------------
-- BUILD MENU
--------------------------------------------------

local function BuildVote()


    if not voteOpen and selectedName == "" then

        CloseVote()
        return

    end



    if IsValid(voteFrame) then

        UpdateVoteButtons()
        return

    end



    voteFrame = vgui.Create("DFrame")

    voteFrame:SetSize(1480,420)

    voteFrame:Center()

    voteFrame:SetTitle("")

    voteFrame:ShowCloseButton(false)

    voteFrame:SetDraggable(false)

    voteFrame:SetSizable(false)

    voteFrame:MakePopup()



    voteFrame.Paint = function(self,w,h)


        Derma_DrawBackgroundBlur(
            self,
            self.m_fCreateTime
        )


        draw.RoundedBox(
            12,
            0,
            0,
            w,
            h,
            Color(9,9,14,250)
        )



        for i=1,7 do

            surface.SetDrawColor(
                255,
                65,
                175,
                5
            )

            surface.DrawRect(
                12,
                i*2,
                w-24,
                5
            )

        end



        draw.RoundedBoxEx(
            12,
            0,
            0,
            w,
            70,
            Color(20,14,25,255),
            true,
            true,
            false,
            false
        )



        draw.RoundedBox(
            2,
            18,
            68,
            w-36,
            2,
            Color(255,75,180)
        )



        surface.SetDrawColor(
            255,
            85,
            185,
            100
        )

        surface.DrawOutlinedRect(
            0,
            0,
            w,
            h,
            1
        )



        draw.SimpleText(
            voteOpen
            and "ВЫБЕРИТЕ НЕКСБОТА"
            or "НЕКСБОТ ВЫБРАН",

            "NextbotMode_Title",

            w/2,
            35,

            Color(255,240,250),

            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER
        )



        if voteOpen then


            draw.SimpleText(
                "Голосование завершится через "
                ..
                math.max(
                    0,
                    math.ceil(voteEndTime-CurTime())
                )
                ..
                " сек.",

                "NextbotMode_Small",

                w/2,
                91,

                Color(220,210,225),

                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER
            )


        else


            draw.SimpleText(
                "Приготовьтесь. Скоро начнётся охота.",

                "NextbotMode_Small",

                w/2,
                91,

                Color(255,125,200),

                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER
            )


        end



        local labels = {

            "SCP-173: "..votes173,
            "SCP-096: "..votes096,
            "КОТ: "..votesCith,
            "BON: "..votesBon,
            "G-MAN: "..votesGman

        }



        for i,text in ipairs(labels) do


            draw.SimpleText(

                text,

                "NextbotMode_Small",

                145+(i-1)*295,

                390,

                Color(240,210,230),

                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER

            )


        end


    end



    local function MakeOption(x,option)


        local card = vgui.Create(
            "DPanel",
            voteFrame
        )


        card:SetPos(
            x,
            120
        )


        card:SetSize(
            270,
            250
        )



        card.Paint = function(self,w,h)


            local selected =
                selectedName == option.name


            local hovered =
                self:IsHovered()



            draw.RoundedBox(
                10,
                0,
                0,
                w,
                h,
                Color(20,18,27,255)
            )



            surface.SetDrawColor(
                option.accent.r,
                option.accent.g,
                option.accent.b,
                selected and 255 or (hovered and 220 or 90)
            )

            surface.DrawOutlinedRect(
                0,
                0,
                w,
                h,
                selected and 3 or 1
            )



            draw.SimpleText(
                option.name,

                "NextbotMode_Button",

                w/2,
                145,

                Color(255,245,250),

                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER
            )


            draw.SimpleText(
                option.subtitle,

                "NextbotMode_Small",

                w/2,
                170,

                Color(180,170,190),

                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER
            )



            draw.SimpleText(
                "ГОЛОСА: "..GetVoteCount(option.id),

                "NextbotMode_Small",

                w/2,
                192,

                option.accent,

                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER
            )


        end
		        --------------------------------------------------
        -- MODEL PANEL
        --------------------------------------------------

        local modelPanel = vgui.Create(
            "DModelPanel",
            card
        )


        modelPanel:SetPos(
            5,
            5
        )


        modelPanel:SetSize(
            260,
            130
        )


        modelPanel:SetMouseInputEnabled(false)

        modelPanel:SetKeyboardInputEnabled(false)


        modelPanel:SetFOV(
            option.fov or 35
        )



        local modelPath = GetOptionModel(option)



        if modelPath then


            modelPanel:SetModel(modelPath)


            modelPanel:SetCamPos(
                option.camPos or Vector(100,0,50)
            )


            modelPanel:SetLookAt(
                option.lookAt or Vector(0,0,50)
            )



            --------------------------------------------------
-- NEXTBOT CARD MODEL POSE
--------------------------------------------------

modelPanel.LayoutEntity = function(self,ent)

    if not IsValid(ent) then
        return
    end

end


    -- отключаем вращение
    ent:SetAngles(
        Angle(
            0,
            180,
            0
        )
    )


    -- отключаем движение анимации
    ent:SetPlaybackRate(0)


    --------------------------------------------------
    -- IDLE ПОЗА
    --------------------------------------------------

    local idleSequences = {

        "idle",
        "Idle",
        "ACT_IDLE",
        "pose",
        "stand",
        "walk_all"

    }


    for _,seqName in ipairs(idleSequences) do


        local seq =
            ent:LookupSequence(seqName)


        if seq and seq >= 0 then


            ent:ResetSequence(seq)

            ent:SetCycle(0)


            break

        end


    end



    --------------------------------------------------
    -- ОСОБЫЕ ПОЗЫ
    --------------------------------------------------


    -- SCP-173
    if option.name == "SCP-173" then


        local head =
            ent:LookupBone("ValveBiped.Bip01_Head1")


        if head then

            ent:ManipulateBoneAngles(

                head,

                Angle(
                    15,
                    0,
                    0
                )

            )

        end


    end



    -- SCP-096
    if option.name == "SCP-096" then


        local spine =
            ent:LookupBone("ValveBiped.Bip01_Spine")


        if spine then

            ent:ManipulateBoneAngles(

                spine,

                Angle(
                    -20,
                    0,
                    0
                )

            )

        end


    end



    -- G-Man
    if option.name == "G-Man" then


        local spine =
            ent:LookupBone("ValveBiped.Bip01_Spine")


        if spine then

            ent:ManipulateBoneAngles(

                spine,

                Angle(
                    5,
                    0,
                    0
                )

            )

        end


    end


end



        --------------------------------------------------
        -- BUTTON
        --------------------------------------------------

        local button = vgui.Create(
            "DButton",
            card
        )


        button:SetPos(
            10,
            215
        )


        button:SetSize(
            250,
            30
        )


        button:SetText("")


        button:SetEnabled(
            voteOpen
        )



        button.Paint = function(self,w,h)


            local hovered =
                self:IsHovered()
                and voteOpen



            draw.RoundedBox(
                6,
                0,
                0,
                w,
                h,

                Color(
                    option.accent.r,
                    option.accent.g,
                    option.accent.b,

                    hovered
                    and 230
                    or 150
                )

            )



            draw.SimpleText(

                voteOpen
                and "ПРОГОЛОСОВАТЬ"
                or
                (
                    selectedName == option.name
                    and "ВЫБРАН"
                    or
                    "ЗАВЕРШЕНО"
                ),

                "NextbotMode_ModelLabel",

                w/2,
                h/2,

                color_white,

                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER

            )


        end



        button.DoClick = function()

            SendVote(option.id)

        end



        voteButtons[#voteButtons+1] = button


    end



    MakeOption(10,OPTIONS[1])

    MakeOption(305,OPTIONS[2])

    MakeOption(600,OPTIONS[3])

    MakeOption(895,OPTIONS[4])

    MakeOption(1190,OPTIONS[5])


    UpdateVoteButtons()


end



--------------------------------------------------
-- NETWORK
--------------------------------------------------

net.Receive(
"nextbot_mode_vote_state",

function()


    voteOpen =
        net.ReadBool()


    voteEndTime =
        net.ReadFloat()



    votes173 =
        net.ReadUInt(16)


    votes096 =
        net.ReadUInt(16)


    votesCith =
        net.ReadUInt(16)


    votesBon =
        net.ReadUInt(16)



    votesGman =
        net.ReadUInt(16)



    selectedName =
        net.ReadString()



    if voteOpen
    or selectedName ~= ""
    then

        BuildVote()

        UpdateVoteButtons()

    else

        CloseVote()

    end


end)



--------------------------------------------------
-- ROUND START
--------------------------------------------------

net.Receive(
"nextbot_mode_round_started",

function()


    voteOpen = false

    selectedName = ""


    CloseVote()


end)



--------------------------------------------------
-- RESULT
--------------------------------------------------

net.Receive(
"nextbot_mode_result",

function()


    local result =
        net.ReadString()



    CloseVote()



    if result == "nextbot" then


        chat.AddText(

            Color(255,70,135),

            "[Нексбот] ",

            color_white,

            "Нексбот победил!"

        )



    elseif result == "spawn_failed" then


        chat.AddText(

            Color(255,180,70),

            "[Нексбот] ",

            color_white,

            "Нексбот не появился."

        )



    else


        chat.AddText(

            Color(100,255,165),

            "[Нексбот] ",

            color_white,

            "Выжившие победили!"

        )


    end


end)



--------------------------------------------------
-- THINK
--------------------------------------------------

hook.Add("Think","NextbotMode_VoteWindowThink",function()


    if introActive then
        return
    end


    if (voteOpen or selectedName ~= "")
    and not IsValid(voteFrame)
    then

        BuildVote()

    end


end)


--------------------------------------------------
-- RESIZE
--------------------------------------------------

hook.Add(
"OnScreenSizeChanged",
"NextbotMode_VoteScreenChanged",

function()


    if IsValid(voteFrame) then

        voteFrame:Center()

    end


end)



print(
"[Nextbot] cl_nextbot.lua loaded with G-Man support."
)

--------------------------------------------------
-- NEXTBOT HORROR INTRO SCREEN
--------------------------------------------------

local nextbotIntroFrame
local introName = ""
local introModel = ""

local INTRO_TIME = 5


local INTRO_MODELS = {

    ["SCP-173"] =
        "models/scp/173.mdl",

    ["SCP-096"] =
        "models/scp_096/scp_096_final.mdl",

    ["G-Man"] =
        "models/player/gman_high.mdl"

}



local function IntroShake()

    return math.random(-3,3)

end



local function GetIntroModel(name)

    if INTRO_MODELS[name]
    and file.Exists(
        INTRO_MODELS[name],
        "GAME"
    )
    then

        return INTRO_MODELS[name]

    end



    -- Bon / Cat поиск как у твоего меню

    for _,option in ipairs(OPTIONS) do


        if option.name == name then


            local mdl =
                GetOptionModel(option)


            if mdl then

                return mdl

            end


        end


    end



    return nil

end





--------------------------------------------------
-- HORROR NEXTBOT INTRO
--------------------------------------------------

local function OpenNextbotIntro(name)

    introActive = true

    CloseVote()

    voteOpen = false



    if IsValid(nextbotIntroFrame) then

        nextbotIntroFrame:Remove()

    end



    introName = name


    introModel =
        GetIntroModel(name)
        or ""




    nextbotIntroFrame =
        vgui.Create("DFrame")



    nextbotIntroFrame:SetSize(
        ScrW(),
        ScrH()
    )


    nextbotIntroFrame:SetPos(
        0,
        0
    )


    nextbotIntroFrame:SetTitle("")


    nextbotIntroFrame:ShowCloseButton(false)


    nextbotIntroFrame:SetDraggable(false)


    nextbotIntroFrame:MakePopup()





    nextbotIntroFrame.Paint =
    function(self,w,h)



        -- ЧЁРНЫЙ ФОН

        draw.RoundedBox(

            0,

            0,

            0,

            w,

            h,

            Color(
                0,
                0,
                0,
                255
            )

        )



        -- лёгкий красный свет

        surface.SetDrawColor(
            120,
            0,
            30,
            35
        )

        surface.DrawRect(

            w*0.55,

            0,

            w*0.45,

            h

        )




        local x =
            w*0.75


        local y =
            h*0.45




        local shakeX =
            math.random(-2,2)


        local shakeY =
            math.random(-2,2)





        --------------------------------------------------
        -- ВЫБРАН
        --------------------------------------------------


        draw.SimpleText(

            "ВЫБРАН:",

            "NextbotMode_Title",

            x + shakeX,

            y - 110 + shakeY,

            Color(
                240,
                240,
                240
            ),

            TEXT_ALIGN_CENTER,

            TEXT_ALIGN_CENTER

        )






        --------------------------------------------------
        -- ИМЯ НЕКСБОТА
        --------------------------------------------------


        for i = 1,3 do


            draw.SimpleText(

                introName,

                "NextbotMode_Title",

                x + shakeX + i,

                y + shakeY + i,

                Color(
                    120,
                    0,
                    40,
                    120
                ),

                TEXT_ALIGN_CENTER,

                TEXT_ALIGN_CENTER

            )


        end




        draw.SimpleText(

            introName,

            "NextbotMode_Title",

            x + shakeX,

            y + shakeY,

            Color(
                255,
                40,
                90
            ),

            TEXT_ALIGN_CENTER,

            TEXT_ALIGN_CENTER

        )



    end





    --------------------------------------------------
    -- MODEL LEFT
    --------------------------------------------------


    if introModel ~= "" then



        local modelPanel =
            vgui.Create(
                "DModelPanel",
                nextbotIntroFrame
            )



        modelPanel:SetSize(

            ScrW()*0.45,

            ScrH()*0.85

        )



        modelPanel:SetPos(

            20,

            ScrH()*0.08

        )



        modelPanel:SetModel(

            introModel

        )



        modelPanel:SetFOV(32)



        modelPanel:SetCamPos(

            Vector(
                120,
                0,
                65
            )

        )



        modelPanel:SetLookAt(

            Vector(
                0,
                0,
                55
            )

        )



        --------------------------------------------------
-- INTRO MODEL POSE
--------------------------------------------------

modelPanel.LayoutEntity = function(self,ent)

    if not IsValid(ent) then
        return
    end


    -- НЕ ВРАЩАЕМ
    ent:SetAngles(
        Angle(0,180,0)
    )


    ent:SetPlaybackRate(0)


end



    --------------------------------------------------
    -- IDLE
    --------------------------------------------------

    local sequences = {

        "idle",
        "Idle",
        "ACT_IDLE",
        "pose",
        "stand"

    }



    for _,seqName in ipairs(sequences) do


        local seq =
            ent:LookupSequence(seqName)



        if seq and seq >= 0 then


            ent:ResetSequence(seq)

            ent:SetCycle(0)


            break

        end


    end





    --------------------------------------------------
    -- ПОЗЫ
    --------------------------------------------------


    if introName == "SCP-173" then



        local head =
            ent:LookupBone(
                "ValveBiped.Bip01_Head1"
            )



        if head then

            ent:ManipulateBoneAngles(

                head,

                Angle(
                    20,
                    0,
                    0
                )

            )

        end



    end





    if introName == "SCP-096" then



        local spine =
            ent:LookupBone(
                "ValveBiped.Bip01_Spine"
            )



        if spine then

            ent:ManipulateBoneAngles(

                spine,

                Angle(
                    -25,
                    0,
                    0
                )

            )

        end



    end






    if introName == "G-Man" then



        local spine =
            ent:LookupBone(
                "ValveBiped.Bip01_Spine"
            )



        if spine then

            ent:ManipulateBoneAngles(

                spine,

                Angle(
                    8,
                    0,
                    0
                )

            )

        end



    end


end





    surface.PlaySound(

        "ambient/levels/citadel/portal_beam_shoot5.wav"

    )





    timer.Simple(

        5,

        function()


            if IsValid(nextbotIntroFrame) then

                nextbotIntroFrame:Remove()

            end


        end

    )


end



--------------------------------------------------
-- OPEN AFTER VOTE
--------------------------------------------------

hook.Add(

"Think",

"Nextbot_OpenIntroAfterVote",

function()


    if selectedName == ""
    then

        return

    end



    if voteOpen
    then

        return

    end



    if IsValid(nextbotIntroFrame)
    then

        return

    end



    if not introPlayed
    then

        introPlayed = true

        OpenNextbotIntro(
            selectedName
        )

    end


end)



--------------------------------------------------
-- RESET INTRO
--------------------------------------------------

net.Receive(

"nextbot_mode_round_started",

function()

    introPlayed = false

    if IsValid(nextbotIntroFrame) then

        nextbotIntroFrame:Remove()

    end

end)

local function ApplyNextbotPose(ent,name)

    if not IsValid(ent) then
        return
    end


    -- убираем вращение
    ent:SetAngles(
        Angle(0,180,0)
    )


    -- пробуем найти idle
    local seq = ent:LookupSequence("idle")


    if seq and seq >= 0 then

        ent:ResetSequence(seq)
        ent:SetCycle(0)

    end


    -- безопасная обработка костей
    local function BonePose(boneName,ang)

        local bone =
            ent:LookupBone(boneName)


        if bone then

            ent:ManipulateBoneAngles(
                bone,
                ang
            )

        end

    end



    if name == "SCP-173" then

        BonePose(
            "ValveBiped.Bip01_Head1",
            Angle(15,0,0)
        )

    end



    if name == "SCP-096" then

        BonePose(
            "ValveBiped.Bip01_Spine",
            Angle(-20,0,0)
        )

    end



    if name == "G-Man" then

        BonePose(
            "ValveBiped.Bip01_Spine",
            Angle(5,0,0)
        )

    end


end