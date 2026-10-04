local npc = nil
local pedCoords = Config.Ped.coords

local function optionList(list)
    local options = {}
    for _, name in ipairs(list) do
        options[#options + 1] = { value = name, text = name }
    end
    return options
end

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
                label = 'Kimlik Başvurusu',
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

RegisterNetEvent('county-idnpc:client:menu', function()
    local fee = Config.Fee > 0 and ('Ücret: %s$'):format(Config.Fee) or 'Ücretsiz'
    exports['qb-menu']:openMenu({
        { header = 'Polis Kimlik Bürosu', isMenuHeader = true },
        {
            header = 'Kimlik başvurusu yap',
            txt = fee .. ' | Kimliğin yoksa yeni kart çıkarılır',
            params = { event = 'county-idnpc:client:apply' },
        },
        { header = 'Kapat', params = { event = 'qb-menu:client:closeMenu' } },
    })
end)

RegisterNetEvent('county-idnpc:client:apply', function()
    local form = exports['qb-input']:ShowInput({
        header = 'Kimlik Başvuru Formu',
        submitText = 'Başvur',
        inputs = {
            { type = 'number', isRequired = true, name = 'height', text = ('Boy (cm, %d-%d)'):format(Config.MinHeight, Config.MaxHeight) },
            { type = 'select', isRequired = true, name = 'eye', text = 'Göz rengi', options = optionList(Config.EyeColors) },
            { type = 'select', isRequired = true, name = 'hair', text = 'Saç rengi', options = optionList(Config.HairColors) },
            { type = 'text', isRequired = true, name = 'address', text = 'İkametgah adresi' },
        },
    })
    if form then
        TriggerServerEvent('county-idnpc:server:issue', form)
    end
end)
