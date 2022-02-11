QBCore = exports['qb-core']:GetCoreObject()
local closestBank = nil
local closestLocker = nil
local inRange
local copsCalled = false
local PlayerJob = {}
local refreshed = false
CurrentCops = 0

-- Handlers

local function ResetBankDoors()
    for k, v in pairs(Config.SmallBanks) do
        local object = GetClosestObjectOfType(Config.SmallBanks[k]["coords"]["x"], Config.SmallBanks[k]["coords"]["y"], Config.SmallBanks[k]["coords"]["z"], 5.0, Config.SmallBanks[k]["object"], false, false, false)
        if not Config.SmallBanks[k]["isOpened"] then
            SetEntityHeading(object, Config.SmallBanks[k]["heading"].closed)
        else
            SetEntityHeading(object, Config.SmallBanks[k]["heading"].open)
        end
    end
    if not Config.BigBanks["paleto"]["isOpened"] then
        local paletoObject = GetClosestObjectOfType(Config.BigBanks["paleto"]["coords"]["x"], Config.BigBanks["paleto"]["coords"]["y"], Config.BigBanks["paleto"]["coords"]["z"], 5.0, Config.BigBanks["paleto"]["object"], false, false, false)
        SetEntityHeading(paletoObject, Config.BigBanks["paleto"]["heading"].closed)
    else
        local paletoObject = GetClosestObjectOfType(Config.BigBanks["paleto"]["coords"]["x"], Config.BigBanks["paleto"]["coords"]["y"], Config.BigBanks["paleto"]["coords"]["z"], 5.0, Config.BigBanks["paleto"]["object"], false, false, false)
        SetEntityHeading(paletoObject, Config.BigBanks["paleto"]["heading"].open)
    end

    if not Config.BigBanks["pacific"]["isOpened"] then
        local pacificObject = GetClosestObjectOfType(Config.BigBanks["pacific"]["coords"][2]["x"], Config.BigBanks["pacific"]["coords"][2]["y"], Config.BigBanks["pacific"]["coords"][2]["z"], 20.0, Config.BigBanks["pacific"]["object"], false, false, false)
        SetEntityHeading(pacificObject, Config.BigBanks["pacific"]["heading"].closed)
    else
        local pacificObject = GetClosestObjectOfType(Config.BigBanks["pacific"]["coords"][2]["x"], Config.BigBanks["pacific"]["coords"][2]["y"], Config.BigBanks["pacific"]["coords"][2]["z"], 20.0, Config.BigBanks["pacific"]["object"], false, false, false)
        SetEntityHeading(pacificObject, Config.BigBanks["pacific"]["heading"].open)
    end
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        ResetBankDoors()
    end
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
    onDuty = true
end)

RegisterNetEvent('police:SetCopCount', function(amount)
    CurrentCops = amount
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerJob = QBCore.Functions.GetPlayerData().job
    QBCore.Functions.TriggerCallback('qb-bankrobbery:server:GetConfig', function(config)
        Config = config
    end)
    onDuty = true
    ResetBankDoors()
end)

-- Functions

function DrawText3Ds(x, y, z, text) -- Globally used
	SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

local function OpenPaletoDoor()
    TriggerServerEvent('qb-doorlock:server:updateState', 85, false)
    local object = GetClosestObjectOfType(Config.BigBanks["paleto"]["coords"]["x"], Config.BigBanks["paleto"]["coords"]["y"], Config.BigBanks["paleto"]["coords"]["z"], 5.0, Config.BigBanks["paleto"]["object"], false, false, false)
    local timeOut = 10
    local entHeading = Config.BigBanks["paleto"]["heading"].closed

    if object ~= 0 then
        SetEntityHeading(object, Config.BigBanks["paleto"]["heading"].open)
    end
end

