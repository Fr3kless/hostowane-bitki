ESX = nil
TriggerEvent('FineeaszKrul:getIqDogHahaha', function(obj) ESX = obj end)

local playerStates = {}
local bitkaKills = {}
local Killers = {}
local PlayersInBitka = {}


RegisterNetEvent('bitki:enter')
AddEventHandler('bitki:enter', function(currentSphere)
    local src = source
    SetPlayerState(src, 'currentSphere', currentSphere)
end)

RegisterNetEvent('bitki:exit')
AddEventHandler('bitki:exit', function(currentSphere)
    local src = source
    SetPlayerState(src, 'currentSphere', 0)
end)

ESX.RegisterServerCallback('bitki:getAvailableOrgs', function(source, cb, sphere)
    local src = source
    local currentSphere = GetPlayerState(src, 'currentSphere') or 0
    local orgsData = GetOrgsData(src, currentSphere)

    cb(orgsData)
end)

RegisterServerEvent('bitki:inviteToBitka')
AddEventHandler('bitki:inviteToBitka', function(info)
    local src = source
    local encodedInfo = json.encode(info)    
    local decodedInfo = json.decode(encodedInfo)
    local receiverPlayer = decodedInfo.receiverPlayers[1]

    TriggerClientEvent("bitki:inviteToBitka", receiverPlayer.value, info)
end)


RegisterServerEvent('bitki:startBitka')
AddEventHandler('bitki:startBitka', function(info)
    local src = source
    local selectedZone = tonumber(info.currentZone)
    local bitkaId = math.random(11111111, 99999999)
    
    local initiatorOrg = info.initiator
    local receiverOrg = info.receiver

    bitkaKills[bitkaId] = {
        [initiatorOrg] = 0,
        [receiverOrg] = 0
    }

    AddPlayersToBitkaTable(bitkaId, info)    

    for i, receiver in ipairs(info.receiverPlayers) do
        SetPlayerAndVehicleRoutingBucket(receiver.value, bitkaId)
        TriggerClientEvent('bitki:TP', receiver.value, selectedZone, "team1Position")
        TriggerClientEvent("bitki:startBitka", receiver.value, info)
        SetPlayerState(receiver.value, 'currentBitka', bitkaId)
    end
      
    for i, initiator in ipairs(info.initiatorPlayers) do
        SetPlayerAndVehicleRoutingBucket(initiator.value, bitkaId)
        TriggerClientEvent('bitki:TP', initiator.value, selectedZone, "team2Position")
        TriggerClientEvent("bitki:startBitka", initiator.value, info)
        SetPlayerState(initiator.value, 'currentBitka', bitkaId)
    end
end)

