local ESX = exports["es_extended"]:getSharedObject()

local cooldowns = {}

-- ─── Database ───────────────────────────────────────────────────────────────

MySQL.ready(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `luudi_korekort` (
            `identifier` VARCHAR(60) NOT NULL,
            `card_number` VARCHAR(8) NOT NULL,
            `issued_at` INT NOT NULL,
            `active` TINYINT NOT NULL DEFAULT 1,
            PRIMARY KEY (`identifier`),
            UNIQUE KEY `card_number` (`card_number`)
        )
    ]])
end)

-- ─── Hjælpere ───────────────────────────────────────────────────────────────

local function isPolice(xPlayer)
    return xPlayer and xPlayer.job and Config.PoliceJobs[xPlayer.job.name] == true
end

local function isActive(value)
    return value == true or value == 1 or value == "1"
end

local function getCategories(identifier)
    local ok, rows = pcall(function()
        return MySQL.query.await("SELECT `type` FROM `user_licenses` WHERE `owner` = ?", { identifier })
    end)

    if not ok then
        print("^1[luudi_korekortapp] Kunne ikke læse user_licenses. Er esx_license installeret?^0")
        rows = {}
    end

    local owned = {}
    for _, row in ipairs(rows or {}) do
        owned[row.type] = true
    end

    local categories = {}
    for _, cat in ipairs(Config.Categories) do
        if owned[cat.license] then
            categories[#categories + 1] = { code = cat.code, label = cat.label, icon = cat.icon }
        end
    end

    return categories
end

local function generateCardNumber()
    for _ = 1, 25 do
        local number = tostring(math.random(10000000, 99999999))
        local exists = MySQL.scalar.await("SELECT 1 FROM `luudi_korekort` WHERE `card_number` = ?", { number })
        if not exists then return number end
    end
end

-- Holder kortnummer og udstedelsesdato i sync med om spilleren har et kørekort
local function syncRecord(identifier, hasLicense)
    local row = MySQL.single.await("SELECT * FROM `luudi_korekort` WHERE `identifier` = ?", { identifier })
    local now = os.time()

    if not row then
        if not hasLicense then return nil end

        local number = generateCardNumber()
        if not number then return nil end

        MySQL.insert.await(
            "INSERT INTO `luudi_korekort` (`identifier`, `card_number`, `issued_at`, `active`) VALUES (?, ?, ?, 1)",
            { identifier, number, now }
        )
        return { card_number = number, issued_at = now, active = true }
    end

    local active = isActive(row.active)

    if hasLicense and not active then
        -- Nyt kørekort efter frakendelse: ny udstedelsesdato
        MySQL.update.await("UPDATE `luudi_korekort` SET `issued_at` = ?, `active` = 1 WHERE `identifier` = ?", { now, identifier })
        row.issued_at = now
        active = true
    elseif not hasLicense and active then
        MySQL.update.await("UPDATE `luudi_korekort` SET `active` = 0 WHERE `identifier` = ?", { identifier })
        active = false
    end

    row.active = active
    return row
end

local function getIdentity(xPlayer)
    local first = xPlayer.get and xPlayer.get("firstName")
    local last = xPlayer.get and xPlayer.get("lastName")
    local dob = xPlayer.get and xPlayer.get("dateofbirth")

    if not first or not last or not dob then
        local row = MySQL.single.await("SELECT `firstname`, `lastname`, `dateofbirth` FROM `users` WHERE `identifier` = ?", { xPlayer.identifier })
        if row then
            first = first or row.firstname
            last = last or row.lastname
            dob = dob or row.dateofbirth
        end
    end

    return first or "", last or "", dob
end

local function parseDob(value)
    if type(value) ~= "string" then return nil end

    local y, m, d = value:match("^(%d%d%d%d)[-/.](%d%d?)[-/.](%d%d?)")
    if not y then
        d, m, y = value:match("^(%d%d?)[-/.](%d%d?)[-/.](%d%d%d%d)")
        if d and Config.DobFormat == "MDY" then d, m = m, d end
    end
    if not y then return nil end

    y, m, d = tonumber(y), tonumber(m), tonumber(d)
    if m > 12 and d <= 12 then m, d = d, m end
    return y, m, d
end

local function calcAge(y, m, d)
    local now = os.date("*t")
    local age = now.year - y
    if now.month < m or (now.month == m and now.day < d) then age = age - 1 end
    return age
end

local function getPoints(identifier)
    if not Config.Points.enabled then return nil end
    if GetResourceState(Config.Points.resource) ~= "started" then return nil end

    local ok, points = pcall(function()
        return exports[Config.Points.resource]:getLicensePoints(identifier)
    end)

    if ok and tonumber(points) then return tonumber(points) end
    return nil
end

local function buildCard(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return nil end

    local categories = getCategories(xPlayer.identifier)
    local hasLicense = #categories > 0
    local record = syncRecord(xPlayer.identifier, hasLicense)
    local first, last, dob = getIdentity(xPlayer)
    local y, m, d = parseDob(dob)

    local status = "none"
    if hasLicense then
        status = "valid"
    elseif record then
        status = "revoked"
    end

    return {
        status = status,
        firstName = first,
        lastName = last,
        dob = y and ("%02d. %02d. %d"):format(d, m, y) or (dob or "Ukendt"),
        age = y and calcAge(y, m, d) or nil,
        cardNumber = record and record.card_number or nil,
        issuedAt = record and tonumber(record.issued_at) or nil,
        categories = categories,
        points = getPoints(xPlayer.identifier),
        maxPoints = Config.Points.threshold,
        issuer = Config.Issuer,
        country = Config.CountryCode,
        serverId = src,
        updatedAt = os.time(),
    }
end

local function getNearbyPolice(src, maxDistance)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return {} end

    local coords = GetEntityCoords(ped)
    local list = {}

    for _, xTarget in pairs(ESX.GetExtendedPlayers()) do
        if xTarget.source ~= src and isPolice(xTarget) then
            local targetPed = GetPlayerPed(xTarget.source)
            if targetPed and targetPed ~= 0 then
                local distance = #(coords - GetEntityCoords(targetPed))
                if distance <= maxDistance then
                    list[#list + 1] = {
                        id = xTarget.source,
                        name = xTarget.getName and xTarget.getName() or GetPlayerName(xTarget.source),
                        distance = math.floor(distance + 0.5),
                    }
                end
            end
        end
    end

    table.sort(list, function(a, b) return a.distance < b.distance end)
    return list
end

local function onCooldown(src)
    local now = os.time()
    if cooldowns[src] and now - cooldowns[src] < Config.Cooldown then
        return true
    end
    cooldowns[src] = now
    return false
end

local function deliver(target, card, method)
    TriggerClientEvent("luudi_korekort:client:receive", target, {
        card = card,
        method = method,
        receivedAt = os.time(),
    })
end

-- ─── Callbacks ──────────────────────────────────────────────────────────────

lib.callback.register("luudi_korekort:getCard", function(src)
    return buildCard(src)
end)

lib.callback.register("luudi_korekort:isPolice", function(src)
    return isPolice(ESX.GetPlayerFromId(src))
end)

lib.callback.register("luudi_korekort:getNearbyPolice", function(src)
    return getNearbyPolice(src, Config.AirShareDistance)
end)

lib.callback.register("luudi_korekort:sendNearest", function(src)
    if onCooldown(src) then
        return { ok = false, message = "Vent et øjeblik før du sender igen." }
    end

    local card = buildCard(src)
    if not card or card.status ~= "valid" then
        return { ok = false, message = "Du har ikke et gyldigt kørekort." }
    end

    local nearest = getNearbyPolice(src, Config.SendDistance)[1]
    if not nearest then
        return { ok = false, message = "Ingen politi i nærheden." }
    end

    deliver(nearest.id, card, "nearest")
    return { ok = true, message = ("Kørekort sendt til %s."):format(nearest.name) }
end)

lib.callback.register("luudi_korekort:airshare", function(src, targetId)
    targetId = tonumber(targetId)
    if not targetId then return { ok = false, message = "Ugyldig modtager." } end

    if onCooldown(src) then
        return { ok = false, message = "Vent et øjeblik før du sender igen." }
    end

    local card = buildCard(src)
    if not card or card.status ~= "valid" then
        return { ok = false, message = "Du har ikke et gyldigt kørekort." }
    end

    -- Tjek igen på serveren, så klienten ikke kan sende til hvem som helst
    local allowed = false
    for _, officer in ipairs(getNearbyPolice(src, Config.AirShareDistance)) do
        if officer.id == targetId then allowed = true break end
    end
    if not allowed then
        return { ok = false, message = "Betjenten er ikke længere i nærheden." }
    end

    local fromName = ("%s %s"):format(card.firstName, card.lastName)
    local ok, accepted = pcall(lib.callback.await, "luudi_korekort:airshareRequest", targetId, fromName)

    if not ok or not accepted then
        return { ok = false, message = "Betjenten afviste AirShare." }
    end

    deliver(targetId, card, "airshare")
    return { ok = true, message = "Kørekort delt via AirShare." }
end)

AddEventHandler("playerDropped", function()
    cooldowns[source] = nil
end)