local function OpenPacificDoor()
    local object = GetClosestObjectOfType(Config.BigBanks["pacific"]["coords"][2]["x"], Config.BigBanks["pacific"]["coords"][2]["y"], Config.BigBanks["pacific"]["coords"][2]["z"], 20.0, Config.BigBanks["pacific"]["object"], false, false, false)
    local timeOut = 10
    local entHeading = Config.BigBanks["pacific"]["heading"].closed

    if object ~= 0 then
        CreateThread(function()
            while true do

                if entHeading > Config.BigBanks["pacific"]["heading"].open then
                    SetEntityHeading(object, entHeading - 10)
                    entHeading = entHeading - 0.5
                else
                    break
                end

                Wait(10)
            end
        end)
    end
end

local function OnHackDone(success)
    if success then
        TriggerServerEvent('qb-bankrobbery:server:setBankState', closestBank, true)
    else
		QBCore.Functions.Notify("You Suck!", 'error')
	end
end

local function loadAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Wait(5)
    end
end

local function OpenBankDoor(bankId)
    local object = GetClosestObjectOfType(Config.SmallBanks[bankId]["coords"]["x"], Config.SmallBanks[bankId]["coords"]["y"], Config.SmallBanks[bankId]["coords"]["z"], 5.0, Config.SmallBanks[bankId]["object"], false, false, false)
    local timeOut = 10
    local entHeading = Config.SmallBanks[bankId]["heading"].closed
    if object ~= 0 then
        CreateThread(function()
            while true do

                if entHeading ~= Config.SmallBanks[bankId]["heading"].open then
                    SetEntityHeading(object, entHeading - 10)
                    entHeading = entHeading - 0.5
                else
                    break
                end

                Wait(10)
            end
        end)
    end
end

function IsWearingHandshoes() -- Globally Used
    local armIndex = GetPedDrawableVariation(PlayerPedId(), 3)
    local model = GetEntityModel(PlayerPedId())
    local retval = true
    if model == `mp_m_freemode_01` then
        if Config.MaleNoHandshoes[armIndex] ~= nil and Config.MaleNoHandshoes[armIndex] then
            retval = false
        end
    else
        if Config.FemaleNoHandshoes[armIndex] ~= nil and Config.FemaleNoHandshoes[armIndex] then
            retval = false
        end
    end
    return retval
end

