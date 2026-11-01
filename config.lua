Config = {}

-- App i lb-phone
Config.App = {
    identifier = "luudi_korekort",
    name = "Kørekort",
    description = "Dit digitale kørekort",
    defaultApp = true, -- true = appen er installeret på alle telefoner fra start
}

-- Tekst på kortet
Config.Issuer = "Los Santos Politi"
Config.CountryCode = "DK"

-- Job der tæller som politi (kan modtage kørekort og ser fanen "Modtaget")
Config.PoliceJobs = {
    police = true,
}

-- Kategorier. "license" er navnet i esx_license (user_licenses.type)
-- icon: car, bike, truck
Config.Categories = {
    { license = "drive",       code = "B", label = "Personbil",   icon = "car" },
    { license = "drive_bike",  code = "A", label = "Motorcykel",  icon = "bike" },
    { license = "drive_truck", code = "C", label = "Lastbil",     icon = "truck" },
}

-- Klip hentes fra p_policejob's pointsystem (bøder giver point)
Config.Points = {
    enabled = true,
    resource = "p_policejob",
    -- SKAL matche Config.Tickets.points.suspendThreshold i p_policejob/modules/tickets/config.lua
    threshold = 12,
}

-- Deling
Config.SendDistance = 5.0      -- "Send bevis til nærmeste politi" (meter)
Config.AirShareDistance = 10.0 -- AirShare liste (meter)
Config.AirShareTimeout = 20    -- sekunder betjenten har til at acceptere
Config.Cooldown = 5            -- sekunder mellem delinger pr. spiller
Config.MaxReceived = 5         -- antal modtagne kort en betjent gemmer (ryddes ved relog)

-- Fødselsdato format fra esx_identity, kun relevant hvis datoen står som 01/02/1999
-- "DMY" = dag/måned/år (dansk), "MDY" = måned/dag/år (amerikansk)
Config.DobFormat = "DMY"
