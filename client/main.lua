local APP_ID = Config.App.identifier
local RESOURCE = GetCurrentResourceName()

local received = {}  -- kort modtaget af betjenten (kun i hukommelsen)
local headshots = {} -- [key] = handle

-- ─── App registrering ───────────────────────────────────────────────────────

local function sendToApp(action, data)
    exports["lb-phone"]:SendCustomAppMessage(APP_ID, { action = action, data = data })
end

local function addApp()
    local url = GetResourceMetadata(RESOURCE, "ui_page", 0)
    local ui = url:find("http") and url or (RESOURCE .. "/" .. url)

    pcall(function()
        exports["lb-phone"]:RemoveCustomApp(APP_ID)
    end)

    local added, err = exports["lb-phone"]:AddCustomApp({
        identifier = APP_ID,
        name = Config.App.name,
        description = Config.App.description,
        defaultApp = Config.App.defaultApp,
        fixBlur = true,
        ui = ui,
        icon = ("https://cfx-nui-%s/web/icon.png"):format(RESOURCE),
        onUse = function()
            sendToApp("appOpened")
        end,
    })

    if not added then
        print("[luudi_korekortapp] Kunne ikke tilføje app:", err)
    end
end

CreateThread(function()
    while GetResourceState("lb-phone") ~= "started" do Wait(500) end
    addApp()
end)

AddEventHandler("onResourceStart", function(name)
    if name == "lb-phone" then
        Wait(1000)
        addApp()
    end
end)

-- ─── Headshot (billede på kortet) ───────────────────────────────────────────

local function releaseHeadshot(key)
    if headshots[key] then
        UnregisterPedheadshot(headshots[key])
        headshots[key] = nil
    end
end

local function createHeadshot(ped, key)
    releaseHeadshot(key)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return nil end

    local handle = RegisterPedheadshot(ped)
    local started = GetGameTimer()

    while not IsPedheadshotReady(handle) or not IsPedheadshotValid(handle) do
        if GetGameTimer() - started > 5000 then
            UnregisterPedheadshot(handle)
            return nil
        end
        Wait(50)
    end

    headshots[key] = handle
    local txd = GetPedheadshotTxdString(handle)
    return ("https://nui-img/%s/%s?t=%d"):format(txd, txd, GetGameTimer())
end

local function pedFromServerId(serverId)
    if serverId == GetPlayerServerId(PlayerId()) then return PlayerPedId() end
    local player = GetPlayerFromServerId(serverId)
    if player == -1 then return nil end
    return GetPlayerPed(player)
end

-- ─── Notifikation ───────────────────────────────────────────────────────────

local function notify(title, content)
    local ok = pcall(function()
        exports["lb-phone"]:SendNotification({ app = APP_ID, title = title, content = content })
    end)
    if not ok then
        lib.notify({ title = title, description = content, type = "inform" })
    end
end

-- ─── NUI callbacks fra appen ────────────────────────────────────────────────

RegisterNUICallback("getCard", function(_, cb)
    cb(lib.callback.await("luudi_korekort:getCard", false))
end)

RegisterNUICallback("getPhoto", function(_, cb)
    cb({ url = createHeadshot(PlayerPedId(), "self") })
end)

RegisterNUICallback("isPolice", function(_, cb)
    cb({ police = lib.callback.await("luudi_korekort:isPolice", false) == true })
end)

RegisterNUICallback("getNearbyPolice", function(_, cb)
    cb(lib.callback.await("luudi_korekort:getNearbyPolice", false) or {})
end)

RegisterNUICallback("sendNearest", function(_, cb)
    cb(lib.callback.await("luudi_korekort:sendNearest", false))
end)

RegisterNUICallback("airshare", function(data, cb)
    cb(lib.callback.await("luudi_korekort:airshare", false, data and data.target))
end)

RegisterNUICallback("getReceived", function(_, cb)
    cb(received)
end)

RegisterNUICallback("clearReceived", function(_, cb)
    for _, entry in ipairs(received) do releaseHeadshot(entry.key) end
    received = {}
    cb(received)
end)

-- ─── Modtagelse (betjent) ───────────────────────────────────────────────────

lib.callback.register("luudi_korekort:airshareRequest", function(fromName)
    local answered = false

    SetTimeout(Config.AirShareTimeout * 1000, function()
        if not answered then lib.closeAlertDialog() end
    end)

    local result = lib.alertDialog({
        header = "AirShare",
        content = ("**%s** vil dele sit kørekort med dig."):format(fromName or "Ukendt"),
        centered = true,
        cancel = true,
        labels = { confirm = "Accepter", cancel = "Afvis" },
    })

    answered = true
    return result == "confirm"
end)

RegisterNetEvent("luudi_korekort:client:receive", function(payload)
    if not payload or not payload.card then return end

    local card = payload.card
    local key = ("rx_%d_%d"):format(card.serverId or 0, GetGameTimer())

    local entry = {
        key = key,
        card = card,
        method = payload.method,
        receivedAt = payload.receivedAt,
        photo = createHeadshot(pedFromServerId(card.serverId), key),
    }

    table.insert(received, 1, entry)
    while #received > Config.MaxReceived do
        local removed = table.remove(received)
        releaseHeadshot(removed.key)
    end

    sendToApp("received", received)
    notify("Kørekort modtaget", ("%s %s har delt sit kørekort."):format(card.firstName, card.lastName))
end)

AddEventHandler("onResourceStop", function(name)
    if name ~= RESOURCE then return end
    for key in pairs(headshots) do releaseHeadshot(key) end
    pcall(function() exports["lb-phone"]:RemoveCustomApp(APP_ID) end)
end)