function openLocker(bankId, lockerId) -- Globally Used
    local pos = GetEntityCoords(PlayerPedId())
    if math.random(1, 100) <= 65 and not IsWearingHandshoes() then
        TriggerServerEvent("evidence:server:CreateFingerDrop", pos)
    end
    TriggerServerEvent('qb-bankrobbery:server:setLockerState', bankId, lockerId, 'isBusy', true)
    if bankId == "paleto" then
        QBCore.Functions.TriggerCallback('QBCore:HasItem', function(hasItem)
            if hasItem then
                loadAnimDict("anim@heists@fleeca_bank@drilling")
                TaskPlayAnim(PlayerPedId(), 'anim@heists@fleeca_bank@drilling', 'drill_straight_idle' , 3.0, 3.0, -1, 1, 0, false, false, false)
                local pos = GetEntityCoords(PlayerPedId(), true)
                local DrillObject = CreateObject(`hei_prop_heist_drill`, pos.x, pos.y, pos.z, true, true, true)
                AttachEntityToEntity(DrillObject, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 57005), 0.14, 0, -0.01, 90.0, -90.0, 180.0, true, true, false, true, 1, true)
                IsDrilling = true
                TriggerEvent('Drilling:Start',function(Success)
                    if Success then
                        StopAnimTask(PlayerPedId(), "anim@heists@fleeca_bank@drilling", "drill_straight_idle", 1.0)
                        DetachEntity(DrillObject, true, true)
                        DeleteObject(DrillObject)
                        TriggerServerEvent('qb-bankrobbery:server:setLockerState', bankId, lockerId, 'isOpened', true)
                        TriggerServerEvent('qb-bankrobbery:server:setLockerState', bankId, lockerId, 'isBusy', false)
                        TriggerServerEvent('qb-bankrobbery:server:recieveItem', 'paleto')
                        QBCore.Functions.Notify("Successful!", "success")
                        IsDrilling = false
                    else
                        StopAnimTask(PlayerPedId(), "anim@heists@fleeca_bank@drilling", "drill_straight_idle", 1.0)
                        TriggerServerEvent('qb-bankrobbery:server:setLockerState', bankId, lockerId, 'isBusy', false)
                        DetachEntity(DrillObject, true, true)
                        DeleteObject(DrillObject)
                        QBCore.Functions.Notify("Canceled..", "error")
                        IsDrilling = false
                    end
                end)
                CreateThread(function()
                    while IsDrilling do
                        TriggerServerEvent('hud:server:GainStress', math.random(2, 4))
                        Wait(15000)
                    end
                end)
            else
                QBCore.Functions.Notify("Looks like the safe lock is too strong ..", "error")
                TriggerServerEvent('qb-bankrobbery:server:setLockerState', bankId, lockerId, 'isBusy', false)
            end
        end, "drill")
    elseif bankId == "pacific" then
        QBCore.Functions.TriggerCallback('QBCore:HasItem', function(hasItem)
            if hasItem then
                loadAnimDict("anim@heists@fleeca_bank@drilling")
                TaskPlayAnim(PlayerPedId(), 'anim@heists@fleeca_bank@drilling', 'drill_straight_idle' , 3.0, 3.0, -1, 1, 0, false, false, false)
                local pos = GetEntityCoords(PlayerPedId(), true)
                local DrillObject = CreateObject(`hei_prop_heist_drill`, pos.x, pos.y, pos.z, true, true, true)
                AttachEntityToEntity(DrillObject, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 57005), 0.14, 0, -0.01, 90.0, -90.0, 180.0, true, true, false, true, 1, true)
                TriggerEvent('Drilling:Start',function(Success)
                    if Success then
                        StopAnimTask(PlayerPedId(), "anim@heists@fleeca_bank@drilling", "drill_straight_idle", 1.0)
                        DetachEntity(DrillObject, true, true)
                        DeleteObject(DrillObject)

                        TriggerServerEvent('qb-bankrobbery:server:setLockerState', bankId, lockerId, 'isOpened', true)
                        TriggerServerEvent('qb-bankrobbery:server:setLockerState', bankId, lockerId, 'isBusy', false)
                        TriggerServerEvent('qb-bankrobbery:server:recieveItem', 'pacific')
                        QBCore.Functions.Notify("Successful!", "success")
                        IsDrilling = false
                    else
                        StopAnimTask(PlayerPedId(), "anim@heists@fleeca_bank@drilling", "drill_straight_idle", 1.0)
                        TriggerServerEvent('qb-bankrobbery:server:setLockerState', bankId, lockerId, 'isBusy', false)
                        DetachEntity(DrillObject, true, true)
                        DeleteObject(DrillObject)
                        QBCore.Functions.Notify("Canceled..", "error")
                        IsDrilling = false
                    end
                end)
                CreateThread(function()
                    while IsDrilling do
                        TriggerServerEvent('hud:server:GainStress', math.random(2, 4))
                        Wait(15000)
                    end
                end)
            else
                QBCore.Functions.Notify("Looks like the safe lock is too strong ..", "error")
                TriggerServerEvent('qb-bankrobbery:server:setLockerState', bankId, lockerId, 'isBusy', false)
            end
        end, "drill")
    else
        loadAnimDict("anim@heists@fleeca_bank@drilling")
        TaskPlayAnim(PlayerPedId(), 'anim@heists@fleeca_bank@drilling', 'drill_straight_idle' , 3.0, 3.0, -1, 1, 0, false, false, false)
        local pos = GetEntityCoords(PlayerPedId(), true)
        local DrillObject = CreateObject(GetHashKey("hei_prop_heist_drill"), pos.x, pos.y, pos.z, true, true, true)
        AttachEntityToEntity(DrillObject, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 57005), 0.14, 0, -0.01, 90.0, -90.0, 180.0, true, true, false, true, 1, true)
        IsDrilling = true
        TriggerEvent('Drilling:Start',function(Success)
            if Success then
                StopAnimTask(PlayerPedId(), "anim@heists@fleeca_bank@drilling", "drill_straight_idle", 1.0)
                DetachEntity(DrillObject, true, true)
                DeleteObject(DrillObject)
    
                TriggerServerEvent('qb-bankrobbery:server:setLockerState', bankId, lockerId, 'isOpened', true)
                TriggerServerEvent('qb-bankrobbery:server:setLockerState', bankId, lockerId, 'isBusy', false)
                TriggerServerEvent('qb-bankrobbery:server:recieveItem', 'small')
                QBCore.Functions.Notify("Successful!", "success")
                IsDrilling = false
            else
                StopAnimTask(PlayerPedId(), "anim@heists@fleeca_bank@drilling", "drill_straight_idle", 1.0)
                DetachEntity(DrillObject, true, true)
                DeleteObject(DrillObject)
    
                TriggerServerEvent('qb-bankrobbery:server:setLockerState', bankId, lockerId, 'isBusy', false)
                QBCore.Functions.Notify("Canceled..", "error")
                IsDrilling = false
            end
        end)
        CreateThread(function()
            while IsDrilling do
                TriggerServerEvent('hud:server:GainStress', math.random(2, 4))
                Wait(15000)
            end
        end)
    end
