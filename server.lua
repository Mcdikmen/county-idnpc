local QBCore = exports['qb-core']:GetCoreObject()

local function notify(src, msg, kind)
    TriggerClientEvent('QBCore:Notify', src, msg, kind or 'error')
end

local function money(amount)
    local s = tostring(amount)
    while true do
        local replaced
        s, replaced = s:gsub('^(-?%d+)(%d%d%d)', '%1.%2')
        if replaced == 0 then break end
    end
    return s
end

-- kind: 'first' (first ID card) or 'renew' (replacement for a lost card)
RegisterNetEvent('county-idnpc:server:issue', function(kind)
    local src = source
    local ply = QBCore.Functions.GetPlayer(src)
    if not ply or (kind ~= 'first' and kind ~= 'renew') then return end

    -- must be standing at the desk (the event can be triggered by a modified client)
    local pc = Config.Ped.coords
    if #(GetEntityCoords(GetPlayerPed(src)) - vector3(pc.x, pc.y, pc.z)) > Config.UseDistance + 3.0 then return end

    if QBCore.Functions.HasItem(src, 'id_card', 1) then
        return notify(src, 'Zaten bir kimlik kartın var.', 'error')
    end

    -- how many cards were issued before (stored in the character metadata, no extra table needed)
    local issued = tonumber(ply.PlayerData.metadata['idissued']) or 0
    if kind == 'first' and issued > 0 then
        return notify(src, 'Daha önce kimlik çıkarılmış. Kaybettiysen "Kayıp kimlik yenileme" başvurusu yap.', 'error')
    end
    if kind == 'renew' and issued == 0 then
        return notify(src, 'Daha önce kimlik çıkarılmamış. "İlk kimlik başvurusu" yap.', 'error')
    end

    -- fee: cash first, then bank
    local fee = kind == 'first' and Config.FirstFee or Config.RenewFee
    local paidWith
    if fee > 0 then
        if ply.PlayerData.money.cash >= fee then
            paidWith = 'cash'
        elseif ply.PlayerData.money.bank >= fee then
            paidWith = 'bank'
        else
            return notify(src, ('Yeterli paran yok (%s$).'):format(money(fee)), 'error')
        end
        ply.Functions.RemoveMoney(paidWith, fee, 'id-card-fee')
    end

    -- ID number = permanent character ID (players.id); name/birthdate/gender/nationality are added by codem-inventory
    local row = MySQL.single.await('SELECT id FROM players WHERE citizenid = ?', { ply.PlayerData.citizenid })
    local info = {
        idnumber = row and row.id or nil,
        issued = os.date('%d.%m.%Y'),
        issuedby = 'MRPD',
        reissue = kind == 'renew' or nil,
    }

    if ply.Functions.AddItem('id_card', 1, false, info) then
        ply.Functions.SetMetaData('idissued', issued + 1)
        notify(src, kind == 'first' and 'Kimlik kartın hazırlandı. İyi günler.' or 'Yeni kimlik kartın hazırlandı. Bir daha kaybetme.', 'success')
    else
        if paidWith then ply.Functions.AddMoney(paidWith, fee, 'id-card-refund') end
        notify(src, 'Envanterinde yer yok, ücret iade edildi.', 'error')
    end
end)
