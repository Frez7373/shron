-- SHRON - Create Item Vault monitor
-- CC:Tweaked + Create
-- Designed for a wired modem connection.

local TARGET_NAME = "create:item_vault_0"
local UPDATE_TIME = 1
local STACK_SIZE = 64

local modem = nil

local function findWiredModem()
    local names = peripheral.getNames()
    for _, side in ipairs(names) do
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

local function remoteExists(name)
    if modem and type(modem.isPresentRemote) == "function" then
        local ok, present = pcall(modem.isPresentRemote, name)
        return ok and present == true
    end
    return false
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

    local m, side = findWiredModem()
    if not m then
        return nil, nil, "No wired modem connected"
    end
    modem = m

    if remoteExists(TARGET_NAME) then
        return TARGET_NAME, side, nil
    end

    -- Fallback: find a remote peripheral which has inventory methods.
    local ok, names = pcall(modem.getNamesRemote)
    if ok and type(names) == "table" then
        for _, name in ipairs(names) do
            local typeOk, pType = pcall(modem.getTypeRemote, name)
            if typeOk and pType == "inventory" then
                return name, side, nil
            end

            local methodOk, methods = pcall(modem.getMethodsRemote, name)
            if methodOk and type(methods) == "table" then
                local hasList, hasSize = false, false
                for _, method in ipairs(methods) do
                    if method == "list" then hasList = true end
                    if method == "size" then hasSize = true end
                end
                if hasList and hasSize then
                    return name, side, nil
                end
            end
        end
    end

    return nil, side, "Item Vault not found on wired network"
end

local function getStackLimit(name, slot)
    local ok, limit = remoteCall(name, "getItemLimit", slot)
    if ok and type(limit) == "number" and limit > 0 then
        return limit
    end
    return STACK_SIZE
end

local function draw()
    term.clear()
    term.setCursorPos(1, 1)

    local width = term.getSize()
    local line = string.rep("=", math.max(34, width))

    print(line)
    print("             SHRON")
    print("          ITEM VAULT")
    print(line)
    print()

    local vaultName, modemSide, findError = findVault()

    if not vaultName then
        print("STATUS: NOT CONNECTED")
        print()
        print(findError or "Unknown error")
        print()
        if modemSide then
            print("Wired modem: " .. modemSide)
        else
            print("Connect a wired modem to the computer.")
        end
        print()
        print("Press any key for retry...")
        return false
    end

    local okSize, slots = remoteCall(vaultName, "size")
    if not okSize or type(slots) ~= "number" then
        print("STATUS: ERROR")
        print()
        print("Cannot read inventory size.")
        print("Device: " .. vaultName)
        return false
    end

    local okList, items = remoteCall(vaultName, "list")
    if not okList or type(items) ~= "table" then
        print("STATUS: ERROR")
        print()
        print("Cannot read inventory contents.")
        print("Device: " .. vaultName)
        return false
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
    print("Used slots:   " .. usedSlots .. "/" .. slots)
    print()
    print("FULL STACKS:  " .. fullStacks)
    print("LOOSE ITEMS:  " .. looseItems)
    print("TOTAL ITEMS:  " .. totalItems)
    print()
    print("1 stack = up to " .. STACK_SIZE .. " items")
    print()
    print("Updating every " .. UPDATE_TIME .. " sec.")
    return true
end

while true do
    local ok = pcall(draw)

    if not ok then
        term.clear()
        term.setCursorPos(1, 1)
        print("SHRON")
        print()
        print("Unexpected error while reading Item Vault.")
        print("Retrying...")
    end

    sleep(UPDATE_TIME)
end
