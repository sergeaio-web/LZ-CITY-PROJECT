--
hg = hg or {}
hg.WeaponSelector = hg.WeaponSelector or {}
local WS = hg.WeaponSelector

-- ============================================================
-- LZ-CITY WEAPON SELECTOR STYLE
-- ============================================================

local CYCLE_TIME = 6

local GRAPHITE = Color(41,41,41)          -- #292929
local PINK = Color(200,142,155)           -- #C88E9B
local LIGHT_PINK = Color(230,180,190)

local OUTLINE_COLOR = Color(200,142,155)
local OUTLINE_ALL = false


-- ============================================================
-- ПЛАВНОЕ ПЕРЕЛИВАНИЕ
-- графит -> розовый -> светлый розовый -> обратно
-- ============================================================

local PULSE_KEYS = {
    {41,41,41},
    {200,142,155},
    {230,180,190},
    {200,142,155},
}


local function PulseRGB()

    local n = #PULSE_KEYS

    local pos = ((CurTime() / CYCLE_TIME) % 1) * n

    local i = math.floor(pos)

    local t = pos - i

    local f = t * t * (3 - 2 * t)


    local a = PULSE_KEYS[i % n + 1]
    local b = PULSE_KEYS[(i + 1) % n + 1]


    return 
        Lerp(f,a[1],b[1]),
        Lerp(f,a[2],b[2]),
        Lerp(f,a[3],b[3])
end


local function TextShade(r,g,b)

    return 
        (r * 0.299 + g * 0.587 + b * 0.114) > 140 
        and 0 
        or 255

end


-- ============================================================
-- NAME
-- ============================================================


function WS.GetPrintName(self)

    local class = self:GetClass()

    local phrase = language.GetPhrase(class)

    return phrase ~= class and phrase or self:GetPrintName()

end



WS.Show = 0
WS.Transparent = 0

WS.LastSelectedSlot = 0
WS.LastSelectedSlotPos = 0

WS.SelectedSlot = 0
WS.SelectedSlotPos = 0



function WS.DrawText(text,font,posX,posY,color,textAlign)

    draw.DrawText(
        text,
        font,
        posX + 2,
        posY + 2,
        ColorAlpha(color_black,WS.Transparent * 255),
        textAlign
    )


    draw.DrawText(
        text,
        font,
        posX,
        posY,
        ColorAlpha(color,WS.Transparent * 255),
        textAlign
    )

end



function WS.GetSelectedWeapon()

    if not IsValid(LocalPlayer()) or not LocalPlayer():Alive() then return end


    local Weapons = WS.GetWeaponTable(LocalPlayer())


    return Weapons[WS.SelectedSlot]
    and Weapons[WS.SelectedSlot][WS.SelectedSlotPos]

    or Weapons[WS.LastSelectedSlot]
    and Weapons[WS.LastSelectedSlot][WS.LastSelectedSlotPos]

    or Weapons[0][0]

end