end

-- Laptop
RegisterNetEvent('qb-bankrobbery:client:UseGreenLaptop', function(laptopData)
    local ped = PlayerPedId() 
    local pos = GetEntityCoords(ped)
    if closestBank ~= nil then
        QBCore.Functions.TriggerCallback('qb-bankrobbery:server:isRobberyActive', function(isBusy)
            if not isBusy then
                local dist = #(pos - vector3(Config.SmallBanks[closestBank]['coords'].x, Config.SmallBanks[closestBank]['coords'].y, Config.SmallBanks[closestBank]['coords'].z))
                if dist < 2.5 then
                    if CurrentCops >= Config.MinimumFleecaPolice then
                        if not Config.SmallBanks[closestBank]['isOpened'] then
                            SetEntityHeading(ped, Config.SmallBanks[closestBank]['coords'].w)
                            if math.random(1, 100) <= 65 and not IsWearingHandshoes() then
                                TriggerServerEvent("evidence:server:CreateFingerDrop", pos)
                            end
                            QBCore.Functions.Progressbar('hack_gate', 'Connecting the laptop..', math.random(5000, 10000), false, true, {
                                disableMovement = true,
                                disableCarMovement = true,
                                disableMouse = false,
                                disableCombat = true,
                            }, {
                                animDict = 'anim@gangops@facility@servers@',
                                anim = 'hotwire',
                                flags = 16,
                            }, {}, {}, function() -- Done
                                StopAnimTask(PlayerPedId(), 'anim@gangops@facility@servers@', 'hotwire', 1.0)
                                -- Removes a use from the laptop
                                TriggerServerEvent('qb-bankrobbery:server:RemoveLaptopUse', laptopData)
                                TriggerEvent('qb-bankrobbery:client:LaptopFleeca', closestBank)
                                -- Police Alert
                                if not copsCalled then
                                    if Config.SmallBanks[closestBank]["alarm"] then
                                        cameraId = Config.SmallBanks[closestBank]['camId']
                                        bank = 'Fleeca'
                                        TriggerEvent('qb-dispatch:bankrobbery', bank, cameraId)
                                        copsCalled = true
                                    end
                                end
                            end, function() -- Cancel
                                StopAnimTask(PlayerPedId(), 'anim@gangops@facility@servers@', 'hotwire', 1.0)
                                QBCore.Functions.Notify("Cancelled", 'error')
                            end)
                        else
                            QBCore.Functions.Notify("Door Already Open", 'error', 5000)
                        end
                    else
                        QBCore.Functions.Notify("Not Enough LEO", 'error', 5000)
                    end
                end
            else
                QBCore.Functions.Notify("Security Lockdown", 'error', 5000)
            end
        end)
    end
end)

RegisterNetEvent('qb-bankrobbery:client:LaptopFleeca', function()
    local loc = {x,y,z,h}
    loc.x = Config.SmallBanks[closestBank]['coords'].x
    loc.y = Config.SmallBanks[closestBank]['coords'].y
    loc.z = Config.SmallBanks[closestBank]['coords'].z
    loc.h = Config.SmallBanks[closestBank]['coords'].w

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

    exports['hacking']:OpenHackingGame(Config.FleecaTime, Config.FleecaBlocks, Config.FleecaRepeat, function(bool)
        NetworkStartSynchronisedScene(netScene3)
        NetworkStopSynchronisedScene(netScene3)
        DeleteObject(bag)
        DeleteObject(laptop)
        FreezeEntityPosition(ped, false)
        OnHackDone(bool)
    end)
end)

