local npc = nil
local pedCoords = Config.Ped.coords

local function removeNpc()
    if npc and DoesEntityExist(npc) then
        exports['qb-target']:RemoveTargetEntity(npc)
        DeleteEntity(npc)
    end
    npc = nil
end

local function spawnNpc()
    local model = joaat(Config.Ped.model)
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 100 do
        Wait(50)
        timeout = timeout + 1
    end
    if not HasModelLoaded(model) then return end

    npc = CreatePed(4, model, pedCoords.x, pedCoords.y, pedCoords.z - 1.0, pedCoords.w, false, false)
    SetEntityHeading(npc, pedCoords.w)
    FreezeEntityPosition(npc, true)
    SetEntityInvincible(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    SetPedFleeAttributes(npc, 0, false)
    SetPedCanRagdoll(npc, false)
    if Config.Ped.scenario then
        TaskStartScenarioInPlace(npc, Config.Ped.scenario, 0, true)
    end
    SetModelAsNoLongerNeeded(model)

    exports['qb-target']:AddTargetEntity(npc, {
        options = {
            {
                type = 'client',
                event = 'county-idnpc:client:menu',
                icon = 'fas fa-id-card',
                label = 'Kimlik İşlemleri',
            },
        },
        distance = 2.5,
    })
end

CreateThread(function()
    while true do
        local dist = #(GetEntityCoords(PlayerPedId()) - vector3(pedCoords.x, pedCoords.y, pedCoords.z))
        if dist < Config.SpawnDistance and not npc then
            spawnNpc()
        elseif dist > Config.SpawnDistance + 20.0 and npc then
            removeNpc()
        end
        Wait(1500)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then removeNpc() end
end)

-- qb-target forgets every registered target when it restarts; respawn the NPC so the target is re-added
AddEventHandler('onResourceStart', function(resource)
    if resource == 'qb-target' then removeNpc() end
end)

local function money(amount)
    -- 1000 -> "1.000"
    local s = tostring(amount)
    while true do
        local replaced
        s, replaced = s:gsub('^(-?%d+)(%d%d%d)', '%1.%2')
        if replaced == 0 then break end
    end
    return s
end

RegisterNetEvent('county-idnpc:client:menu', function()
    exports['qb-menu']:openMenu({
        { header = 'Polis Kimlik Bürosu', isMenuHeader = true },
        {
            header = 'İlk kimlik başvurusu',
            txt = ('Ücret: %s$ | Daha önce kimlik çıkarmadıysan'):format(money(Config.FirstFee)),
            params = { event = 'county-idnpc:client:request', args = 'first' },
        },
        {
            header = 'Kimlik yenileme',
            txt = ('Ücret: %s$ | Kimliğin kaybolduysa ya da el konulduysa'):format(money(Config.RenewFee)),
            params = { event = 'county-idnpc:client:request', args = 'renew' },
        },
        { header = 'Kapat', params = { event = 'qb-menu:client:closeMenu' } },
    })
end)

RegisterNetEvent('county-idnpc:client:request', function(kind)
    TriggerServerEvent('county-idnpc:server:issue', kind)
end)
