if Config.QBCore == 'new' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.QBCore == 'old' then
    QBCore = nil
    Wait(5)
    Citizen.CreateThread(function() --add an onplayer loaded for blips and config fetch as well as this thread
        while QBCore == nil do
            TriggerEvent("QBCore:GetObject", function(obj) QBCore = obj end)
            Citizen.Wait(100) 
        end
        TriggerEvent('shanks-storagelockers:client:FetchConfig')
        TriggerEvent('shanks-storagelockers:client:setupBlips')
    end)
end

local OwnedLockerBlips = {}
local currentLocker, lockerName

RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    TriggerEvent('shanks-storagelockers:client:FetchConfig')
    TriggerEvent('shanks-storagelockers:client:setupBlips')
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload')
AddEventHandler('QBCore:Client:OnPlayerUnload', function()
    for _, v in pairs(OwnedLockerBlips) do
        RemoveBlip(v)
    end
end)

RegisterNetEvent('shanks-storagelockers:client:FetchConfig')
AddEventHandler('shanks-storagelockers:client:FetchConfig', function()
    QBCore.Functions.TriggerCallback("shanks-storagelockers:server:FetchConfig", function(lockers)
        CheckLockers = lockers
    end)
end)

RegisterNetEvent('shanks-storagelockers:client:setupBlips')
AddEventHandler('shanks-storagelockers:client:setupBlips', function()
    for _, v in pairs(OwnedLockerBlips) do
        RemoveBlip(v)
    end
    QBCore.Functions.TriggerCallback('shanks-storagelockers:server:getOwnedLockers', function(ownedLockers)
        if ownedLockers ~= nil then
            for _, v in pairs(ownedLockers) do
                local locker = CheckLockers[v]['coords']
                local lockerBlip = AddBlipForCoord(locker.x, locker.y, locker.z)
                SetBlipSprite (lockerBlip, 50)
                SetBlipDisplay(lockerBlip, 4)
                SetBlipScale  (lockerBlip, 0.65)
                SetBlipAsShortRange(lockerBlip, true)
                SetBlipColour(lockerBlip, 3)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentSubstringPlayerName("Storage Locker")
                EndTextCommandSetBlipName(lockerBlip)
                table.insert(OwnedLockerBlips, lockerBlip)
            end
        end
    end)
end)

Citizen.CreateThread(function()
    while true do
        sleep = 1000
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            if CheckLockers ~= nil then
                for k, v in pairs(CheckLockers) do
                    local dist = #(pos - vector3(v["coords"].x, v["coords"].y, v["coords"].z))
                    if dist < 1.5 then
                        currentLocker = v
                        lockerName = k
                        sleep = 3
                        DrawText3D(v["coords"].x, v["coords"].y, v["coords"].z, "~g~E~w~ - To use locker")
                        if IsControlJustReleased(0, 38) then
                            TriggerEvent("shanks-storagelockers:client:interact", k, v)
                        end
                    end
                end
            end
    Wait(sleep)
    end
end)

RegisterNetEvent("shanks-storagelockers:client:interact")
AddEventHandler("shanks-storagelockers:client:interact", function(k, v)
    local lockername = k
    local lockertable = v
    local citizenid = QBCore.Functions.GetPlayerData().citizenid
    PlayerJob = QBCore.Functions.GetPlayerData().job
    TriggerEvent('nh-context:sendMenu', { --send the close button all the time
        {
            id = 0,
            header = "Locker "..lockername,
            txt = "",
        },
    })
    if not lockertable["isOwned"] then
        TriggerEvent('nh-context:sendMenu', { --if not owned send the purchase button to the menu
            {
                id = 2,
                header = "Purchase",
                txt = "Purchase Locker for $" .. v.price,
                params = {
                    event = "shanks-storagelockers:client:purchase",
                }
            },
        })
    elseif lockertable["isOwned"] then
        TriggerEvent('nh-context:sendMenu', { --if locker is owned send these buttons to the menu
            {
                id = 3,
                header = "Open Locker",
                txt = "",
                params = {
                    event = "shanks-storagelockers:client:openLocker",
                }
            },
        })
    end
    if lockertable["owner"] == citizenid then
        TriggerEvent('nh-context:sendMenu', { --send the close button all the time
            {
                id = 4,
                header = "Change Passcode",
                txt = "",
                params = {
                    event = "shanks-storagelockers:client:changePasscode", 
                }
            },
            {
                id = 5,
                header = "Sell Locker",
                txt = "",
                params = {
                    event = "shanks-storagelockers:client:sellLocker",
                    args = {
                        lockername = lockername,
                        lockertable = lockertable
                    }
                }
            },
        })
    end
        if PlayerJob.name == "police" then
        TriggerEvent('nh-context:sendMenu', {
            {
                id = 6,
                header = "Raid Locker",
                txt = "",
                params = {
                    event = "shanks-storagelockers:client:raidLocker", 
                    args = {
                        lockername = lockername,
                        lockertable = lockertable
                    }
                }
            },
        })
    end
    TriggerEvent('nh-context:sendMenu', { --send the close button all the time
        {
            id = 9999,
            header = "Close Menu",
            txt = "",
            params = {
                event = "nh-context:closeMenu",
            }
        },
    })
end)

RegisterNetEvent('shanks-storagelockers:client:sellLocker')
AddEventHandler('shanks-storagelockers:client:sellLocker', function(data)
    TriggerServerEvent('shanks-storagelockers:server:sellLocker', data.lockername, data.lockertable)
end)

