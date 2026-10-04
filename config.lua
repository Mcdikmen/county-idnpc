Config = {}

Config.Ped = {
    model = 's_f_y_cop_01',
    coords = vector4(442.7896, -981.7935, 30.6895, 82.4108), -- MRPD front desk
    scenario = 'WORLD_HUMAN_CLIPBOARD',
}

Config.Fee = 100               -- paid in cash, falls back to bank. 0 = free
Config.SpawnDistance = 60.0    -- the ped exists only while a player is this close (interior streaming)
Config.UseDistance = 4.0       -- server-side check when the form is submitted

Config.MinHeight = 140
Config.MaxHeight = 215
Config.MaxAddressLength = 60

Config.EyeColors = { 'Kahverengi', 'Siyah', 'Mavi', 'Yeşil', 'Ela', 'Gri' }
Config.HairColors = { 'Siyah', 'Kahverengi', 'Sarı', 'Kızıl', 'Gri', 'Beyaz', 'Kel' }