RegisterCommand('laptopanim', function()
    local loc = {x,y,z,h}
    local ped = PlayerPedId() 
    local pos = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    loc.x = pos.x
    loc.y = pos.y
    loc.z = pos.z+0.8
    loc.h = heading

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

    NetworkStartSynchronisedScene(netScene3)
    NetworkStopSynchronisedScene(netScene3)
    DeleteObject(bag)
    DeleteObject(laptop)
    FreezeEntityPosition(ped, false)
end)

-- Practice Laptop
RegisterNetEvent('qb-bankrobbery:client:UsePinkLaptop', function(laptopData)
    QBCore.Functions.Progressbar('hack_gate', 'Connecting the laptop..', math.random(15000, 30000), false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        -- Removes a use from the laptop
        TriggerServerEvent('qb-bankrobbery:server:RemoveLaptopUse', laptopData)
        -- Trigger Mini Game
        exports['hacking']:OpenHackingGame(Config.FleecaTime, Config.FleecaBlocks, Config.FleecaRepeat, function(bool)
            if bool then
                -- Reward Heist Points on Success [To be used with the heist rep system - Progression making people practice hacking in city to progress to better banks/heists]
                QBCore.Functions.Notify("WooHoo!", "success")
                TriggerServerEvent('qb-bankrobbery:server:succesHeist', 5) -- This adds 5 Heist Rep [For future use with buying laptops based on rep!]
            else
                QBCore.Functions.Notify("You Suck!", "error")
            end
        end)
        
    end, function() -- Cancel
        QBCore.Functions.Notify("Cancelled", 'error')
    end)
end)

-- Events

RegisterNetEvent('qb-bankrobbery:client:setBankState', function(bankId, state)
    if bankId == "paleto" then
        Config.BigBanks["paleto"]["isOpened"] = state
        if state then
            OpenPaletoDoor()
        end
    elseif bankId == "pacific" then
        Config.BigBanks["pacific"]["isOpened"] = state
        if state then
            OpenPacificDoor()
        end
    else
        Config.SmallBanks[bankId]["isOpened"] = state
        if state then
            OpenBankDoor(bankId)
        end
    end
end)

RegisterNetEvent('qb-bankrobbery:client:enableAllBankSecurity', function()
    for k, v in pairs(Config.SmallBanks) do
        Config.SmallBanks[k]["alarm"] = true
    end
end)

RegisterNetEvent('qb-bankrobbery:client:disableAllBankSecurity', function()
    for k, v in pairs(Config.SmallBanks) do
        Config.SmallBanks[k]["alarm"] = false
    end
end)

RegisterNetEvent('qb-bankrobbery:client:BankSecurity', function(key, status)
    Config.SmallBanks[key]["alarm"] = status
end)

RegisterNetEvent('qb-bankrobbery:client:setLockerState', function(bankId, lockerId, state, bool)
    if bankId == "paleto" then
        Config.BigBanks["paleto"]["lockers"][lockerId][state] = bool
    elseif bankId == "pacific" then
        Config.BigBanks["pacific"]["lockers"][lockerId][state] = bool
    else
        Config.SmallBanks[bankId]["lockers"][lockerId][state] = bool
    end
end)

RegisterNetEvent('qb-bankrobbery:client:ResetFleecaLockers', function(BankId)
    Config.SmallBanks[BankId]["isOpened"] = false
    for k,_ in pairs(Config.SmallBanks[BankId]["lockers"]) do
        Config.SmallBanks[BankId]["lockers"][k]["isOpened"] = false
        Config.SmallBanks[BankId]["lockers"][k]["isBusy"] = false
    end
end)

