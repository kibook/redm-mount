local CurrentMount = 0

function GetLastMount(ped)
	return Citizen.InvokeNative(0x4C8B59171957BCF7, ped)
end

function BlipAddForEntity(blipHash, entity)
	return Citizen.InvokeNative(0x23F74C2FDA6E7C61, blipHash, entity)
end

function SetPedAsSaddleHorseForPlayer(player, mount)
	return Citizen.InvokeNative(0xD2CB0FB0FDCB473D, player, mount)
end

function SetEntityCoordsAndHeading(entity, xPos, yPos, zPos, heading, xAxis, yAxis, zAxis)
	return Citizen.InvokeNative(0x203BEFFDBE12E96A, entity, xPos, yPos, zPos, heading, xAxis, yAxis, zAxis)
end

function GetRiderOfMount(mount, p1)
	return Citizen.InvokeNative(0xB676EFDA03DADA52, mount, p1)
end

function RestorePedStamina(ped, stamina)
	return Citizen.InvokeNative(0x675680D089BFA21F, ped, stamina)
end

function SetAttributeCoreValue(ped, coreIndex, value)
	return Citizen.InvokeNative(0xC6258F41D86676E0, ped, coreIndex, value)
end

function GetSaddleHorseForPlayer(player)
	return Citizen.InvokeNative(0xB48050D326E9A2F3, player)
end

function RequestControl(entity)
	NetworkRequestControlOfEntity(entity)
end

function Whistle()
	local playerPed = PlayerPedId()
	local playerCoords = GetEntityCoords(playerPed)
	local mountCoords = GetEntityCoords(CurrentMount)
	local distance = #(playerCoords - mountCoords)

	RequestControl(CurrentMount)

	if distance > Config.MaxWhistleDistance then
		local h = GetEntityHeading(playerPed)
		local r = math.rad(-h)
		local x = playerCoords.x + 5 * math.sin(r)
		local y = playerCoords.y + 5 * math.cos(r)
		local z = playerCoords.z

		SetEntityCoordsAndHeading(CurrentMount, x, y, z, h + 180)
	else
		ClearPedTasks(CurrentMount)
		TaskGoToEntity(CurrentMount, playerPed, -1, 2.5, 1.5, 0, 0)
		SetPedKeepTask(CurrentMount, true)
	end
end

function Revive()
	local playerPed = PlayerPedId()

	if IsPedFatallyInjured(CurrentMount) and IsMountNearby(playerPed, CurrentMount) then
		RequestControl(CurrentMount)

		TaskReviveTarget(playerPed, CurrentMount)
	end
end

function Brush()
	local playerPed = PlayerPedId()

	if IsMountNearby(playerPed, CurrentMount) then
		RequestControl(CurrentMount)

		TaskAnimalInteraction(playerPed, CurrentMount, 554992710, `P_BRUSHHORSE02X`, 0)

		SetTimeout(5000, function()
			ClearPedEnvDirt(CurrentMount)
			ClearPedDamageDecalByZone(CurrentMount, 10, "ALL")
			ClearPedBloodDamage(CurrentMount)
		end)
	end
end

function Feed()
	local playerPed = PlayerPedId()

	if IsMountNearby(playerPed, CurrentMount) then
		RequestControl(CurrentMount)

		TaskAnimalInteraction(playerPed, CurrentMount, -224471938, 0, 0)

		SetTimeout(2000, function()
			SetAttributeCoreValue(CurrentMount, 0, 100)
			SetAttributeCoreValue(CurrentMount, 1, 100)
			SetEntityHealth(CurrentMount, 100, 0)
			RestorePedStamina(CurrentMount, 100.0)
		end)
	end
end

function IsMountNearby(ped, mount)
	return #(GetEntityCoords(ped) - GetEntityCoords(mount)) < Config.MaxInteractionDistance
end

function GetCurrentMount(playerId, playerPed)
	local mount = GetSaddleHorseForPlayer(playerId)

	if mount then
		return mount
	end

	mount = GetLastMount(playerPed)

	if GetRiderOfMount(mount, true) == playerPed then
		return mount
	end

	return nil
end

CreateThread(function()
	while true do
		if CurrentMount ~= 0 and (not DoesEntityExist(CurrentMount) or IsPedDeadOrDying(CurrentMount)) then
			CurrentMount = 0
		end

		local playerId = PlayerId()
		local playerPed = PlayerPedId()
		local mount = GetCurrentMount(playerId, playerPed)

		if mount and mount ~= CurrentMount then
			SetPedAsSaddleHorseForPlayer(playerId, mount)

			SetPedConfigFlag(mount, 297, true) -- Enable leading
			SetPedConfigFlag(mount, 312, true) -- Horse won"t flee when shooting
			SetPedConfigFlag(mount, 442, true) -- Remove Flee prompt

			RemoveBlip(GetBlipFromEntity(mount))
			BlipAddForEntity(Config.HorseBlipSprite, mount)

			CurrentMount = mount
		end

		Wait(500)
	end
end)

CreateThread(function()
	while true do
		if CurrentMount ~= 0 then
			if IsControlJustPressed(0, `INPUT_WHISTLE`) then
				Whistle()
			end

			if IsDisabledControlJustPressed(0, `INPUT_REVIVE`) then
				Revive()
			end

			if IsDisabledControlJustPressed(0, `INPUT_INTERACT_HORSE_BRUSH`) then
				Brush()
			end

			if IsDisabledControlJustPressed(0, `INPUT_INTERACT_HORSE_FEED`) then
				Feed()
			end
		end

		Wait(0)
	end
end)
