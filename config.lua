Config = {}

Config.Ped = {
    model = 's_f_y_cop_01',
    coords = vector4(442.7896, -981.7935, 30.6895, 82.4108), -- MRPD front desk
    scenario = 'WORLD_HUMAN_CLIPBOARD',
}

Config.FirstFee = 100          -- first ID card (cash first, then bank)
Config.RenewFee = 1000         -- replacement for a lost card
Config.SpawnDistance = 60.0    -- the ped exists only while a player is this close (interior streaming)
Config.UseDistance = 4.0       -- server-side check when the request is sent
