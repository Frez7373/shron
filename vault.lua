-- SHRON - Create Item Vault monitor
-- CC:Tweaked
-- Shows total items, full stacks and remaining items in the connected Item Vault.

local TARGET_NAME = "create:item_vault_0"
local UPDATE_TIME = 1

local function findVault()
    -- Prefer the exact Create Item Vault peripheral name.
    if peripheral.isPresent(TARGET_NAME) then
        local ok, p = pcall(peripheral.wrap, TARGET_NAME)
        if ok and p then
            return p, TARGET_NAME
        end
    end

    -- Fallback: find any inventory exposed through the wired modem.
    local name = peripheral.find("inventory")
    if name then
        -- peripheral.find returns the wrapped peripheral.
        return name, "auto-detected"
    end

    return nil, nil
end

local function getStackSize(vault, slot)
    if type(vault.getItemLimit) == "function" then
        local ok, limit = pcall(vault.getItemLimit, slot)
        if ok and type(limit) == "number" and limit > 0 then
            return limit
        end
    end
    return 64
end

local function draw()
    term.clear()
    term.setCursorPos(1, 1)

    local width = select(1, term.getSize())
    local line = string.rep("=", math.max(30, width))

    print(line)
    print("          SHRON")
    print("       ITEM VAULT")
    print(line)
    print()

    local vault, source = findVault()
    if not vault then
        print("Item Vault not found.")
        print()
        print("Check:")
        print("  1. Wired modem is connected.")
        print("  2. The modem cable reaches the vault.")
        print("  3. The peripheral is: " .. TARGET_NAME)
        print()
        print("Retrying...")
        return
    end

    local ok, slots = pcall(vault.size)
    if not ok or type(slots) ~= "number" then
        print("Connected peripheral is not a valid inventory.")
        print()
        print("Peripheral: " .. tostring(source))
        return
    end

    local okList, items = pcall(vault.list)
    if not okList or type(items) ~= "table" then
        print("Cannot read Item Vault contents.")
        print()
        print("Peripheral: " .. tostring(source))
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

            local stackSize = getStackSize(vault, slot)
            fullStacks = fullStacks + math.floor(item.count / stackSize)
            looseItems = looseItems + (item.count % stackSize)
        end
    end

    print("Connection: " .. tostring(source))
    print("Slots:      " .. usedSlots .. "/" .. slots)
    print()
    print("Full stacks: " .. fullStacks)
    print("Loose items: " .. looseItems)
    print("Total items: " .. totalItems)
    print()
    print("Update: every " .. UPDATE_TIME .. " sec")
end

while true do
    local ok, err = pcall(draw)
    if not ok then
        term.clear()
        term.setCursorPos(1, 1)
        print("SHRON ERROR")
        print()
        print(tostring(err))
        print()
        print("Retrying...")
    end

    sleep(UPDATE_TIME)
end
