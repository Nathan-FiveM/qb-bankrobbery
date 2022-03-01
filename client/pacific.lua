-- Functions
function OnHackPacificDone(success)
    if success then
        TriggerEvent('qb-bankrobbery:client:SetUpPacificTrolleys')
        local VaultWait = Config.PacificVaultWait / 1000
        local VaultWaitMins = tonumber(VaultWait) / 60
        QBCore.Functions.Notify("Door Opening in: "..math.floor(VaultWaitMins).." Minutes", 'success')
        Wait(Config.PacificVaultWait)
        TriggerServerEvent('qb-bankrobbery:server:setBankState', "pacific", true)
    else
        QBCore.Functions.Notify("You Suck!", 'error')
	end
end
function ThermitePacificPlanting(door)
    local pos = nil
    if door == 1 then
        pos = vector4(253.01703, 220.73141, 101.78381, 162.6746)
    elseif door == 2 then
        pos = vector4(261.66752, 215.73648, 101.78382, 261.99899)
    elseif door == 3 then
        pos = vector4(257.3800, 220.2000, 106.40, 335.00)
    end
    RequestAnimDict("anim@heists@ornate_bank@thermal_charge")
    RequestModel("hei_p_m_bag_var22_arm_s")
    RequestNamedPtfxAsset("scr_ornate_heist")
    while not HasAnimDictLoaded("anim@heists@ornate_bank@thermal_charge") and not HasModelLoaded("hei_p_m_bag_var22_arm_s") and not HasNamedPtfxAssetLoaded("scr_ornate_heist") do
        Citizen.Wait(50)
    end

    local ped = PlayerPedId()
    SetEntityHeading(ped, pos.w)
    Citizen.Wait(100)
    local rotx, roty, rotz = table.unpack(vec3(GetEntityRotation(ped)))
    local bagscene = NetworkCreateSynchronisedScene(pos.x, pos.y, pos.z, rotx, roty, rotz, 2, false, false, 1065353216, 0, 1.3)
    local bag = CreateObject(GetHashKey("hei_p_m_bag_var22_arm_s"), pos.x, pos.y, pos.z,  true,  true, false)
    SetEntityCollision(bag, false, true)

    local x, y, z = table.unpack(GetEntityCoords(ped))
    local thermite = CreateObject(GetHashKey("hei_prop_heist_thermite"), x, y, z + 0.2,  true,  true, true)
    SetEntityCollision(thermite, false, true)
    AttachEntityToEntity(thermite, ped, GetPedBoneIndex(ped, 28422), 0, 0, 0, 0, 0, 200.0, true, true, false, true, 1, true)
    
    NetworkAddPedToSynchronisedScene(ped, bagscene, "anim@heists@ornate_bank@thermal_charge", "thermal_charge", 1.5, -4.0, 1, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(bag, bagscene, "anim@heists@ornate_bank@thermal_charge", "bag_thermal_charge", 4.0, -8.0, 1)
    SetPedComponentVariation(ped, 5, 0, 0, 0)
    NetworkStartSynchronisedScene(bagscene)
    Citizen.Wait(5000)
    DetachEntity(thermite, 1, 1)
    FreezeEntityPosition(thermite, true)
    DeleteObject(bag)
    NetworkStopSynchronisedScene(bagscene)
    Citizen.CreateThread(function()
        Citizen.Wait(15000)
        DeleteEntity(thermite)
    end)
end
function ThermitePacificEffect(door)
    local ptfx = nil
    local PacDoor = nil
    if door == 1 then
        ptfx = vector3(253.11703, 221.53141, 101.78381)
        PacDoor = Config.PacificDoor3
    elseif door == 2 then
        ptfx = vector3(261.69946, 216.82735, 101.78382)
        PacDoor = Config.PacificDoor4
    elseif door == 3 then
        ptfx = vector3(257.400, 221.2500, 106.28)
        PacDoor = Config.PacificDoor1
    end

    RequestAnimDict("anim@heists@ornate_bank@thermal_charge")
    while not HasAnimDictLoaded("anim@heists@ornate_bank@thermal_charge") do
        Citizen.Wait(50)
    end
    local ped = PlayerPedId()
    Citizen.Wait(1500)
    TriggerServerEvent("qb-bankrobbery:server:ThermitePtfx", ptfx)
    Citizen.Wait(500)
    TaskPlayAnim(ped, "anim@heists@ornate_bank@thermal_charge", "cover_eyes_intro", 8.0, 8.0, 1000, 36, 1, 0, 0, 0)
    TaskPlayAnim(ped, "anim@heists@ornate_bank@thermal_charge", "cover_eyes_loop", 8.0, 8.0, 5000, 49, 1, 0, 0, 0)
    Citizen.Wait(12000)
    ClearPedTasks(ped)
    QBCore.Functions.Notify("The lock had been melted", "success")
    TriggerServerEvent('qb-doorlock:server:updateState', PacDoor , false)
end

-- Events
RegisterNetEvent('qb-bankrobbery:UseBankcardB', function()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local dist = #(pos - Config.BigBanks["pacific"]["coords"][1])
    if math.random(1, 100) <= 85 and not IsWearingHandshoes() then
        TriggerServerEvent("evidence:server:CreateFingerDrop", pos)
    end
    if dist < 2.5 then
        QBCore.Functions.TriggerCallback('qb-bankrobbery:server:isRobberyActive', function(isBusy)
            if not isBusy then
                if CurrentCops >= Config.MinimumPacificPolice then
                    if not Config.BigBanks["pacific"]["isOpened"] then
                        if not copsCalled then
                            if Config.BigBanks["pacific"]["alarm"] then
                                bank = 'Pacific'
                                TriggerEvent('dispatch:bankrobbery:pacific')
                                copsCalled = true
                            end
                        end
                        TriggerServerEvent("QBCore:Server:RemoveItem", "security_card_02", 1)
                        TriggerEvent('inventory:client:ItemBox', QBCore.Shared.Items["security_card_02"], 'remove')
                        QBCore.Functions.Progressbar("security_pass", "Please validate ..", math.random(5000, 10000), false, true, {
                            disableMovement = true,
                            disableCarMovement = true,
                            disableMouse = false,
                            disableCombat = true,
                        }, {
                            animDict = "anim@gangops@facility@servers@",
                            anim = "hotwire",
                            flags = 16,
                        }, {}, {}, function() -- Done
                            StopAnimTask(PlayerPedId(), "anim@gangops@facility@servers@", "hotwire", 1.0)
                            exports["memorygame"]:thermiteminigame(Config.ThermiteBlocks, Config.ThermiteAttempts, Config.ThermiteShow, Config.ThermiteTime,
                            function()
                                -- SUCCESS
                                TriggerServerEvent('qb-doorlock:server:updateState', Config.PacificDoor2, false)
                                QBCore.Functions.Notify('Door Unlocked!', 'error', '5000')
                            end,
                            function()
                                -- FAIL
                                QBCore.Functions.Notify('You suck!', 'error', '5000')
                            end)
                        end, function() -- Cancel
                            StopAnimTask(PlayerPedId(), "anim@gangops@facility@servers@", "hotwire", 1.0)
                            QBCore.Functions.Notify("Canceled..", "error")
                        end)
                    else
                        QBCore.Functions.Notify("Looks like the bank is already open ..", "error")
                    end
                else
                    QBCore.Functions.Notify('Minimum Of '..Config.MinimumPacificPolice..' Police Needed', "error")
                end
            else
                QBCore.Functions.Notify("The security lock is active, opening the door is currently not possible.", "error", 5500)
            end
        end)
    end
end)
RegisterNetEvent('qb-bankrobbery:client:UseRedLaptop', function(laptopData)
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local dist = #(pos - vector3(Config.BigBanks["pacific"]["coords"][2].x, Config.BigBanks["pacific"]["coords"][2].y, Config.BigBanks["pacific"]["coords"][2].z))
    if dist < 1.5 then
        QBCore.Functions.TriggerCallback('qb-bankrobbery:server:isRobberyActive', function(isBusy)
            if not isBusy then
                local dist = #(pos - vector3(Config.BigBanks["pacific"]["coords"][2].x, Config.BigBanks["pacific"]["coords"][2].y, Config.BigBanks["pacific"]["coords"][2].z))
                if dist < 1.5 then
                    if CurrentCops >= Config.MinimumPacificPolice then
                        if not Config.BigBanks["pacific"]["isOpened"] then
                            TriggerServerEvent('qb-bankrobbery:server:RemoveLaptopUse', laptopData) -- Removes a use from the laptop
                            if math.random(1, 100) <= 65 and not IsWearingHandshoes() then
                                TriggerServerEvent("evidence:server:CreateFingerDrop", pos)
                            end
                            QBCore.Functions.Progressbar("hack_gate", "Connecting laptop...", math.random(5000, 10000), false, true, {
                                disableMovement = true,
                                disableCarMovement = true,
                                disableMouse = false,
                                disableCombat = true,
                            }, {
                                animDict = "anim@gangops@facility@servers@",
                                anim = "hotwire",
                                flags = 16,
                            }, {}, {}, function() -- Done
                                StopAnimTask(PlayerPedId(), "anim@gangops@facility@servers@", "hotwire", 1.0)
                                TriggerEvent('qb-bankrobbery:client:LaptopPacific')
                                if not copsCalled then
                                    if Config.BigBanks["pacific"]["alarm"] then
                                        bank = 'Pacific'
                                        TriggerEvent('dispatch:bankrobbery:pacific') 
                                        copsCalled = true
                                    end
                                end
                            end, function() -- Cancel
                                StopAnimTask(PlayerPedId(), "anim@gangops@facility@servers@", "hotwire", 1.0)
                                QBCore.Functions.Notify("Canceled", "error")
                            end)
                        else
                            QBCore.Functions.Notify("Looks like the bank is already open", "error")
                        end
                    else
                        QBCore.Functions.Notify('Minimum Of '..Config.MinimumPacificPolice..' Police Needed', "error")
                    end
                end
            else
                QBCore.Functions.Notify("The security lock is active, opening the door is currently not possible.", "error", 5500)
            end
        end)
    end
end)
RegisterNetEvent('qb-bankrobbery:client:LaptopPacific', function()
    local loc = {x,y,z,h}
    loc.x = Config.BigBanks["pacific"]["coords"][2].x
    loc.y = Config.BigBanks["pacific"]["coords"][2].y
    loc.z = Config.BigBanks["pacific"]["coords"][2].z
    loc.h = Config.BigBanks["pacific"]["coords"][2].w

    local animDict = 'anim@heists@ornate_bank@hack'
    RequestAnimDict(animDict)
    RequestModel('hei_prop_hst_laptop')
    RequestModel('hei_p_m_bag_var22_arm_s')

    while not HasAnimDictLoaded(animDict)
        or not HasModelLoaded('hei_prop_hst_laptop')
        or not HasModelLoaded('hei_p_m_bag_var22_arm_s') do
        Wait(100)
    end

    local ped = PlayerPedId()
    local targetPosition, targetRotation = (vec3(GetEntityCoords(ped))), vec3(GetEntityRotation(ped))

    SetEntityHeading(ped, loc.h)
    local animPos = GetAnimInitialOffsetPosition(animDict, 'hack_enter', loc.x, loc.y, loc.z, loc.x, loc.y, loc.z, 0, 2)
    local animPos2 = GetAnimInitialOffsetPosition(animDict, 'hack_loop', loc.x, loc.y, loc.z, loc.x, loc.y, loc.z, 0, 2)
    local animPos3 = GetAnimInitialOffsetPosition(animDict, 'hack_exit', loc.x, loc.y, loc.z, loc.x, loc.y, loc.z, 0, 2)

    FreezeEntityPosition(ped, true)
    local netScene = NetworkCreateSynchronisedScene(animPos, targetRotation, 2, false, false, 1065353216, 0, 1.3)
    local bag = CreateObject(GetHashKey('hei_p_m_bag_var22_arm_s'), targetPosition, 1, 1, 0)
    local laptop = CreateObject(GetHashKey('hei_prop_hst_laptop'), targetPosition, 1, 1, 0)

    NetworkAddPedToSynchronisedScene(ped, netScene, animDict, 'hack_enter', 1.5, -4.0, 1, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(bag, netScene, animDict, 'hack_enter_bag', 4.0, -8.0, 1)
    NetworkAddEntityToSynchronisedScene(laptop, netScene, animDict, 'hack_enter_laptop', 4.0, -8.0, 1)

    local netScene2 = NetworkCreateSynchronisedScene(animPos2, targetRotation, 2, false, true, 1065353216, 0, 1.3)
    NetworkAddPedToSynchronisedScene(ped, netScene2, animDict, 'hack_loop', 1.5, -4.0, 1, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(bag, netScene2, animDict, 'hack_loop_bag', 4.0, -8.0, 1)
    NetworkAddEntityToSynchronisedScene(laptop, netScene2, animDict, 'hack_loop_laptop', 4.0, -8.0, 1)

    local netScene3 = NetworkCreateSynchronisedScene(animPos3, targetRotation, 2, false, false, 1065353216, 0, 1.3)
    NetworkAddPedToSynchronisedScene(ped, netScene3, animDict, 'hack_exit', 1.5, -4.0, 1, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(bag, netScene3, animDict, 'hack_exit_bag', 4.0, -8.0, 1)
    NetworkAddEntityToSynchronisedScene(laptop, netScene3, animDict, 'hack_exit_laptop', 4.0, -8.0, 1)

    Wait(200)
    NetworkStartSynchronisedScene(netScene)
    Wait(6300)
    NetworkStartSynchronisedScene(netScene2)
    Wait(2000)

    exports['hacking']:OpenHackingGame(Config.PacificTime, Config.PacificBlocks, Config.PacificRepeat, function(bool)
        NetworkStartSynchronisedScene(netScene3)
        NetworkStopSynchronisedScene(netScene3)
        DeleteObject(bag)
        DeleteObject(laptop)
        FreezeEntityPosition(ped, false)
        OnHackPacificDone(bool)
    end)
end)
RegisterNetEvent('qb-bankrobbery:client:DrillPacificLocker', function()
    if Config.BigBanks["pacific"]["isOpened"] then
        for k, v in pairs(Config.BigBanks["pacific"]["lockers"]) do
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            local lockerDist = #(pos - Config.BigBanks["pacific"]["lockers"][k]["coords"])
            if not Config.BigBanks["pacific"]["lockers"][k]["isBusy"] then
                if not Config.BigBanks["pacific"]["lockers"][k]["isOpened"] then
                    if lockerDist < 5 then
                        QBCore.Functions.TriggerCallback('QBCore:HasItem', function(result)
                            if result then
                                if CurrentCops >= Config.MinimumPacificPolice then
                                    -- EW CRUDE Need to figure out how to correct player positioning for the drilling animations
                                    --[[
                                        SetEntityCoords(ped, Config.BigBanks["pacific"]["lockers"][closestLocker]["coords"], 0, 0, 0, 0, false)
                                        SetEntityHeading(ped, Config.BigBanks["pacific"]["lockers"][closestLocker]["heading"])
                                    ]]
                                    openLocker("pacific", k)
                                else
                                    QBCore.Functions.Notify('Minimum Of '..Config.MinimumPacificPolice..' Police Needed', "error")
                                end
                            else
                                QBCore.Functions.Notify('You need a drill bro!', "error")
                            end
                        end, 'drill')
                    end
                end
            end
        end
    else
        QBCore.Functions.Notify('How the hell are you here?!', "error")
    end
end)
RegisterNetEvent('qb-bankrobbery:client:ThermitePacificDoor', function(data)
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    if #(pos - vector3(Config.BigBanks["pacific"]["thermite"][data.door]["coords"].x, Config.BigBanks["pacific"]["thermite"][data.door]["coords"].y, Config.BigBanks["pacific"]["thermite"][data.door]["coords"].z)) < 10.0 then
        if not Config.BigBanks["pacific"]["thermite"][data.door]["isOpened"] then
            local dist = #(pos - vector3(Config.BigBanks["pacific"]["thermite"][data.door]["coords"].x, Config.BigBanks["pacific"]["thermite"][data.door]["coords"].y, Config.BigBanks["pacific"]["thermite"][data.door]["coords"].z))
            if dist < 1 then
                QBCore.Functions.TriggerCallback('QBCore:HasItem', function(result)
                    if result then
                        if math.random(1, 100) <= 85 and not IsWearingHandshoes() then
                            TriggerServerEvent("evidence:server:CreateFingerDrop", pos)
                        end
                        TriggerServerEvent('QBCore:Server:RemoveItem', 'thermite', 1)
                        TriggerEvent('inventory:client:ItemBox', QBCore.Shared.Items["thermite"], 'remove')
                        ThermitePacificPlanting(data.door)
                        -- Thermite Game
                        exports["memorygame"]:thermiteminigame(Config.ThermiteBlocks, Config.ThermiteAttempts, Config.ThermiteShow, Config.ThermiteTime,
                        function()
                            -- SUCCESS
                            ThermitePacificEffect(data.door)
                        end,
                        function()
                            -- FAIL
                            QBCore.Functions.Notify('You suck!', 'error', '5000')
                        end)
                    else
                        QBCore.Functions.Notify('You don\'t have any thermite!', 'error', '5000')
                    end
                end, 'thermite')
            end
        end
    end
end)

-- Threads
if Config.Target then
    CreateThread(function() -- Drill Spots
        for bank, _ in pairs(Config.BigBanks) do
            for k,v in pairs(Config.BigBanks["pacific"]['lockers']) do
                exports['qb-target']:AddBoxZone('PacificLockers'..math.random(1,200), vector3(Config.BigBanks["pacific"]['lockers'][k]['coords'].x, Config.BigBanks["pacific"]['lockers'][k]['coords'].y, Config.BigBanks["pacific"]['lockers'][k]['coords'].z), 1.00, 0.80, {
                    name = 'PacificLockers'..math.random(1,200), 
                    heading = Config.BigBanks["pacific"]['lockers'][k]['heading'],
                    debugPoly = Config.DebugPoly,
                    minZ = Config.BigBanks["pacific"]['lockers'][k]['coords'].z-1,
                    maxZ = Config.BigBanks["pacific"]['lockers'][k]['coords'].z+2,
                    }, {
                    options = {
                        { 
                            type = 'client',
                            event = 'qb-bankrobbery:client:DrillPacificLocker',
                            icon = 'fas fa-bomb',
                            label = 'Drill Locker',
                            locker = k
                        }
                    },
                    distance = 0.75,
                })
            end
        end
    end)
    CreateThread(function() -- Thermite Spots
        for bank, _ in pairs(Config.BigBanks) do
            for k,v in pairs(Config.BigBanks["pacific"]['thermite']) do
                exports['qb-target']:AddBoxZone('PacificThermite'..math.random(1,200), vector3(Config.BigBanks["pacific"]['thermite'][k]['coords'].x, Config.BigBanks["pacific"]['thermite'][k]['coords'].y, Config.BigBanks["pacific"]['thermite'][k]['coords'].z), 1.00, 0.80, {
                    name = 'PacificThermite'..math.random(1,200), 
                    heading = Config.BigBanks["pacific"]['thermite'][k]['heading'],
                    debugPoly = Config.DebugPoly,
                    minZ = Config.BigBanks["pacific"]['thermite'][k]['coords'].z-1,
                    maxZ = Config.BigBanks["pacific"]['thermite'][k]['coords'].z+2,
                    }, {
                    options = {
                        { 
                            type = 'client',
                            event = 'qb-bankrobbery:client:ThermitePacificDoor',
                            icon = 'fas fa-bomb',
                            label = 'Blow Door',
                            door = k,
                        }
                    },
                    distance = 1.5,
                })
            end
        end
    end)
else
    CreateThread(function() -- Drill Spots
        Wait(2000)
        while true do
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            local inRange = false
            if QBCore ~= nil then
                if Config.BigBanks["pacific"]["isOpened"] then
                    for k, v in pairs(Config.BigBanks["pacific"]["lockers"]) do
                        local lockerDist = #(pos - Config.BigBanks["pacific"]["lockers"][k]["coords"])
                        if not Config.BigBanks["pacific"]["lockers"][k]["isBusy"] then
                            if not Config.BigBanks["pacific"]["lockers"][k]["isOpened"] then
                                if lockerDist < 5 then
                                    inRange = true
                                    DrawMarker(2, Config.BigBanks["pacific"]["lockers"][k]["coords"].x, Config.BigBanks["pacific"]["lockers"][k]["coords"].y, Config.BigBanks["pacific"]["lockers"][k]["coords"].z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.1, 0.1, 0.05, 255, 255, 255, 255, false, false, false, 1, false, false, false)
                                    if lockerDist < 0.5 then
                                        DrawText3Ds(Config.BigBanks["pacific"]["lockers"][k]["coords"].x, Config.BigBanks["pacific"]["lockers"][k]["coords"].y, Config.BigBanks["pacific"]["lockers"][k]["coords"].z + 0.3, '[E] Break open the safe')
                                        if IsControlJustPressed(0, 38) then
                                            if CurrentCops >= Config.MinimumPacificPolice then
                                                openLocker("pacific", k)
                                            else
                                                QBCore.Functions.Notify('Minimum Of '..Config.MinimumPacificPolice..' Police Needed', "error")
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                if not inRange then
                    Wait(2500)
                end
            end
            Wait(1)
        end
    end)
end