RegisterNetEvent('shanks-storagelockers:client:changePasscode')
AddEventHandler('shanks-storagelockers:client:changePasscode', function()
    SendNUIMessage({
        type = "changePasscode",
        action = "openKeypad",
    })
    SetNuiFocus(true, true)
end)

RegisterNetEvent('shanks-storagelockers:client:raidLocker')
AddEventHandler('shanks-storagelockers:client:raidLocker', function(data)
    QBCore.Functions.TriggerCallback('QBCore:HasItem', function(HasItem)
        if HasItem then
            QBCore.Functions.Progressbar("raid_locker", "Raiding Locker ..", math.random(6000,8000), false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }, {
                animDict = "amb@prop_human_bum_bin@idle_a", -- Knocking Animation | Change Needed
                anim = "idle_a", -- Knocking Animation | Change Needed
                flags = 6, -- Knocking Animation | Change Needed
            }, {}, {}, function()
                ClearPedTasks(PlayerPedId())
                TriggerServerEvent("inventory:server:OpenInventory", "stash", data.lockername, {
                    maxweight = currentLocker.capacity,
                    slots = currentLocker.slots,
                    })
                TriggerEvent("inventory:client:SetCurrentStash", data.lockername) 
            end, function()
                QBCore.Functions.Notify("You cancelled the Task?", "error")
                ClearPedTasks(PlayerPedId())
            end)
        else
            QBCore.Functions.Notify("You don't have a Stormram on you..", "error")
        end
    end, 'police_stormram' )
end)

RegisterNetEvent('shanks-storagelockers:client:purchase') --trigger event after nh-context purchase button. Set password which then starts the buying process
AddEventHandler('shanks-storagelockers:client:purchase', function()
    QBCore.Functions.TriggerCallback('shanks-storagelockers:server:purchaselocker', function(bankmoney)
        if bankmoney >= currentLocker.price then
            QBCore.Functions.Notify("Please set a password")
            SendNUIMessage({
                type = "create",
                action = "openKeypad",
            })
            SetNuiFocus(true, true)
        end
    end)
end)

RegisterNetEvent('shanks-storagelockers:client:openLocker') --trigger event after nh-context open locker button. Opens the password UI for the locker
AddEventHandler('shanks-storagelockers:client:openLocker', function()
    SendNUIMessage({
        type = "attempt",
        action = "openKeypad",
    })
    SetNuiFocus(true, true)
end)

function DrawText3D(x, y, z, text)
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

RegisterNUICallback('PadLockClose', function()
    SetNuiFocus(false, false)
end)

RegisterNUICallback("CombinationSound", function()
    PlaySound(-1, "Place_Prop_Fail", "DLC_Dmod_Prop_Editor_Sounds", 0, 0, 1)
end)

RegisterNUICallback('UseCombination', function(data, _)
    if data.type == 'attempt' then
        QBCore.Functions.TriggerCallback('shanks-storagelockers:server:getData', function(combination)
            if tonumber(data.combination) ~= nil then
                if tonumber(data.combination) == tonumber(combination) then
                    SendNUIMessage({
                        action = "closeKeypad",
                        error = false,
                    })
                    SetNuiFocus(false, false)
                    TriggerServerEvent("inventory:server:OpenInventory", "stash", lockerName, {
                    maxweight = currentLocker.capacity,
                    slots = currentLocker.slots,
                    })
                    TriggerEvent("inventory:client:SetCurrentStash", lockerName)
                    --takeAnim()
                else
                    QBCore.Functions.Notify("Incorrect Password", 'error')
                    SendNUIMessage({
                        action = "closeKeypad",
                        error = true,
                    })
                    SetNuiFocus(false, false)
                end
            else
              QBCore.Functions.Notify("Incorrect Password", 'error')
              SendNUIMessage({
                  action = "closeKeypad",
                  error = true,
              })
              SetNuiFocus(false, false)
            end
        end, lockerName, 'password')
    elseif data.type == 'create' then
        SendNUIMessage({
            action = "closeKeypad",
            error = false,
        })
        SetNuiFocus(false, false)
        numberCombination = tonumber(data.combination)
        if data.combination ~= nil and numberCombination ~= nil and string.len(tostring(numberCombination)) == 4 then
            QBCore.Functions.TriggerCallback('shanks-storagelockers:server:purchaselocker', function(bankmoney)
                if bankmoney >= currentLocker.price then
                    TriggerServerEvent("shanks-storagelockers:server:createPassword", data.combination, lockerName)
                    TriggerEvent('shanks-storagelockers:client:FetchConfig')
                    TriggerEvent('shanks-storagelockers:client:setupBlips')
                    QBCore.Functions.Notify("You have purchased this locker","success")
                end
            end, currentLocker, lockerName)
        else
            QBCore.Functions.Notify("Invalid Password. Please use a 4 digit pin.", "error")
        end
    elseif data.type == 'changePasscode' then
        SendNUIMessage({
            action = "closeKeypad",
            error = false,
        })
        SetNuiFocus(false, false)
        numberCombination = tonumber(data.combination)
        if data.combination ~= nil and numberCombination ~= nil and string.len(tostring(numberCombination)) == 4 then
            TriggerServerEvent("shanks-storagelockers:server:changePasscode", data.combination, lockerName, currentLocker)
        else
            QBCore.Functions.Notify("Invalid Password. Please use a 4 digit pin.", "error")
        end
    else 
        SendNUIMessage({
            action = "closeKeypad",
            error = false,
        })
        SetNuiFocus(false, false)
    end
end)