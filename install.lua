-- SHRON installer
-- Run with:
-- wget run https://raw.githubusercontent.com/Frez7373/shron/main/install.lua

local BASE = "https://raw.githubusercontent.com/Frez7373/shron/main/"
local APP_URL = BASE .. "vault.lua"
local APP_PATH = "/vault.lua"

term.clear()
term.setCursorPos(1, 1)

print("================================")
print("          SHRON INSTALLER        ")
print("================================")
print()

if not http then
    print("ERROR: HTTP is disabled.")
    print("Enable HTTP in CC:Tweaked config.")
    return
end

local function download(url, path)
    local response, err = http.get(url)
    if not response then
        return false, err or "HTTP request failed"
    end

    local content = response.readAll()
    response.close()

    local file, fileErr = fs.open(path, "w")
    if not file then
        return false, fileErr or "Cannot open destination file"
    end

    file.write(content)
    file.close()

    return true
end

write("Downloading SHRON... ")

local ok, err = download(APP_URL, APP_PATH)
if not ok then
    print("FAILED")
    print()
    print("Error: " .. tostring(err))
    return
end

print("OK")
print()
print("Installed: " .. APP_PATH)
print()
print("Run it with:")
print("  vault")
print()
print("Done.")
