if Config.QBCore == 'new' then
    QBCore = exports['qb-core']:GetCoreObject()
end

pData = {}

QBCore.Functions.CreateCallback("shanks-storagelockers:server:FetchConfig", function(_, cb)
    CheckLockers = json.decode(LoadResourceFile(GetCurrentResourceName(), "lockers.json"))
    cb(CheckLockers)
end)

QBCore.Functions.CreateCallback("shanks-storagelockers:server:purchaselocker", function(source, cb, v, k)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local CitizenID = Player.PlayerData.citizenid
    local price = v.price
    local bankMoney = Player.PlayerData.money["bank"]
    if bankMoney >= price then
        Player.Functions.RemoveMoney('bank', price, "Locker Purchased")
        CheckLockers = json.decode(LoadResourceFile(GetCurrentResourceName(), "lockers.json"))
        CheckLockers[k]['isOwned'] = true
        CheckLockers[k]['owner'] = CitizenID
        SaveResourceFile(GetCurrentResourceName(), "./lockers.json", json.encode(CheckLockers), -1)
        TriggerClientEvent('shanks-storagelockers:client:FetchConfig', -1)
        TriggerClientEvent('shanks-storagelockers:client:setupBlips', src)
        cb(bankMoney)
    else
        TriggerClientEvent('QBCore:Notify', src, 'You dont have enough money..', 'error')
        cb(bankMoney)
    end
end)

QBCore.Functions.CreateCallback("shanks-storagelockers:server:getData", function(_, cb, locker, data)  --make this a fetch event for everything and then pass through what you wanna fetch
    CheckLockers = json.decode(LoadResourceFile(GetCurrentResourceName(), "lockers.json"))
    cb(CheckLockers[locker][data])
end)

QBCore.Functions.CreateCallback('shanks-storagelockers:server:getOwnedLockers', function(source, cb)
    local src = source
    local pData = QBCore.Functions.GetPlayer(src)
    local citizenID = pData.PlayerData.citizenid
    local ownedLockers = {}
    if pData then
        CheckLockers = json.decode(LoadResourceFile(GetCurrentResourceName(), "lockers.json"))
        for k, v in pairs(CheckLockers) do
            if citizenID == v["owner"] then
                table.insert(ownedLockers, k)
            end
        end
        if ownedLockers ~= nil then
            cb(ownedLockers)
        else
            cb(nil)
        end
    end
end)

RegisterNetEvent('shanks-storagelockers:server:changePasscode')
AddEventHandler('shanks-storagelockers:server:changePasscode', function(newPasscode, lockername, _)
    local src = source
    CheckLockers = json.decode(LoadResourceFile(GetCurrentResourceName(), "lockers.json"))
    CheckLockers[lockername]['password'] = newPasscode
    SaveResourceFile(GetCurrentResourceName(), "./lockers.json", json.encode(CheckLockers), -1)
    TriggerClientEvent('shanks-storagelockers:client:FetchConfig', -1)
    TriggerClientEvent('QBCore:Notify', src, 'Passcode Changed', 'success')
end)

RegisterNetEvent('shanks-storagelockers:server:sellLocker')
AddEventHandler('shanks-storagelockers:server:sellLocker', function(lockername, lockertable)
    --add extra checks to make sure they own the locker
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local price = lockertable.price
    local saleprice = price - ((tonumber(price)/100) * 10)
    CheckLockers[lockername]['isOwned'] = false
    CheckLockers[lockername]['owner'] = '' --will this work?
    Player.Functions.AddMoney('bank', saleprice, "Locker Sold")
    SaveResourceFile(GetCurrentResourceName(), "./lockers.json", json.encode(CheckLockers), -1)
    TriggerClientEvent('QBCore:Notify', src, 'Locker sold for ' .. saleprice, 'success')
    TriggerClientEvent('shanks-storagelockers:client:setupBlips', src)
    TriggerClientEvent('shanks-storagelockers:client:FetchConfig', -1)
end)

RegisterNetEvent('shanks-storagelockers:server:createPassword')
AddEventHandler('shanks-storagelockers:server:createPassword', function(password, locker)
    CheckLockers = json.decode(LoadResourceFile(GetCurrentResourceName(), "lockers.json"))
    CheckLockers[locker]['password'] = password
    SaveResourceFile(GetCurrentResourceName(), "./lockers.json", json.encode(CheckLockers), -1)
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