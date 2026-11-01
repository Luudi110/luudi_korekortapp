local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version', 0)
local versionURL = "https://raw.githubusercontent.com/Luudi110/versionchecker/main/koerekort.txt"

local function isNewerVersion(latest, current)
    local function parse(version)
        local major, minor, patch = version:match("^(%d+)%.(%d+)%.(%d+)$")

        if not major then return nil end

        return tonumber(major), tonumber(minor), tonumber(patch)
    end

    local a, b, c = parse(latest)
    local x, y, z = parse(current)

    if not a or not x then return false end

    if a ~= x then return a > x end
    if b ~= y then return b > y end

    return c > z
end

CreateThread(function()
    Wait(3000)

    PerformHttpRequest(versionURL, function(statusCode, response)
        if statusCode == 200 then
            local latestVersion = response:gsub("%s+", "")

            if isNewerVersion(latestVersion, currentVersion) then
                print("^3========================================")
                print("^3[KOEREKORT] NY UPDATE TILGÆNGELIG!")
                print("^3[KOEREKORT] Installeret version: " .. currentVersion)
                print("^2[KOEREKORT] Nyeste version: " .. latestVersion)
                print("^2[KOEREKORT] Download: https://github.com/Luudi110/luudi_korekortapp")
                print("^3========================================^7")
            else
                print("^2[KOEREKORT] Du bruger den nyeste version!^7")
            end
        else
            print("^1[KOEREKORT] Kunne ikke kontrollere GitHub-versionen.^7")
        end
    end, "GET")
end)