isLoggedIn = true
QBCore = nil
Config = {}
local currentLocker, lockerName

Citizen.CreateThread(function()
    while QBCore == nil do
        TriggerEvent("QBCore:GetObject", function(obj) QBCore = obj end)
        Citizen.Wait(100) 
    end

    TriggerEvent('shanks-storagelockers:client:FetchConfig')

end)

RegisterNetEvent('shanks-storagelockers:client:FetchConfig')
AddEventHandler('shanks-storagelockers:client:FetchConfig', function()
    QBCore.Functions.TriggerCallback("shanks-storagelockers:server:FetchConfig", function(lockers)
        Config.Lockers = lockers
    end)
end)

Citizen.CreateThread(function() 
    while true do
        sleep = 1000
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            if Config.Lockers ~= nil then
                for k, v in pairs(Config.Lockers) do
                    local dist = #(pos - vector3(v["coords"].x, v["coords"].y, v["coords"].z))
                    if dist < 1.5 then
                        currentLocker = v
                        lockerName = k
                        sleep = 5
                        if v["isOwned"] then
                            DrawText3D(v["coords"].x, v["coords"].y, v["coords"].z, "~g~E~w~ - To open locker")
                            if IsControlJustReleased(0, 38) then
                                SendNUIMessage({
                                    type = "attempt",
                                    action = "openKeypad",
                                })
                                SetNuiFocus(true, true)
                            end
                        else
                            DrawText3D(v["coords"].x, v["coords"].y, v["coords"].z, "~g~E~w~ - To purchase locker for " .. "~g~$"..v.price.."~g~")
                            if IsControlJustReleased(0, 38) then
                                QBCore.Functions.Notify("Please set a password")
                                SendNUIMessage({
                                    type = "create",
                                    action = "openKeypad",
                                })
                                SetNuiFocus(true, true)
                            end
                        end
                    end
                end
            end
    Wait(sleep)
    end
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

RegisterNUICallback("CombinationSound", function(data, cb)
    PlaySound(-1, "Place_Prop_Fail", "DLC_Dmod_Prop_Editor_Sounds", 0, 0, 1)
end)

RegisterNUICallback('UseCombination', function(data, cb)

    if data.type == 'attempt' then

        QBCore.Functions.TriggerCallback('shanks-storagelockers:server:getPassword', function(combination)
            if tonumber(data.combination) ~= nil then
                if tonumber(data.combination) == tonumber(combination) then
                    SetNuiFocus(false, false)
                    SendNUIMessage({
                        action = "closeKeypad",
                        error = false,
                    })
                    TriggerServerEvent("inventory:server:OpenInventory", "stash", lockerName, {
                    maxweight = currentLocker.capacity,
                    slots = currentLocker.slots,
                    })
                    TriggerEvent("inventory:client:SetCurrentStash", lockerName)   

                    --takeAnim()
                else
                    QBCore.Functions.Notify("Incorrect Password", 'error')
                    SetNuiFocus(false, false)
                    SendNUIMessage({
                        action = "closeKeypad",
                        error = true,
                    })
                end
            end
        
        end, lockerName)



    elseif data.type == 'create' then
        SendNUIMessage({
            action = "closeKeypad",
            error = false,
        })
        if data.combination ~= nil then
            QBCore.Functions.TriggerCallback('shanks-storagelockers:server:purchaselocker', function(bankmoney)
                if bankmoney >= currentLocker.price then
                    TriggerServerEvent("shanks-storagelockers:server:createPassword", data.combination, lockerName)
                    TriggerEvent('shanks-storagelockers:client:FetchConfig')
                    QBCore.Functions.Notify("You have purchased this locker","success")
                end
            end, currentLocker, lockerName)
        end
    end
end)