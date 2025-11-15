local patrolPeds = {}
local defenceLights = {}
local defencesActive = false
local isWhitelisted = false

local patrolModels = {
    `s_m_m_marine_01`,
    `s_m_y_blackops_01`,
    `s_m_m_armoured_01`
}

local patrolCoords = {
    { x = 4972.0, y = -5700.0, z = 20.0, heading = 90.0 },
    { x = 4890.0, y = -4900.0, z = 10.0, heading = 180.0 },
    { x = 5100.0, y = -5200.0, z = 15.0, heading = 270.0 },
}

local lightCoords = {
    { x = 4975.0, y = -5705.0, z = 21.0, heading = 90.0 },
    { x = 4885.0, y = -4905.0, z = 11.0, heading = 180.0 },
    { x = 5105.0, y = -5205.0, z = 16.0, heading = 270.0 },
}

-- Spawn patrol NPCs
local function spawnPatrols()
    for _, coords in ipairs(patrolCoords) do
        local model = patrolModels[math.random(#patrolModels)]
        RequestModel(model)
        while not HasModelLoaded(model) do Wait(0) end

        local ped = CreatePed(4, model, coords.x, coords.y, coords.z, coords.heading, true, true)
        SetPedArmour(ped, 100)
        SetPedAccuracy(ped, 70)
        GiveWeaponToPed(ped, `WEAPON_ASSAULTRIFLE`, 250, false, true)
        SetEntityAsMissionEntity(ped, true, true)
        TaskGuardCurrentPosition(ped, 10.0, 10.0, true)

        -- Relationship logic
        SetPedRelationshipGroupHash(ped, `ARMY`)
        if isWhitelisted then
            SetRelationshipBetweenGroups(1, `ARMY`, GetHashKey("PLAYER")) -- Neutral
        else
            SetRelationshipBetweenGroups(5, `ARMY`, GetHashKey("PLAYER")) -- Hostile
        end

        table.insert(patrolPeds, ped)
    end
end

-- Delete patrol NPCs
local function clearPatrols()
    for _, ped in ipairs(patrolPeds) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
    patrolPeds = {}
end

-- Spawn floodlights
local function spawnLights()
    for _, coords in ipairs(lightCoords) do
        local obj = CreateObject(`prop_worklight_03b`, coords.x, coords.y, coords.z, true, true, false)
        SetEntityHeading(obj, coords.heading)
        SetEntityAsMissionEntity(obj, true, true)
        table.insert(defenceLights, obj)
    end
    -- Flicker effect
    Citizen.CreateThread(function()
        for i = 1, 3 do
            for _, obj in ipairs(defenceLights) do SetEntityVisible(obj, false) end
            Wait(500)
            for _, obj in ipairs(defenceLights) do SetEntityVisible(obj, true) end
            Wait(500)
        end
    end)
end

-- Delete floodlights
local function clearLights()
    for _, obj in ipairs(defenceLights) do
        if DoesEntityExist(obj) then DeleteEntity(obj) end
    end
    defenceLights = {}
end

-- Anti-aircraft detection
Citizen.CreateThread(function()
    while true do
        Wait(1000)
        if defencesActive and not isWhitelisted then
            local ped = PlayerPedId()
            if IsPedInAnyPlane(ped) or IsPedInAnyHeli(ped) then
                local coords = GetEntityCoords(ped)
                -- Expanded radius around Perico
                if #(coords - vector3(4960.0, -5700.0, 20.0)) < 2000.0 then
                    local veh = GetVehiclePedIsIn(ped, false)
                    if veh ~= 0 then
                        -- Force explosion + disable vehicle
                        AddExplosion(coords.x, coords.y, coords.z, 2, 100.0, true, false, 1.0)
                        SetVehicleEngineHealth(veh, -4000)
                        SetVehicleUndriveable(veh, true)
                        TriggerEvent('chat:addMessage', { args = { '^1Perico Defences', 'Your aircraft was destroyed by anti-air!' } })
                    end
                end
            end
        end
    end
end)

-- Handle defence toggle
RegisterNetEvent('perico:defences', function(state, whitelist)
    local QBCore = exports['qb-core']:GetCoreObject()
    local PlayerData = QBCore.Functions.GetPlayerData()

    isWhitelisted = false
    if whitelist then
        for _, citizenid in pairs(whitelist) do
            if PlayerData.citizenid == citizenid then
                isWhitelisted = true
                break
            end
        end
    end

    defencesActive = state

    if state then
        spawnPatrols()
        spawnLights()
    else
        clearPatrols()
        clearLights()
    end
end)
