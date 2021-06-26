-- Created by Dalrae

--[[ CONFIG ]]
local validRoutes = { -- First checkpoint and last checkpoint have to be the same since I'm fucking dumb
    {
        vector3(-221, 6148, 30.1),
        vector3(-109, 6260, 30.1),
        vector3(-165, 6349, 30.3),
        vector3(-291, 6245, 30.3),
        vector3(-221, 6148, 30.1),
    }
}
--[[ END CONFIG ]]
function getDistance(a, b, noZ) -- Gets distance between two coords, third arg being true ignores the Z coord (up-down)
	local x, y, z = a.x-b.x, a.y-b.y, a.z-b.z
	if noZ then 
		return math.floor(math.sqrt(x*x+y*y))
	else
		return math.floor(math.sqrt(x*x+y*y+z*z))
	end
end


local route = validRoutes[math.random(1, #validRoutes)]
local gameInfo = {}
gameInfo.Checkpoints = {}
for pointIndex, routePoint in pairs(route) do
    if pointIndex < #route then
        table.insert(gameInfo.Checkpoints, {
            ["Position"] = routePoint,
            ["NextPosition"] = route[pointIndex+1]
        })
    else
        table.insert(gameInfo.Checkpoints, {
            ["Position"] = routePoint
        })
    end
end

gameInfo.Players = {}
gameInfo.NumLaps = 2
local spawnPositions = {}
local vehicleSpacing = {
    ["Side"] = 5,
    ["Front"] = 10
}
gameInfo.DefaultSpawn = {
    ["Position"] = vector3(-251, 6125, 31),
    ["Heading"] = 315.0 -- Top Left
}
function getDirectionVectorFromHeading(heading)
    return norm(-vector3(math.cos(math.rad(heading-90)), math.sin(math.rad(heading-90)), 0))
end
function getNewSpawnPosition()
    local normalizedForward = getDirectionVectorFromHeading(gameInfo.DefaultSpawn.Heading)
    local normalizedRight = getDirectionVectorFromHeading(gameInfo.DefaultSpawn.Heading-90)
    local newSpawn
    if (#spawnPositions)%2 == 0 then -- Should spawn next vehicle on the left
        newSpawn = gameInfo.DefaultSpawn.Position-(normalizedForward*(#spawnPositions*vehicleSpacing.Front))
    else -- Should spawn next vehicle on the right
        newSpawn = gameInfo.DefaultSpawn.Position+(normalizedRight*vehicleSpacing.Side)-(normalizedForward*((#spawnPositions-1)*vehicleSpacing.Front))
    end
    table.insert(spawnPositions, newSpawn)
    return newSpawn
end
RegisterServerEvent("DalraeEvent:Ping", function()
    gameInfo.Players[source] = {
        ["Name"] = GetPlayerName(source),
        ["CurrentLap"] = 1,
        ["CurrentCheckpoint"] = 1,
        ["Place"] = 1,
        ["SpawnPosition"] = getNewSpawnPosition()
    }
    TriggerClientEvent("DalraeEvent:ReceiveGameInfo", source, gameInfo)
end)

function findKeyFromVal(table, val)
    for key,valT in pairs(table) do
        if val == valT then
            return key
        end
    end
end
function alphabeticalSortByValue(tab, f)
    local sortedTab = {}
    local sortedKeyTab = {}
    for _,val in pairs(tab) do
        table.insert(sortedTab, val) 
    end
    table.sort(sortedTab, f)
    for _,sortedVal in pairs(sortedTab) do
        table.insert(sortedKeyTab, findKeyFromVal(tab, sortedVal))
    end
    local i = 0      -- iterator variable
    local iter = function ()   -- iterator function
        i = i + 1
        if sortedTab[i] == nil then 
            return nil
        else 
            return sortedKeyTab[i], sortedTab[i]
        end
    end
    return iter
end
function getPlace(wantedPlayer)
    local places = {}
    for playerID, player in pairs(gameInfo.Players) do
        table.insert(places, {
            ["ID"] = playerID,
            ["CurrentLap"] = player.CurrentLap,
            ["CurrentCheckpoint"] = player.CurrentCheckpoint,
            ["DistanceFromNextCheckpoint"] = getDistance(GetEntityCoords(GetPlayerPed(playerID)), (gameInfo.Checkpoints[player.CurrentCheckpoint] and gameInfo.Checkpoints[player.CurrentCheckpoint].NextPosition) or GetEntityCoords(GetPlayerPed(playerID)))
        })
    end
    table.sort(places, function(a, b)
        return (a.CurrentLap >= b.CurrentLap and
        (a.CurrentLap > b.CurrentLap or
            (a.CurrentCheckpoint >= b.CurrentCheckpoint and
                (a.CurrentCheckpoint > b.CurrentCheckpoint or a.DistanceFromNextCheckpoint < b.DistanceFromNextCheckpoint))))
    end)
    for place,player in pairs(places) do
        if player.ID == wantedPlayer then
            return place
        end
    end
end
CreateThread(function()
    while true do
        Wait(1000)
        for playerID,player in pairs(gameInfo.Players) do
            gameInfo.Players[playerID].Place = getPlace(playerID)
        end
        TriggerClientEvent("DalraeEvent:ReceiveGameInfo", -1, gameInfo)
    end
end)
RegisterServerEvent("DalraeEvent:PassedCheckpoint", function()
    gameInfo.Players[source].CurrentCheckpoint = gameInfo.Players[source].CurrentCheckpoint+1
    if gameInfo.Players[source].CurrentCheckpoint > #gameInfo.Checkpoints then
        gameInfo.Players[source].CurrentCheckpoint = 0
        gameInfo.Players[source].CurrentLap = gameInfo.Players[source].CurrentLap+1
    end
end)

RegisterServerEvent("DalraeEvent:Win", function()
    if not gameInfo.GameWon then
        gameInfo.GameWon = source
    end
end)
