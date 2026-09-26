-- SHRON - Create Item Vault monitor
-- CC:Tweaked + Create
-- Designed for a wired modem connection.

local TARGET_NAME = "create:item_vault_0"
local UPDATE_TIME = 1
local DEFAULT_STACK_SIZE = 64

local modem = nil
local lastNames = {}

local function findWiredModem()
    for _, side in ipairs(peripheral.getNames()) do
        local ok, p = pcall(peripheral.wrap, side)
        if ok and p and type(p.isWireless) == "function" then
            local okWireless, wireless = pcall(p.isWireless)
            if okWireless and wireless == false then
                return p, side
            end
        end
    end
    return nil, nil
end

local function remoteCall(name, method, ...)
    if not modem then
        return false, "wired modem not found"
    end

    local args = {...}
    local ok, a, b, c, d = pcall(function()
        return modem.callRemote(name, method, table.unpack(args))
    end)

    if not ok then
        return false, a
    end

    return true, a, b, c, d
end

local function findVault()
    modem = nil
    lastNames = {}

    local m, side = findWiredModem()
    if not m then
        return nil, side, "NO WIRED MODEM"
    end

    modem = m

    local okNames, names = pcall(modem.getNamesRemote)
    if okNames and type(names) == "table" then
        lastNames = names
    else
        return nil, side, "Cannot read wired network devices"
    end

    for _, name in ipairs(names) do
        if name == TARGET_NAME then
            return name, side, nil
        end
    end

    -- Fallback: accept any remote peripheral exposing inventory methods.
    for _, name in ipairs(names) do
        local methodOk, methods = pcall(modem.getMethodsRemote, name)
        if methodOk and type(methods) == "table" then
            local hasList = false
            local hasSize = false

            for _, method in ipairs(methods) do
                if method == "list" then hasList = true end
                if method == "size" then hasSize = true end
            end

            if hasList and hasSize then
                return name, side, nil
            end
        end
    end

    return nil, side, "ITEM VAULT NOT FOUND"
end

local function getStackLimit(name, slot)
    local ok, limit = remoteCall(name, "getItemLimit", slot)
    if ok and type(limit) == "number" and limit > 0 then
        return limit
    end
    return DEFAULT_STACK_SIZE
end

local function draw()
    term.clear()
    term.setCursorPos(1, 1)

    local width = term.getSize()
    local line = string.rep("=", math.max(36, width))

    print(line)
    print("              SHRON")
    print("           ITEM VAULT")
    print(line)
    print()

    local vaultName, modemSide, err = findVault()

    if not vaultName then
        print("STATUS: NOT CONNECTED")
        print()
        print(err or "Unknown error")
        print()

        if modemSide then
            print("Modem: " .. modemSide)
        else
            print("Connect a wired modem to the computer.")
        end

        print()
        print("Remote devices:")

        if #lastNames == 0 then
            print("  (none)")
        else
            local maxShown = math.min(#lastNames, 8)
            for i = 1, maxShown do
                print("  " .. tostring(lastNames[i]))
            end
            if #lastNames > maxShown then
                print("  ... +" .. (#lastNames - maxShown) .. " more")
            end
        end

        print()
        print("Target: " .. TARGET_NAME)
        return
    end

    local okSize, slots = remoteCall(vaultName, "size")
    if not okSize or type(slots) ~= "number" then
        print("STATUS: ERROR")
        print()
        print("Cannot read inventory size.")
        print("Device: " .. tostring(vaultName))
        return
    end

    local okList, items = remoteCall(vaultName, "list")
    if not okList or type(items) ~= "table" then
        print("STATUS: ERROR")
        print()
        print("Cannot read inventory contents.")
        print("Device: " .. tostring(vaultName))
        return
    end

    local totalItems = 0
    local fullStacks = 0
    local looseItems = 0
    local usedSlots = 0

    for slot, item in pairs(items) do
        if type(item) == "table" and type(item.count) == "number" then
            usedSlots = usedSlots + 1
            totalItems = totalItems + item.count

            local limit = getStackLimit(vaultName, slot)
            fullStacks = fullStacks + math.floor(item.count / limit)
            looseItems = looseItems + (item.count % limit)
        end
    end

    print("STATUS: CONNECTED")
    print("Vault: " .. vaultName)
    print("Modem: " .. tostring(modemSide))
    print()
    print("Used slots:  " .. usedSlots .. "/" .. slots)
    print()
    print("FULL STACKS: " .. fullStacks)
    print("LOOSE ITEMS: " .. looseItems)
    print("TOTAL ITEMS: " .. totalItems)
    print()
    print("Stack size: up to " .. DEFAULT_STACK_SIZE)
    print("Updating every " .. UPDATE_TIME .. " sec.")
end

while true do
    pcall(draw)
    sleep(UPDATE_TIME)
end
