-- Created by Dalrae
local tick = 1
local gameInfo = {}
local oldServerGameInfo = {}
local myVehicle
local checkpointBlip
local lastLapStartTime
TriggerServerEvent("DalraeEvent:Ping")
RegisterNetEvent("DalraeEvent:ReceiveGameInfo", function(serverGameInfo)
    gameInfo = serverGameInfo
end)
function NitroBoost()
    CreateThread(function()
        if IsPedInAnyVehicle(PlayerPedId()) then
            local vehicleSpeed = GetEntitySpeed(GetVehiclePedIsIn(PlayerPedId()))
            SetVehicleBoostActive(GetVehiclePedIsIn(PlayerPedId()), true)
            SetVehicleForwardSpeed(GetVehiclePedIsIn(PlayerPedId()), vehicleSpeed+10)
            AnimpostfxStop('RaceTurbo')
            AnimpostfxPlay('RaceTurbo', 0, false)
            SetTimecycleModifier('rply_motionblur')
            ShakeGameplayCam('SKY_DIVING_SHAKE', 0.25)
            Wait(1000)
            StopGameplayCamShaking(true)
            SetTransitionTimecycleModifier('default', 0.35)
        end
    end)
end

function makeVehicle(model, pos, heading)
    local model = GetHashKey(model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end
    return CreateVehicle(model, pos, heading,true,true)
end

function formatOrdinally(number)
	local ordinalAbrev = {
		["1"] = "st", 
		["2"] = "nd",
		["3"] = "rd",
		["4"] = "th",
		["5"] = "th",
		["6"] = "th",
		["7"] = "th",
		["8"] = "th",
		["9"] = "th",
		["0"] = "th",
	}
	local stringNum = tostring(number)
	local lastDigit = tostring(number):sub(#stringNum, #stringNum)
	local secondToLastDigit = nil
	if #stringNum > 1 then
		secondToLastDigit = tostring(number):sub(#stringNum-1, #stringNum-1)
	end
	if secondToLastDigit == "1" then
		return stringNum.."th"
	else
		for num,ordinal in pairs(ordinalAbrev) do
			if lastDigit == num then
				return stringNum..ordinal
			end
		end
	end
end

function DrawTxt(x, y, text, center, scale, font)
    SetTextFont(font or 4)
    SetTextProportional(0)
    SetTextScale(scale or 0.45, scale or 0.45)
    SetTextColour(255, 255, 255, 255)
    SetTextDropShadow(0, 0, 0, 0,255)
    SetTextEdge(2, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextCentre(center == true)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end
function formatTime(time)
    local minutes = math.floor((time)/(120000))
    local seconds = math.floor((time%60000)/1000)
    local ms = math.floor((time%1000)/10)
    if ms < 10 then
        ms = ("0%s"):format(ms)
    end
    if seconds < 10 then
        seconds = ("0%s"):format(seconds)
    end
    if minutes < 10 then
        minutes = ("0%s"):format(minutes)
    end
    return ("%s:%s.%s"):format(minutes, seconds, ms)
end
local cR, cG, cB, cA = 247, 198, 104, 100
local cIR, cIG, cIB, cIA = 108, 183, 220, 220
function enteredCheckpoint(checkpoint)
    CreateThread(function()
        local curIR, curIG, curIB, curIA = cIR, cIG, cIB, cIA
        local curA = cA
        CreateThread(function()
            for a=cA, 0,-15 do
                Wait(0)
                curA = a
                SetCheckpointRgba(checkpoint, cR, cG, cB, curA)
            end
        end)
        CreateThread(function()
            for r=cIR,255,5 do
                Wait(0)
                curIR = r
                SetCheckpointRgba2(checkpoint, curIR, curIG, curIB, curIA)
            end
        end)
        CreateThread(function()
            for g=cIG, 255,5 do
                Wait(0)
                curIG = g
                SetCheckpointRgba2(checkpoint, curIR, curIG, curIB, curIA)
            end
        end)
        CreateThread(function()
            for b=cIB, 255,5 do
                Wait(0)
                curIB = b
                SetCheckpointRgba2(checkpoint, curIR, curIG, curIB, curIA)
            end
        end)
        Wait(40)
        for a=cIA, 0,-3 do
            Wait(0)
            curIA = a
            SetCheckpointRgba2(checkpoint, curIR, curIG, curIB, curIA)
        end
        DeleteCheckpoint(checkpoint)
    end)
end
local lastRespawnTime = 0
function respawnVehicle()
    if GetGameTimer()-lastRespawnTime > 1000*tick then
        lastRespawnTime = GetGameTimer()
        CreateThread(function()
            SetTimecycleModifier("Bloom")
            for i = 1,350,10 do -- More than 255 to prolong the affect
                SetTimecycleModifierStrength(i/255)
                DrawRect(0.5,0.5,1.0,1.0,0,0,0,i)
                Wait(0)
            end
            if DoesEntityExist(myVehicle) then
                DeleteEntity(myVehicle)
            end
            myVehicle = makeVehicle("neon", gameInfo.Players[GetPlayerServerId(PlayerId())].SpawnPosition.xyz, gameInfo.DefaultSpawn.Heading)
            SetPedIntoVehicle(PlayerPedId(), myVehicle, -1)
            SetVehicleEngineOn(myVehicle, true, true)
            if gameInfo.Checkpoints[gameInfo.Players[GetPlayerServerId(PlayerId())].CurrentCheckpoint-1] then
                SetEntityCoords(myVehicle, gameInfo.Checkpoints[gameInfo.Players[GetPlayerServerId(PlayerId())].CurrentCheckpoint-1].Position)
            else -- Is the first checkpoint
                SetEntityCoords(myVehicle, gameInfo.Players[GetPlayerServerId(PlayerId())].SpawnPosition)
            end
            for i = 350,1,-10 do -- More than 255 to prolong the affect
                SetTimecycleModifierStrength(i/255)
                DrawRect(0.5,0.5,1.0,1.0,0,0,0,i)
                Wait(0)
            end
            ClearTimecycleModifier()
        end)
    end
end
local respawnBarProgress = 0
function LoadRace(checkpoints)
    local currentCheckpointIndex = 1
    local checkpoint = CreateCheckpoint(0, checkpoints[currentCheckpointIndex].Position.xyz, checkpoints[currentCheckpointIndex].NextPosition.xyz, 10.0, cR, cG, cB, cA, 100, 100)
    SetCheckpointRgba2(checkpoint, cIR, cIG, cIB, cIA)
    SetCheckpointScale(checkpoint, 0.4) -- Sets the checkpoint's icon Z offset
    SetCheckpointCylinderHeight(checkpoint, 5.0, 5.0, 10.0)

    CreateThread(function()
        while true do
            Wait(0)
            
            
            --[[DrawRect(0.92, 0.86, 0.02, 0.01, 158, 26, 33, 255.0)
            DrawRect(0.94, 0.86, 0.03, 0.01, 78, 33, 33, 255.0)]]
            DisableControlAction(0,75)
            if IsDisabledControlPressed(0, 75) then -- F
                if GetGameTimer()-lastRespawnTime > 5000*tick then
                    respawnBarProgress = respawnBarProgress+0.0005
                    if respawnBarProgress > 0.05 then
                        respawnBarProgress = 0
                        respawnVehicle()
                    end
                    DrawTxt(0.87, 0.85, "RESPAWNING", true, 0.3)
                    DrawRect(0.895+(respawnBarProgress/2), 0.86, respawnBarProgress, 0.01, 158, 26, 33, 255.0)
                    DrawRect(0.92+(respawnBarProgress/2), 0.86, 0.05-respawnBarProgress, 0.01, 78, 33, 33, 255.0)
                end
            else
                respawnBarProgress = 0
            end
            if IsPedInAnyVehicle(PlayerPedId()) then
                if checkpointBlip then
                    if checkpoints[currentCheckpointIndex].NextPosition or gameInfo.Players[GetPlayerServerId(PlayerId())].CurrentLap < gameInfo.NumLaps then
                        SetBlipSprite(checkpointBlip, 1)
                        SetBlipColour(checkpointBlip, 5)
                    else
                        SetBlipSprite(checkpointBlip, 38)
                    end
                else
                    checkpointBlip = AddBlipForCoord(checkpoints[currentCheckpointIndex].Position.xyz)
                end
                if GetDistanceBetweenCoords(checkpoints[currentCheckpointIndex].Position, GetEntityCoords(PlayerPedId())) <= (5/2)+6 then -- Entered checkpoint
                    currentCheckpointIndex = currentCheckpointIndex+1
                    TriggerServerEvent("DalraeEvent:PassedCheckpoint")
                    if checkpoints[currentCheckpointIndex] then -- Passed a checkpoint
                        RemoveBlip(checkpointBlip)
                        checkpointBlip = AddBlipForCoord(checkpoints[currentCheckpointIndex].Position.xyz)
                        PlaySoundFrontend(-1, "Checkpoint", "DLC_AW_Frontend_Sounds")
                        enteredCheckpoint(checkpoint)
                        if checkpoints[currentCheckpointIndex].NextPosition then
                            checkpoint = CreateCheckpoint(0, checkpoints[currentCheckpointIndex].Position.xyz, checkpoints[currentCheckpointIndex].NextPosition.xyz, 10.0, 247, 198, 104, 100, 100)
                            SetCheckpointRgba2(checkpoint, cIR, cIG, cIB, cIA)
                            SetCheckpointScale(checkpoint, 0.4)
                            SetCheckpointCylinderHeight(checkpoint, 5.0, 5.0, 10.0)
                        elseif gameInfo.Players[GetPlayerServerId(PlayerId())].CurrentLap == gameInfo.NumLaps then
                            checkpoint = CreateCheckpoint(4, checkpoints[currentCheckpointIndex].Position.xyz, checkpoints[currentCheckpointIndex].Position.xyz, 10.0, 247, 198, 104, 100, 100)
                            SetCheckpointRgba2(checkpoint, cIR, cIG, cIB, cIA)
                            SetCheckpointScale(checkpoint, 0.4)
                            SetCheckpointCylinderHeight(checkpoint, 5.0, 5.0, 10.0)
                        else
                            checkpoint = CreateCheckpoint(0, checkpoints[currentCheckpointIndex].Position.xyz, checkpoints[2].Position.xyz, 10.0, 247, 198, 104, 100, 100)
                            SetCheckpointRgba2(checkpoint, cIR, cIG, cIB, cIA)
                            SetCheckpointScale(checkpoint, 0.4)
                            SetCheckpointCylinderHeight(checkpoint, 5.0, 5.0, 10.0)
                        end
                    elseif gameInfo.Players[GetPlayerServerId(PlayerId())].CurrentLap == gameInfo.NumLaps then-- Passed the last checkpoint
                        if not gameInfo.GameWon then
                            PlaySoundFrontend(-1, "Finish_Win", "DLC_AW_Frontend_Sounds")
                        end
                        TriggerServerEvent("DalraeEvent:Win")
                        enteredCheckpoint(checkpoint)
                        RemoveBlip(checkpointBlip)
                        break
                    else
                        enteredCheckpoint(checkpoint)
                        lastLapStartTime = GetGameTimer()
                        gameInfo.Players[GetPlayerServerId(PlayerId())].CurrentLap = gameInfo.Players[GetPlayerServerId(PlayerId())].CurrentLap+1
                        CreateThread(function()
                            Wait(500)
                            PlaySoundFrontend(-1, "CHECKPOINT_NORMAL", "HUD_MINI_GAME_SOUNDSET")
                            showBigRaceMessage(("Lap %s/%s"):format(gameInfo.Players[GetPlayerServerId(PlayerId())].CurrentLap, gameInfo.NumLaps))
                        end)
                        currentCheckpointIndex = 1
                    end
                end
            else
                if DoesEntityExist(myVehicle) and GetEntityHealth(myVehicle) > 200 and GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), GetEntityCoords(myVehicle)) < 30 then
                    showBigRaceMessage("~r~Get back in your vehicle!", "", 1)
                else
                    respawnVehicle()
                end
            end
        end
    end) 
end
function createScaleform(scaleformName)
    local scaleform = RequestScaleformMovie(scaleformName)
    while not HasScaleformMovieLoaded(scaleform) do
        Citizen.Wait(0)
    end
    local scaleformTable = {}
    t1 = {
        __index = function(_, indexed)
            return function(_, ...)
                local args = {...}
                local expectingReturn = args[1]
                table.remove(args, 1)
                BeginScaleformMovieMethod(scaleform, indexed)
                for i,v in pairs(args) do
                    if type(v) == "string" then
                        ScaleformMovieMethodAddParamTextureNameString(v)
                    elseif type(v) == "number" then
                        if math.type(v) == "float" then
                            ScaleformMovieMethodAddParamFloat(v)
                        else
                            ScaleformMovieMethodAddParamInt(v)
                        end
                    elseif type(v) == "boolean" then
                        ScaleformMovieMethodAddParamBool(v)
                    end
                end
                local value = EndScaleformMovieMethodReturn()
                if expectingReturn then
                    while not IsScaleformMovieMethodReturnValueReady(value) do
                        Wait(0)
                    end
                    local returnString = GetScaleformMovieMethodReturnValueString(value)
                    local returnInt = GetScaleformMovieMethodReturnValueInt(value)
                    local returnBool = GetScaleformMovieMethodReturnValueBool(value)
                    EndScaleformMovieMethod()
                    if returnString ~= "" then
                        return returnString
                    end
                    if returnInt ~= 0 and not returnBool then
                        return returnInt
                    end
                    return returnBool
                end
            end
        end,
        __call = function(called, ms, r, g, b, a)
            local startScaleformTimer = GetGameTimer()
            CreateThread(function()
                repeat
                    Citizen.Wait(0)
                    DrawScaleformMovieFullscreen(scaleform, r or 255, g or 255, b or 255, a or 255)
                until GetGameTimer()-startScaleformTimer >= (ms or math.floor(2000*tick))
            end)
        end
    }
    setmetatable(scaleformTable, t1)
    return scaleformTable
end

function showRaceCountdown(time)
    local scaleform = createScaleform("COUNTDOWN")
    if time == 0 then
        scaleform:SET_MESSAGE(false, "GO")
    else
        scaleform:SET_MESSAGE(false, time)
    end
    scaleform(math.floor(1000*tick))
end

function showBigRaceMessage(bigMessage, smallMessage, ms)
    local scaleform = createScaleform("mp_big_message_freemode")
    scaleform:SHOW_SHARD_WASTED_MP_MESSAGE(false, bigMessage or "", smallMessage or "")
    scaleform(ms or math.floor(2000*tick))
end

if IsPedInAnyVehicle(PlayerPedId()) then
    DeleteEntity(GetVehiclePedIsIn(PlayerPedId()), true)
end
local isMovingCamera = true
CreateThread(function()
    --PlaySoundFrontend(-1, "Creator_Snap", "DLC_Stunt_Race_Frontend_Sounds")
    repeat Wait(0) until gameInfo.Checkpoints
    local vehicle = makeVehicle("neon", gameInfo.Players[GetPlayerServerId(PlayerId())].SpawnPosition.xyz, gameInfo.DefaultSpawn.Heading)
    myVehicle = vehicle
    CreateThread(function()
        while isMovingCamera do
            Wait(0)
            DisableControlAction(0,1,true)
            DisableControlAction(0,2,true)
        end
    end)
    
    SetPedIntoVehicle(PlayerPedId(), vehicle, -1)
    SetVehicleEngineOn(myVehicle, true, true)
    FreezeEntityPosition(vehicle, true)
    local forwardVector, rightVector, upVector, position = GetEntityMatrix(vehicle)
    local forwardCoords, rightCoords, upCoords = forwardVector*5, rightVector*3, upVector*2
    local cam1 = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", (GetEntityCoords(vehicle)+forwardCoords+rightCoords+upCoords).xyz, (GetEntityRotation(vehicle)+vector3(-20,0,-210)).xyz, GetGameplayCamFov() * 1.0)
    SetCamAffectsAiming(cam1, false)
    local forwardCoords, rightCoords, upCoords = forwardVector*3, rightVector*-1.5, upVector*0.5
    local cam2 = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", (GetEntityCoords(vehicle)+forwardCoords+rightCoords+upCoords).xyz, (GetEntityRotation(vehicle)+vector3(-20,0,-150)).xyz, GetGameplayCamFov() * 1.0)
    SetCamAffectsAiming(cam2, false)
    local forwardCoords, rightCoords, upCoords = forwardVector*0, rightVector*-2, upVector*0
    local cam3 = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", (GetEntityCoords(vehicle)+forwardCoords+rightCoords+upCoords).xyz, (GetEntityRotation(vehicle)+vector3(0,0,-100)).xyz, GetGameplayCamFov() * 1.0)
    SetCamAffectsAiming(cam3, false)
    SetCamActiveWithInterp(cam2, cam1, math.floor(3700*tick))
    RenderScriptCams(true, false, 0, true, false)
    Wait(math.floor(3700*tick))
    SetCamActive(cam3, true)
    RenderScriptCams(true, false, 0, true, false)
    SetGameplayCamRelativeRotation(GetEntityRotation(vehicle).xyz)
    SetGameplayCamRelativePitch(-10.0, 1.0)
    RenderScriptCams(false, true, math.floor(5000*tick), false, false)
    Wait(math.floor(5000*tick))
    isMovingCamera = false
    local lastSecond = GetGameTimer()
    local secondsElapsed = 3
    while secondsElapsed >= 0 do
        Wait(0)
        local dif = GetGameTimer()-lastSecond
        if dif > math.floor(1000*tick) then
            if secondsElapsed >= 1 then
                if secondsElapsed == 1 then
                    PlaySoundFrontend(-1, "Countdown_GO", "DLC_AW_Frontend_Sounds", true)
                    CreateThread(function()
                        Wait(1000)
                        local startedCheckingRaceBoost = GetGameTimer()
                        while true do
                            if IsControlJustPressed(0, 71) then
                                NitroBoost()
                                break
                            end
                            if GetGameTimer()-startedCheckingRaceBoost > 100*tick then
                                break
                            end
                            Wait(0)
                        end
                    end)
                end
                PlaySoundFrontend(-1, "Countdown_3", "DLC_AW_Frontend_Sounds", false)
            end
            lastSecond = GetGameTimer()
            showRaceCountdown(secondsElapsed)
            secondsElapsed = secondsElapsed-1
        end
    end
    
    local raceStartTime = GetGameTimer()
    lastLapStartTime = GetGameTimer()
    LoadRace(gameInfo.Checkpoints)
    FreezeEntityPosition(vehicle, false)
    while true do
        Wait(0)
        DrawTxt(0.9, 0.65, formatOrdinally(gameInfo.Players[GetPlayerServerId(PlayerId())].Place), true, 4.0)
        DrawTxt(0.87, 0.87, "CURRENT LAP", true, 0.5)
        DrawTxt(0.93, 0.87, formatTime(GetGameTimer()-lastLapStartTime), true, 0.5)
        DrawTxt(0.87, 0.9, "TIME", true, 0.5)
        DrawTxt(0.93, 0.9, formatTime(GetGameTimer()-raceStartTime), true, 0.5)

        if GetGameTimer()-raceStartTime > math.floor(2000*tick) and not shownFirstLapMessage then
            shownFirstLapMessage = true
            PlaySoundFrontend(-1, "CHECKPOINT_NORMAL", "HUD_MINI_GAME_SOUNDSET")
            showBigRaceMessage(("Lap %s/%s"):format(gameInfo.Players[GetPlayerServerId(PlayerId())].CurrentLap, gameInfo.NumLaps))
        end
    end
end)--]]