RegisterServerEvent('bitki:kill')
AddEventHandler('bitki:kill', function(bitka, killerId)
    local isIni = true
    local playerId = source
    local player = ESX.GetPlayerFromId(playerId)

    for k,v in pairs(bitka.receiverPlayers) do
        if v.name == player.name then
            isIni = false
            break
        end
    end

    if not killerId then
        if isIni then
            killerId = bitka.receiverPlayers[math.random(1,#bitka.receiverPlayers)].value
        else
            killerId = bitka.initiatorPlayers[math.random(1,#bitka.initiatorPlayers)].value
        end
    end

    local killer = ESX.GetPlayerFromId(killerId)
    local bitkaState = GetPlayerState(killer.source, "currentBitka")
    local initiatorOrg = bitka.initiator
    local receiverOrg = bitka.receiver
    local killerOrg

    -- Check if killer exists, otherwise assign the kill to the opposing team
    if killer then
        killerOrg = killer.hiddenjob.name
    else
        if player.hiddenjob.name == initiatorOrg then
            killerOrg = receiverOrg
        else
            killerOrg = initiatorOrg
        end
    end

    if bitkaState then 
        if not Killers[bitkaState] then
            Killers[bitkaState] = {}
        end

        local killerFound = false
        for i, v in ipairs(Killers[bitkaState]) do
            if v.name == killer.name then
                v.kills = v.kills + 1
                killerFound = true
                break
            end
        end

        if not killerFound then
            table.insert(Killers[bitkaState], {
                name = killer.name,
                kills = 1,
                org = killerOrg
            })
        end

        if not bitkaKills[bitkaState][killerOrg] then
            bitkaKills[bitkaState][killerOrg] = {}
        end

        bitkaKills[bitkaState][killerOrg] = bitkaKills[bitkaState][killerOrg] + 1

        local vehicles = GetAllVehicles()

        for i,vehicle in ipairs(vehicles) do
            if GetEntityRoutingBucket(vehicle) == tonumber(bitkaState) then
                SetEntityRoutingBucket(vehicle, 0)
            end
        end

        if IsBitkaOver(bitkaState, killer, player) then
            local winner = GetBitkaWinner(bitkaState, initiatorOrg, receiverOrg)
            local loser = GetBitkaLoser(bitkaState, initiatorOrg, receiverOrg)

            for i, p in ipairs(bitka.receiverPlayers) do
                TriggerClientEvent('chatMessage', p.value, "^3^*👑Ekipa ".. winner .." Wygrala bitke")
            end

            for i, p in ipairs(bitka.initiatorPlayers) do
                TriggerClientEvent('chatMessage', p.value, "^3^*👑Ekipa ".. winner .." Wygrala bitke")
            end

            if winner == initiatorOrg then
                for i, p in ipairs(bitka.initiatorPlayers) do
                    TriggerClientEvent("bitki:lootingTime", p.value, true)
                    SetPlayerAndVehicleRoutingBucket(p.value, 0)
                    TriggerEvent('fineeaszkruljebacpsy:reviveson', p.value, true)
                end
            elseif winner == receiverOrg then
                for i, p in ipairs(bitka.receiverPlayers) do
                    TriggerClientEvent("bitki:lootingTime", p.value, true)
                    SetPlayerAndVehicleRoutingBucket(p.value, 0)
                    TriggerEvent('fineeaszkruljebacpsy:reviveson', p.value, true)
                end
            end
            
            if winner ~= initiatorOrg then
                for i, p in ipairs(bitka.initiatorPlayers) do
                    TriggerClientEvent("bitki:lootingTime", p.value, false)
                    TriggerEvent('fineeaszkruljebacpsy:reviveson', p.value, true)
                    SetPlayerAndVehicleRoutingBucket(p.value, 0)
                end
            elseif winner ~= receiverOrg then
                for i, p in ipairs(bitka.receiverPlayers) do
                    TriggerClientEvent("bitki:lootingTime", p.value, false)
                    TriggerEvent('fineeaszkruljebacpsy:reviveson', p.value, true)
                    SetPlayerAndVehicleRoutingBucket(p.value, 0)
                end
            end
        end
    end
end)

-- RegisterServerEvent('bitki:kill')
-- AddEventHandler('bitki:kill', function(bitka, killerId)
--     print("kill",json.encode(bitka), killerId)
 
--     local playerId = source
--     local player = ESX.GetPlayerFromId(playerId)
--     local killer = ESX.GetPlayerFromId(killerId)

--     local initiatorOrg = bitka.initiator
--     local receiverOrg = bitka.receiver
--     local killerOrg

--     if killer and killer.hiddenjob then
--         killerOrg = killer.hiddenjob.name
--     else
--         if player.hiddenjob.name == initiatorOrg then
--             killerOrg = receiverOrg
--         else
--             killerOrg = initiatorOrg
--         end
--     end

--     print(killerOrg)



--     local bitkaState = GetPlayerState(killer and killer.source or player.source, "currentBitka")
--     print(bitkaState)
--     print(1)
--     if not bitkaState then
--         -- Handle the case when bitkaState is nil (killer is nil or invalid)
--         print(2)
--         bitkaState = player.hiddenjob.name == initiatorOrg and receiverOrg or initiatorOrg
--     end
--     print(3)

--     if not Killers[bitkaState] then
--         print(35)
--         Killers[bitkaState] = {}
--     end
--     print(4)
--     for k,v in pairs(bitka.initiatorPlayers) do
--         table.insert(Killers[bitkaState], {
--             name = v.label,
--             id = v.value,
--             kills = 0
--         })
--     end


--     for k,v in pairs(bitka.receiverPlayers) do
--         table.insert(Killers[bitkaState], {
--             name = v.label,
--             id = v.value,
--             kills = 0
--         })
--     end

--     local killerFound = false
--     local killuh = {}
--     if killer then
--         print(5)
--         for i, v in ipairs(Killers[bitkaState]) do
--             print(6)
--             if v.name == killer.name then
--                 print(7)
--                 v.kills = v.kills + 1
--                 killerFound = true
--                 killuh = killer
--                 break
--             end
--         end
--     end
--     print(8)
--     if not killerFound then
--         print(9)
--         table.insert(Killers[bitkaState], {
--             name = killer and killer.name or "Opposition",
--             kills = 1,
--             org = killerOrg
--         })

--         killuh = player
--         killuh.hiddenjob = {name = bitka.receiver}
--     end
--     print(10)
--     if not bitkaKills[bitkaState][killerOrg] then
--         print(11)
--         bitkaKills[bitkaState][killerOrg] = 0
--     end
--     print(12)
--     bitkaKills[bitkaState][killerOrg] = bitkaKills[bitkaState][killerOrg] + 1

--     local vehicles = GetAllVehicles()

--     for i,vehicle in ipairs(vehicles) do
--         if GetEntityRoutingBucket(vehicle) == tonumber(bitkaState) then
--             SetEntityRoutingBucket(vehicle, 0)
--         end
--     end

--     if IsBitkaOver(bitkaState, killuh, player) then
--         local winner = GetBitkaWinner(bitkaState, initiatorOrg, receiverOrg)
--         local loser = GetBitkaLoser(bitkaState, initiatorOrg, receiverOrg)

--         for i, p in ipairs(bitka.receiverPlayers) do
--             TriggerClientEvent('chatMessage', p.value, "^3^*👑Ekipa ".. winner .." Wygrala bitke")
--         end

--         for i, p in ipairs(bitka.initiatorPlayers) do
--             TriggerClientEvent('chatMessage', p.value, "^3^*👑Ekipa ".. winner .." Wygrala bitke")
--         end

--         if winner == initiatorOrg then
--             for i, p in ipairs(bitka.initiatorPlayers) do
--                 TriggerClientEvent("bitki:lootingTime", p.value, true)
--                 SetPlayerAndVehicleRoutingBucket(p.value, 0)
--                 TriggerEvent('fineeaszkruljebacpsy:reviveson', p.value)
--             end
--         elseif winner == receiverOrg then
--             for i, p in ipairs(bitka.receiverPlayers) do
--                 TriggerClientEvent("bitki:lootingTime", p.value, true)
--                 SetPlayerAndVehicleRoutingBucket(p.value, 0)
--                 TriggerEvent('fineeaszkruljebacpsy:reviveson', p.value)
--             end
--         end
        
--         if winner ~= initiatorOrg then
--             for i, p in ipairs(bitka.initiatorPlayers) do
--                 TriggerClientEvent("bitki:lootingTime", p.value, false)
--                 TriggerEvent('fineeaszkruljebacpsy:reviveson', p.value)
--                 SetPlayerAndVehicleRoutingBucket(p.value, 0)
--             end
--         elseif winner ~= receiverOrg then
--             for i, p in ipairs(bitka.receiverPlayers) do
--                 TriggerClientEvent("bitki:lootingTime", p.value, false)
--                 TriggerEvent('fineeaszkruljebacpsy:reviveson', p.value)
--                 SetPlayerAndVehicleRoutingBucket(p.value, 0)
--             end
--         end
--     end
-- end)


-- FUNCTIONS 

function GetBitkaLoser(bitkaId, initiatorOrg, receiverOrg)
    local team1Kills = bitkaKills[bitkaId][initiatorOrg]
    local team2Kills = bitkaKills[bitkaId][receiverOrg]
    if team1Kills > team2Kills then
        return receiverOrg
    elseif team2Kills > team1Kills then
        return initiatorOrg
    else
        return nil
    end
end

function AddPlayersToBitkaTable(bitkaId, info)
    if not PlayersInBitka[bitkaId] then
        PlayersInBitka[bitkaId] = {}
    end

    local initiatorOrg = info.initiator
    local receiverOrg = info.receiver

    if not PlayersInBitka[bitkaId][initiatorOrg] then
        PlayersInBitka[bitkaId][initiatorOrg] = {}
    end

    if not PlayersInBitka[bitkaId][receiverOrg] then
        PlayersInBitka[bitkaId][receiverOrg] = {}
    end

    for i, initiator in ipairs(info.initiatorPlayers) do
        table.insert(PlayersInBitka[bitkaId][initiatorOrg], initiator)
    end

    for i, receiver in ipairs(info.receiverPlayers) do
        table.insert(PlayersInBitka[bitkaId][receiverOrg], receiver)
    end

    return nil
end

function IsBitkaOver(bitkaId, killer, deadPlayer)
    local killerOrg = killer.hiddenjob.name
    local deadPlayerOrg = deadPlayer.hiddenjob.name

    local killerOrgKills = bitkaKills[bitkaId][killerOrg] 
    local killerOrgPlayersCount = #PlayersInBitka[bitkaId][killerOrg]

    local deadPlayerOrgKills = bitkaKills[bitkaId][deadPlayerOrg] 
    local deadPlayerOrgPlayersCount = #PlayersInBitka[bitkaId][deadPlayerOrg]

    return killerOrgKills == deadPlayerOrgPlayersCount
end

function GetBitkaWinner(bitkaId, initiatorOrg, receiverOrg)
    local team1Kills = bitkaKills[bitkaId][initiatorOrg]
    local team2Kills = bitkaKills[bitkaId][receiverOrg]
    if team1Kills > team2Kills then
        return initiatorOrg
    elseif team2Kills > team1Kills then
        return receiverOrg
    else
        return nil
    end
end

function GetOrgsData(src, sphere)
    local orgsData = {}
    local xPlayers = ESX.GetPlayers()
    local xPlayer = ESX.GetPlayerFromId(src)
    local krolarekOrg = xPlayer.hiddenjob.name

    for _, playerId in pairs(xPlayers) do
        local currentPlayer = ESX.GetPlayerFromId(playerId)
        local orgName, orgLabel = currentPlayer.hiddenjob.name, currentPlayer.hiddenjob.label
        local currentSphere = GetPlayerState(playerId, 'currentSphere') or nil

        if currentSphere == sphere and (src == playerId or krolarekOrg == orgName or krolarekOrg ~= orgName) then

            local foundOrg = false
            for _, orgData in ipairs(orgsData) do
                if orgData.name == orgName then
                    foundOrg = true
                    orgData.playerCount = orgData.playerCount + 1
                    table.insert(orgData.players, {
                        label = currentPlayer.name,
                        value = currentPlayer.source,
                    })
                    break
                end
            end

            if not foundOrg then
                local orgData = {
                    name = orgName,
                    label = orgLabel,
                    players = {},
                    playerCount = 1 + 20
                }
                table.insert(orgsData, orgData)
                table.insert(orgData.players, {
                    label = currentPlayer.name,
                    value = currentPlayer.source,
                })
            end
        end
    end

    return orgsData
end

function SetPlayerState(player, key, value)
    if not playerStates[player] then
        playerStates[player] = {}
    end

    playerStates[player][key] = value

    -- print("Updated player state for " .. GetPlayerName(player) .. ": " .. key .. " = " .. tostring(value))
end

function GetPlayerState(player, key)
    if not playerStates[player] then return nil end

    return playerStates[player][key]
end

function SetPlayerAndVehicleRoutingBucket(player, bucket)
    SetPlayerRoutingBucket(player, bucket)
    local ped = GetPlayerPed(player)
    local vehicle = GetVehiclePedIsIn(ped, false)
    SetEntityRoutingBucket(vehicle, bucket)
end

-- RegisterCommand("checkucket", function(src)
--     print(GetPlayerName(src).. " BUCKET: " .. GetPlayerRoutingBucket(src))
-- end)

AddEventHandler('playerDropped', function (reason)
    print('Player ' .. GetPlayerName(source) .. ' dropped (Reason: ' .. reason .. ')')
end)