function WS.GetWeaponTable(ply)

    if not IsValid(ply) or not ply:Alive() then return end


    local WeaponsGet = ply:GetWeapons()


    local FormatedTable = {

        [0] = {},
        [1] = {},
        [2] = {},
        [3] = {},
        [4] = {},
        [5] = {},

    }


    table.sort(
        WeaponsGet,
        function(a,b)

            return (a.SlotPos or 0) > (b.SlotPos or 0)

        end
    )


    for k,wep in ipairs(WeaponsGet) do


        local tTbl = FormatedTable[wep.Slot or 0]


        local iMinPos = math.min(
            wep.SlotPos or 1,
            (#tTbl or 0) + 1
        ) - 1


        local iPos = tTbl[iMinPos]
        and #tTbl + 1
        or iMinPos


        tTbl[iPos] = wep


    end


    return FormatedTable

end



local scrW,scrH = ScrW(),ScrH()

local gradient_u = Material("vgui/gradient-d")

function WS.WeaponSelectorDraw(ply)

    if not IsValid(ply)
    or not ply:Alive()
    or GetGlobalBool("RadialInventory",false)
    then return end


    if WS.Show < CurTime() then

        WS.SelectedSlot = WS.LastSelectedSlot
        WS.SelectedSlotPos = -1

        return

    end



    local Weapons = WS.GetWeaponTable(ply)

    local SelectedWep = WS.GetSelectedWeapon()

    if not IsValid(SelectedWep) then return end



    WS.Transparent = LerpFT(
        0.2,
        WS.Transparent,
        math.min(WS.Show - CurTime(),1)
    )



    -- ============================================================
    -- LZ-CITY ПЕРЕЛИВ
    -- ============================================================

    local PulseR,PulseG,PulseB = PulseRGB()

    local shade = TextShade(
        PulseR,
        PulseG,
        PulseB
    )


    local PlateTextColor = Color(
        shade,
        shade,
        shade
    )



    local SuperAmount = 0
    local AmountSlots = 0



    for i = 0,#Weapons do

        local slotTbl = Weapons[i]

        if table.Count(slotTbl) < 1 then continue end

        AmountSlots = AmountSlots + 1

    end




    for i = 0,#Weapons do


        local slotTbl = Weapons[i]


        if table.Count(slotTbl) < 1 then continue end



        local sizeX = scrW * 0.1


        local position =
            scrW/2 +
            ((SuperAmount - (AmountSlots/2)) * sizeX)



        WS.DrawText(
            i + 1,
            "HomigradFontMedium",
            position + sizeX/2,
            scrH * 0.02,
            ColorAlpha(
                color_white,
                WS.Transparent * 255
            ),
            TEXT_ALIGN_CENTER
        )




        local Amount = 0

        local lastPos = 0




        for Id = 0,#slotTbl do


            local wep = slotTbl[Id]


            if not wep then continue end




            local sizeH =
                SelectedWep == wep
                and scrH * 0.12
                or scrH * 0.025



            if slotTbl[Id-1]
            and SelectedWep == slotTbl[Id-1]
            then

                lastPos = scrH * 0.095

            end




            -- ====================================================
            -- ОСНОВНАЯ ПЛАШКА
            -- ====================================================


            draw.RoundedBox(

                0,

                position,

                (scrH * 0.025) * Amount
                + (scrH * 0.05)
                + lastPos,

                sizeX,

                sizeH,


                Color(

                    PulseR,
                    PulseG,
                    PulseB,

                    WS.Transparent * 220

                )

            )




            -- нижняя тень


            draw.RoundedBox(

                0,

                position,

                (scrH * 0.025) * Amount
                + (scrH * 0.05)
                + lastPos
                + sizeH - 2,

                sizeX,

                2,


                ColorAlpha(
                    color_black,
                    WS.Transparent * 150
                )

            )




            -- ====================================================
            -- РОЗОВЫЙ АКЦЕНТ ВЫБРАННОГО ОРУЖИЯ
            -- ====================================================


            surface.SetMaterial(gradient_u)


            surface.SetDrawColor(

                PINK.r,

                PINK.g,

                PINK.b,


                WS.Transparent *
                (
                    SelectedWep == wep
                    and 200
                    or 0
                )

            )


            surface.DrawTexturedRect(

                position,

                (scrH * 0.025) * Amount
                + (scrH * 0.05)
                + lastPos,

                sizeX,

                sizeH

            )





            -- ====================================================
            -- ОБВОДКА
            -- ====================================================


            if SelectedWep == wep
            or OUTLINE_ALL
            then


                surface.SetDrawColor(

                    OUTLINE_COLOR.r,

                    OUTLINE_COLOR.g,

                    OUTLINE_COLOR.b,


                    WS.Transparent *
                    (
                        SelectedWep == wep
                        and 255
                        or 170
                    )

                )



                surface.DrawOutlinedRect(

                    position,

                    (scrH * 0.025) * Amount
                    + (scrH * 0.05)
                    + lastPos,

                    sizeX,

                    sizeH,

                    2

                )


            end





            local sizeHi =
                (scrH * 0.025) * Amount
                + (scrH * 0.05)
                + lastPos


            sizeHi = sizeHi + 2.5




            WS.DrawText(

                WS.GetPrintName(wep),

                "HomigradFontSmall",

                position + sizeX/2,

                sizeHi,

                ColorAlpha(
                    PlateTextColor,
                    WS.Transparent * 255
                ),

                TEXT_ALIGN_CENTER

            )




            Amount = Amount + 1





            if SelectedWep == wep
            and wep.DrawWeaponSelection
            then


                wep:DrawWeaponSelection(

                    position + 5,

                    (scrH * 0.025) * Amount
                    + (scrH * 0.055)
                    + lastPos,

                    sizeX - 10,

                    sizeH,

                    WS.Transparent * 255

                )


            end


        end



        SuperAmount = SuperAmount + 1


    end


end

-- ============================================================
-- WEAPON CHANGER
-- ============================================================

local tAcceptKeys = {

    ["slot1"] = 1,
    ["slot2"] = 2,
    ["slot3"] = 3,
    ["slot4"] = 4,
    ["slot5"] = 5,
    ["slot6"] = 6,

}



local function GetUpper(Weapons)

    if #LocalPlayer():GetWeapons() < 1 then return end


    WS.SelectedSlot =
        WS.SelectedSlot < 0
        and #Weapons
        or WS.SelectedSlot - 1



    WS.SelectedSlotPos =
        Weapons[WS.SelectedSlot]
        and #Weapons[WS.SelectedSlot]
        or 0



    if Weapons[WS.SelectedSlot] == nil
    or Weapons[WS.SelectedSlot][WS.SelectedSlotPos] == nil
    then

        GetUpper(Weapons)

    end

end



local function GetDown(Weapons)

    if #LocalPlayer():GetWeapons() < 1 then return end



    WS.SelectedSlot =
        WS.SelectedSlot > #Weapons
        and 0
        or WS.SelectedSlot + 1



    WS.SelectedSlotPos = 0



    if Weapons[WS.SelectedSlot] == nil
    or Weapons[WS.SelectedSlot][WS.SelectedSlotPos] == nil
    then

        GetDown(Weapons)

    end

end



local LastSelected = 0



local function get_active_tool(ply,tool)

    local activeWep = ply:GetActiveWeapon()


    if not IsValid(activeWep)
    or activeWep:GetClass() ~= "gmod_tool"
    or activeWep.Mode ~= tool
    then return end



    return activeWep:GetToolObject(tool)

end



local function canUseSelector(ply)

    local wep = ply:GetActiveWeapon()


    local tool =
        get_active_tool(
            ply,
            "submaterial"
        )



    if tool
    and IsValid(ply:GetEyeTraceNoCursor().Entity)
    then

        return true

    end



    return IsAiming(ply)
    or
    (
        IsValid(wep)
        and wep:GetClass() == "weapon_physgun"
        and ply:KeyDown(IN_ATTACK)
    )

    or
    (
        lply.organism
        and lply.organism.pain
        and lply.organism.pain > 100
    )

    or GetGlobalBool(
        "RadialInventory",
        false
    )

end




function WS.ChangeSelectionWep(ply,key)


    if not IsValid(ply)
    or not ply:Alive()
    or GetGlobalBool("RadialInventory",false)
    then return end



    if ply.organism
    and ply.organism.otrub
    then return end



    if canUseSelector(ply)
    then return end




    local iPos = tAcceptKeys[key]



    if iPos
    or key == "invnext"
    or key == "invprev"
    or key == "lastinv"
    then


        local Weapons =
            WS.GetWeaponTable(ply)



        WS.Show =
            CurTime() + 4




        surface.PlaySound(
            "arc9_eft_shared/weapon_generic_rifle_spin"
            ..math.random(10)
            ..".ogg"
        )



        if iPos then


            iPos = iPos - 1



            if LastSelected ~= iPos then

                WS.SelectedSlotPos = -1

            end



            WS.SelectedSlotPos =
                (
                    Weapons[iPos]
                    and LastSelected == iPos
                    and WS.SelectedSlotPos + 1 > #Weapons[iPos]
                    and 0

                    or

                    math.min(
                        WS.SelectedSlotPos + 1,
                        #Weapons[iPos]
                    )
                )
                or 0



            WS.SelectedSlot = iPos


            LastSelected = iPos




        elseif key == "invprev" then



            WS.SelectedSlotPos =
                WS.SelectedSlotPos - 1



            if Weapons[WS.SelectedSlot]
            and WS.SelectedSlotPos < 0
            then

                GetUpper(Weapons)

            end




        elseif key == "invnext" then



            WS.SelectedSlotPos =
                WS.SelectedSlotPos + 1



            if Weapons[WS.SelectedSlot]
            and WS.SelectedSlotPos > #Weapons[WS.SelectedSlot]
            then

                GetDown(Weapons)

            end




        elseif key == "lastinv"
        and IsValid(WS.LastInv)
        then


            WS.Show = 0


            local oldwep =
                ply:GetActiveWeapon()



            input.SelectWeapon(
                WS.LastInv
            )



            WS.LastInv = oldwep


        end

    end

end





function WS.SetActuallyWeapon(ply,cmd)


    if not IsValid(ply)
    or not ply:Alive()
    or GetGlobalBool("RadialInventory",false)
    then return end




    if (
        cmd:KeyDown(IN_ATTACK)
        or cmd:KeyDown(IN_ATTACK2)
    )
    and WS.Show > CurTime()
    then



        if WS.Selected
        and WS.Selected > CurTime()
        then


            cmd:RemoveKey(IN_ATTACK)

            cmd:RemoveKey(IN_ATTACK2)



        else


            cmd:RemoveKey(IN_ATTACK)

            cmd:RemoveKey(IN_ATTACK2)




            if IsValid(
                WS.GetSelectedWeapon()
            )
            then


                WS.LastInv =
                    WS.LastInv ~= ply:GetActiveWeapon()
                    and WS.LastInv
                    or ply:GetActiveWeapon()



                input.SelectWeapon(
                    WS.GetSelectedWeapon()
                )


            end




            WS.LastSelectedSlot =
                WS.SelectedSlot


            WS.LastSelectedSlotPos =
                WS.SelectedSlotPos



            WS.Selected =
                CurTime() + 0.2



            WS.Show =
                CurTime() + 0.2



            surface.PlaySound(
                "arc9_eft_shared/weapon_generic_spin"
                ..math.random(1,10)
                ..".ogg"
            )


        end

    end

end





hook.Add(
    "PlayerBindPress",
    "WeaponSelector_PlayerBindPress",
    WS.ChangeSelectionWep
)



hook.Add(
    "HUDPaint",
    "WeaponSelector_Draw",
    function()

        WS.WeaponSelectorDraw(
            LocalPlayer()
        )

    end
)



hook.Add(
    "StartCommand",
    "WeaponSelector_StartCommand",
    WS.SetActuallyWeapon
)





local tHideElements = {

    ["CHudWeaponSelection"] = true

}




hook.Add(
    "HUDShouldDraw",
    "WeaponSelector_HUDShouldDraw",
    function(name)

        if tHideElements[name]
        then return false end

    end
)