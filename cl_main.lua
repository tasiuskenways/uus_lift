local utils = require 'modules.utils'
local liftZone
local QBCore
if Lift.QB then
    QBCore = exports['qb-core']:GetCoreObject()
end

local function addLiftOptions(data, liftName)
    local liftInfo
    for _, v in ipairs(data) do
        for _, j in ipairs(v.liftData) do
            liftInfo = {
                menuId = 'lift_for_' .. v.lift,
                icon = 'elevator',
                title = 'Elevator ' .. string.gsub(v.lift, '_', ' '),
                event = 'uus_pack:client:lift',
                args = v.liftData
            }
            if liftInfo.menuId == liftName then
                utils.radialAdd(liftInfo)
                break
            end
        end
    end
end

RegisterNetEvent('uus_pack:client:lift', function(data)
    local liftOptions = {}
    local playerJob = ''
    if Lift.QB then
        local Player = QBCore.Functions.GetPlayerData()
        playerJob = Player.job.name
    else
        playerJob = QBX.PlayerData.job.name
    end
    for _, v in ipairs(data) do
        if playerJob == v.job then
            liftOptions[#liftOptions + 1] = {
                title = v.label,
                icon = 'elevator',
                onSelect = function()
                    SetEntityCoords(cache.ped, v.coords.x, v.coords.y, v.coords.z)
                end,
            }
        elseif v.job == '' or nil then
            liftOptions[#liftOptions + 1] = {
                title = v.label,
                icon = 'elevator',
                onSelect = function()
                    SetEntityCoords(cache.ped, v.coords.x, v.coords.y, v.coords.z)
                end,
            }
        end
    end
    lib.registerContext({
        id = 'uus_pack_lift',
        title = 'Choose Floor',
        options = liftOptions
    })
    lib.showContext('uus_pack_lift')
end)

local function createLiftZone()
    local liftData = {}
    for k, v in pairs(Lift.Data) do
        table.insert(liftData, {
            lift = k,
            liftData = v
        })
        for _, j in ipairs(v) do
            liftZone = lib.zones.box({
                name = k .. 'lift_zone',
                coords = j.coords,
                size = j.size,
                rotation = j.rot,
                debug = Lift.Debug,
                onEnter = function()
                    if Lift.UseRadial then
                        lib.showTextUI(string.gsub(k, '_', ' ') .. ' Lift | Select Floor')
                        addLiftOptions(liftData, 'lift_for_' .. k)
                    else
                        if IsControlJustPressed(0, 38) then
                            lib.showTextUI(string.gsub(k, '_', ' ') .. ' Lift | [E] Select Floor')
                        end
                    end
                end,
                onExit = function()
                    lib.hideTextUI()
                    utils.radialRemove('lift_for_' .. k)
                end,
            })
        end
    end
end

local function init()
    if liftZone ~= nil then
        for k, v in pairs(liftZone) do
            liftZone[k]:remove()
        end
    end
    createLiftZone()
end

local helpText = {
    ('------ Lift Creator ------  \n'),
    ('[F] To Add Point  \n'),
    ('[Enter] To Finish  \n'),
    ('[Backspace] To Stop \n')
}

local addedFloor = {}

local function addLiftOptions()
    local playerpos = GetEntityCoords(cache.ped)
    local input = lib.inputDialog('Lift Creator', {
        { type = 'input',  label = 'Label',          placeholder = '1st Floor', required = true },
        { type = 'number', label = 'Size',           placeholder = '2',         required = false },
        { type = 'input',  label = 'Job (Optional)', placeholder = 'police' }
    })

    if not input then return end

    local size = {
        x = input[2] or 2,
        y = input[2] or 2,
        z = input[2] or 2,
    }

    addedFloor[#addedFloor + 1] = {
        label = input[1],
        coords = playerpos,
        size = size,
        job = input[3] or '',
    }
end

local function onFinishAction()
    local input = lib.inputDialog('Lift Creator', {
        { type = 'input', label = 'Lift Name', placeholder = 'MRPD LIFT', required = true },
    })

    if not input then return end
    local label = input[1]:gsub(' ', '_')

    local finalLift = {
        [label] = addedFloor
    }

    TriggerServerEvent('uus_lift:server:liftCreatorSave', finalLift)
end

local isCreatingLift = false

local function createLiftThread()
    while isCreatingLift do
        if IsControlJustPressed(0, 23) then -- f
            print('F')
            addLiftOptions()
        end

        if IsControlJustPressed(0, 194) then -- backspace
            isCreatingLift = false
            lib.hideTextUI()
        end

        if IsControlJustPressed(0, 201) then -- enter
            isCreatingLift = false
            lib.hideTextUI()
            onFinishAction()
        end
        Wait(1)
    end
end

RegisterNetEvent('uus_lift:client:startLiftCreator', function()
    if not isCreatingLift then
        isCreatingLift = true
        lib.showTextUI(table.concat(helpText))
        createLiftThread()
    else
        local alert = lib.alertDialog({
            header = 'Warning',
            content = 'You Already Run This Command \n Press Confirm To Turn Off',
            centered = true,
            cancel = true
        })
        if alert == 'confirm' then
            isCreatingLift = false
            lib.hideTextUI()
        end
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    init()
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= cache.resource then return end
    init()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    for k, v in pairs(liftZone) do
        liftZone[k]:remove()
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end
    for k, v in pairs(liftZone) do
        liftZone[k]:remove()
    end
end)

AddStateBagChangeHandler('uus_lift_lift_zone', 'global', function(bagname, key, value)
    if value then
        Lift.Data = value
        init()
    end
end)
