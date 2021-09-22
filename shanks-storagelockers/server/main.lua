Config = {}

QBCore.Functions.CreateCallback("shanks-storagelockers:server:FetchConfig", function(source, cb)
    Config.Lockers = json.decode(LoadResourceFile(GetCurrentResourceName(), "lockers.json"))
    cb(Config.Lockers)
end)

QBCore.Functions.CreateCallback("shanks-storagelockers:server:purchaselocker", function(source, cb, v, k)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local price = v.price
    local bankMoney = Player.PlayerData.money["bank"]
    if bankMoney >= price then
        Player.Functions.RemoveMoney('bank', price, "Locker Purchased")
        Config.Lockers = json.decode(LoadResourceFile(GetCurrentResourceName(), "lockers.json"))
        Config.Lockers[k]['isOwned'] = true
        SaveResourceFile(GetCurrentResourceName(), "./lockers.json", json.encode(Config.Lockers), -1)
        TriggerClientEvent('shanks-storagelockers:client:FetchConfig', -1)
        cb(bankMoney)
    else
        TriggerClientEvent('QBCore:Notify', src, 'You dont have enough money..', 'error')
        cb(bankMoney)
    end
end)


QBCore.Functions.CreateCallback("shanks-storagelockers:server:getPassword", function(source, cb, locker)
    Config.Lockers = json.decode(LoadResourceFile(GetCurrentResourceName(), "lockers.json"))
    cb(Config.Lockers[locker]["password"])
end)


RegisterNetEvent('shanks-storagelockers:server:createPassword')
AddEventHandler('shanks-storagelockers:server:createPassword', function(password, locker)
    Config.Lockers = json.decode(LoadResourceFile(GetCurrentResourceName(), "lockers.json"))
    Config.Lockers[locker]['password'] = password
    SaveResourceFile(GetCurrentResourceName(), "./lockers.json", json.encode(Config.Lockers), -1)
    TriggerClientEvent('shanks-storagelockers:client:FetchConfig', -1)
end)


QBCore.Commands.Add("locker", "Create a locker at your current location", {{name = "name", help = "Locker name"}, {name = "price", help = "Locker Price"}, {name = "slots", help = "Slots - suggested 30"}, {name = "capactiy", help = "Capacity - suggested 5,000,000"} }, true, function(source, args)
    local coords = GetEntityCoords(GetPlayerPed(source))
    name = args[1]
    price = args[2]
    slots = args[3]
    capacity = args[4]

    newlocker = {
        ["capacity"] = {},
        ["price"] = {},
        ["slots"] = {},
        ["coords"] = {}
    }

    newlocker["price"] = tonumber(price)
    newlocker["capacity"] = tonumber(capacity)
    newlocker["slots"] = tonumber(slots)
    newlocker["coords"] = {x = coords.x, y = coords.y, z = coords.z}



    local currentConfig = json.decode(LoadResourceFile(GetCurrentResourceName(), "lockers.json"))
    currentConfig[name] = newlocker

    SaveResourceFile(GetCurrentResourceName(), "lockers.json", json.encode(currentConfig), -1)

    TriggerClientEvent('shanks-storagelockers:client:FetchConfig', -1)


end, "god")