RegisterNetEvent('qb-bankrobbery:client:DrillSmallLocker', function()
    if closestBank ~= nil then
        if Config.SmallBanks[closestBank]["isOpened"] then
            for k, v in pairs(Config.SmallBanks[closestBank]["lockers"]) do
                local ped = PlayerPedId()
                local pos = GetEntityCoords(ped)
                local lockerDist = #(pos - Config.SmallBanks[closestBank]["lockers"][k]["coords"])
                if not Config.SmallBanks[closestBank]["lockers"][k]["isBusy"] then
                    if not Config.SmallBanks[closestBank]["lockers"][k]["isOpened"] then
                        if lockerDist < 5 then
                            QBCore.Functions.TriggerCallback('QBCore:HasItem', function(result)
                                if result then
                                    if CurrentCops >= Config.MinimumFleecaPolice then
                                        -- EW CRUDE Need to figure out how to correct player positioning for the drilling animations
                                        --[[
                                            SetEntityCoords(PlayerPedId(), Config.SmallBanks[closestBank]["lockers"][closestLocker]["coords"], 0, 0, 0, 0, false)
                                            SetEntityHeading(PlayerPedId(), Config.SmallBanks[closestBank]["lockers"][closestLocker]["heading"])
                                        ]]
                                        openLocker(closestBank, k)
                                    else
                                        QBCore.Functions.Notify('Minimum Of '..Config.MinimumFleecaPolice..' Police Needed', "error")
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
    end
end)

-- Threads

CreateThread(function()
    while true do
        Wait(1000 * 60 * 5)
        if copsCalled then
            copsCalled = false
        end
    end
end)

CreateThread(function()
    Wait(500)
    if QBCore.Functions.GetPlayerData() ~= nil then
        PlayerJob = QBCore.Functions.GetPlayerData().job
        onDuty = true
    end
end)

RegisterNetEvent('QBCore:Client:SetDuty', function(duty)
    onDuty = duty
end)

CreateThread(function()
    while true do
        Wait(1000)
        if inRange then
            if not refreshed then
                ResetBankDoors()
                refreshed = true
            end
        else
            refreshed = false
        end
    end
end)

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        local dist

        if QBCore ~= nil then
            inRange = false
            inLockerRange = false
            for k, v in pairs(Config.SmallBanks) do
                dist = #(pos - vector3(Config.SmallBanks[k]['coords'].x, Config.SmallBanks[k]['coords'].y, Config.SmallBanks[k]['coords'].z))
                if dist < 15 then
                    closestBank = k
                    for locker, _ in pairs(Config.SmallBanks) do
                        lockerDist = #(pos - vector3(Config.SmallBanks[closestBank]["lockers"][locker]["coords"].x, Config.SmallBanks[closestBank]["lockers"][locker]["coords"].y, Config.SmallBanks[closestBank]["lockers"][locker]["coords"].z))
                        if lockerDist < 1 then
                            closestLocker = locker
                        end
                    end
                    inRange = true
                end
            end

            if not inRange then
                Wait(2000)
                closestBank = nil
                closestLocker = nil 
            end
        end

        Wait(3)
    end
end)

-- Drill Spots
CreateThread(function() 
    for bank, _ in pairs(Config.SmallBanks) do
        for k,v in pairs(Config.SmallBanks[bank]['lockers']) do
            exports['qb-target']:AddBoxZone('FleecaLockers'..math.random(1,200), vector3(Config.SmallBanks[bank]['lockers'][k]['coords'].x, Config.SmallBanks[bank]['lockers'][k]['coords'].y, Config.SmallBanks[bank]['lockers'][k]['coords'].z), 1.00, 0.80, {
                name = 'FleecaLockers'..math.random(1,200), 
                heading = Config.SmallBanks[bank]['lockers'][k]['heading'],
                debugPoly = Config.DebugPoly,
                minZ = Config.SmallBanks[bank]['lockers'][k]['coords'].z-1,
                maxZ = Config.SmallBanks[bank]['lockers'][k]['coords'].z+2,
                }, {
                options = {
                    { 
                        type = 'client',
                        event = 'qb-bankrobbery:client:DrillSmallLocker',
                        icon = 'fas fa-bomb',
                        label = 'Drill Locker',
                    }
                },
                distance = 1.5,
            })
        end
    end
end)