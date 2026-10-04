local QBCore = exports['qb-core']:GetCoreObject()

local function notify(src, msg, kind)
    TriggerClientEvent('QBCore:Notify', src, msg, kind or 'error')
end

local function inList(list, value)
    for _, v in ipairs(list) do
        if v == value then return true end
    end
    return false
end

RegisterNetEvent('county-idnpc:server:issue', function(form)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or type(form) ~= 'table' then return end

    -- must be standing at the desk (the event can be triggered by a modified client)
    local pc = Config.Ped.coords
    if #(GetEntityCoords(GetPlayerPed(src)) - vector3(pc.x, pc.y, pc.z)) > Config.UseDistance + 3.0 then return end

    if QBCore.Functions.HasItem(src, 'id_card', 1) then
        return notify(src, 'Zaten bir kimlik kartın var.', 'error')
    end

    -- validate the answers
    local height = tonumber(form.height)
    local address = type(form.address) == 'string' and form.address:gsub('[%c]', ''):match('^%s*(.-)%s*$') or ''
    if not height or height < Config.MinHeight or height > Config.MaxHeight then
        return notify(src, ('Boy %d-%d cm arasında olmalı.'):format(Config.MinHeight, Config.MaxHeight), 'error')
    end
    if not inList(Config.EyeColors, form.eye) or not inList(Config.HairColors, form.hair) then
        return notify(src, 'Formda geçersiz bir seçim var.', 'error')
    end
    if address == '' or #address > Config.MaxAddressLength then
        return notify(src, ('Adres 1-%d karakter olmalı.'):format(Config.MaxAddressLength), 'error')
    end

    -- fee: cash first, then bank
    local fee = Config.Fee
    local paidWith
    if fee > 0 then
        if Player.PlayerData.money.cash >= fee then
            paidWith = 'cash'
        elseif Player.PlayerData.money.bank >= fee then
            paidWith = 'bank'
        else
            return notify(src, ('Kimlik ücreti için yeterli paran yok (%s$).'):format(fee), 'error')
        end
        Player.Functions.RemoveMoney(paidWith, fee, 'id-card-fee')
    end

    local info = {
        height = math.floor(height),
        eyecolor = form.eye,
        haircolor = form.hair,
        address = address,
        issued = os.date('%d.%m.%Y'),
        issuedby = 'MRPD',
    }

    if Player.Functions.AddItem('id_card', 1, false, info) then
        notify(src, 'Kimlik kartın hazırlandı. İyi günler.', 'success')
    else
        if paidWith then Player.Functions.AddMoney(paidWith, fee, 'id-card-refund') end
        notify(src, 'Envanterinde yer yok, ücret iade edildi.', 'error')
    end
end)
