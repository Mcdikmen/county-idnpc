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

-- kind: 'first' (first ID card) or 'renew' (replacement for a lost or confiscated card)
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
        return notify(src, 'Daha önce kimlik çıkarılmış. Kimliğin kaybolduysa ya da el konulduysa "Kimlik yenileme" başvurusu yap.', 'error')
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
    local row = exports.oxmysql:singleSync('SELECT id FROM players WHERE citizenid = ?', { ply.PlayerData.citizenid })
    local info = {
        idnumber = row and row.id or nil,
        issued = os.date('%d.%m.%Y'),
        issuedby = 'MRPD',
        reissue = kind == 'renew' or nil,
    }

    if ply.Functions.AddItem('id_card', 1, false, info) then
        ply.Functions.SetMetaData('idissued', issued + 1)
        notify(src, kind == 'first' and 'Kimlik kartın hazırlandı. İyi günler.' or 'Yeni kimlik kartın hazırlandı. Kimliğini dikkatli taşı.', 'success')
    else
        if paidWith then ply.Functions.AddMoney(paidWith, fee, 'id-card-refund') end
        notify(src, 'Envanterinde yer yok, ücret iade edildi.', 'error')
    end
end)

-- /kimlikelkoy [id]: police seize the ID card of a nearby player. The card is removed from the
-- target's inventory and appears in the officer's inventory with its ORIGINAL owner data
-- (codem-inventory overwrites id_card info with the receiver's data, then merges the info we pass).
QBCore.Commands.Add('kimlikelkoy', 'Yakındaki oyuncunun kimliğine el koy (sadece polis)', {
    { name = 'id', help = 'Oyuncu ID (geçici ID)' },
}, true, function(source, args)
    local src = source
    local officer = QBCore.Functions.GetPlayer(src)
    if not officer then return end

    if officer.PlayerData.job.type ~= 'leo' or not officer.PlayerData.job.onduty then
        return notify(src, 'Bu komutu sadece görevdeki polis kullanabilir.', 'error')
    end

    local targetSrc = tonumber(args[1])
    if not targetSrc or targetSrc == src then
        return notify(src, 'Geçerli bir oyuncu ID gir (kendine kullanamazsın).', 'error')
    end
    local target = QBCore.Functions.GetPlayer(targetSrc)
    if not target then
        return notify(src, 'Bu ID ile oyuncu bulunamadı.', 'error')
    end

    local distance = #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(targetSrc)))
    if distance > Config.SeizeDistance then
        return notify(src, 'Oyuncu yeterince yakın değil.', 'error')
    end

    local card = exports['codem-inventory']:GetItemByName(targetSrc, 'id_card')
    if not card then
        return notify(src, 'Bu oyuncunun üzerinde kimlik kartı yok.', 'error')
    end

    -- copy the card data, then give it to the officer first (fails if the inventory is full)
    local info = {}
    for k, v in pairs(card.info or {}) do info[k] = v end
    if not exports['codem-inventory']:AddItem(src, 'id_card', 1, false, info) then
        return notify(src, 'Envanterinde yer yok, kimliğe el koyulamadı.', 'error')
    end
    if not exports['codem-inventory']:RemoveItem(targetSrc, 'id_card', 1, card.slot) then
        print(('[county-idnpc] WARNING: card was given to officer %s but could not be removed from %s'):format(src, targetSrc))
    end

    local name = ('%s %s'):format(info.firstname or target.PlayerData.charinfo.firstname, info.lastname or target.PlayerData.charinfo.lastname)
    notify(src, ('%s adlı kişinin kimliğine el koydun.'):format(name), 'success')
    notify(targetSrc, 'Kimlik kartına polis tarafından el konuldu.', 'error')
end)
