---@diagnostic disable: undefined-global
local helper = require("helper")
local hturtle = require("turtle_miner")
local stringUtils = require("cc.strings")

local valuable_loot =
{
    ["minecraft:ancient_debris"] = true,
    ["minecraft:diamond"] = true,
    ["minecraft:emerald"] = true,
    ["minecraft:raw_gold"] = true,
    ["minecraft:raw_iron"] = true,
    ["minecraft:redstone"] = true,
    ["minecraft:lapis_lazuli"] = true,
    ["minecraft:coal"] = true,
    ["modern_industrialization:lignite_coal"] = true,
}

local valuable_loot_by_modname = {
    ["indrev"] = true,
}

local filter_list =
{
    "minecraft:cobblestone",
    "minecraft:mossy_cobblestone",
    "minecraft:diorite",
    "minecraft:andesite",
    "minecraft:granite",
    "minecraft:dirt",
    "minecraft:gravel",
    "minecraft:netherrack",
    "minecraft:tuff",
    "minecraft:dripstone_block",
    "minecraft:calcite",
    "minecraft:cobbled_deepslate",
    "minecraft:polished_deepslate",
    "minecraft:infested_stone",
    "minecraft:basalt",
    "minecraft:smoobasalt",
    "minecraft:moss_block",
    "minecraft:clay_ball",
    "twigs:rhyolite",
    "twigs:pebble",
    "promenade:blunite",
    "promenade:asphalt",
    "create:raw_zinc",
    "create_new_age:magnetite_block",
    "create_new_age:thorium",
    "techreborn:peridot_rugem",
    "techreborn:raw_lead",
    "techreborn:raw_silver",
    "techreborn:raw_tin",
    "techreborn:red_garnet",
    "techreborn:ruby_gem",
    "techreborn:sapphire_gem",
    "techreborn:bauxite_ore",
    "techreborn:galena_ore",
    "indrev:raw_lead",
    "modern_industrialization:raw_antimony",
    "modern_industrialization:raw_nickel",
    "bewitchment:salt"
}

-- miner's inventory positions for key items
local light = 1
local lava = 2
local building = 3

local torchInterval = 5 -- block interval for torch placement

local fillSurfacesEnabled = false

local origin = nil       -- miner's point of origin
local isOnMeridian = nil -- is line of longitude (north to south)

local function calculateDestination(distance)
    local x1, y1, z1 = gps.locate()
    origin = { x1, y1, z1 }
    hturtle.forward()
    local x2, y2, z2 = gps.locate()
    hturtle.back()

    local xDelta = x2 - x1
    local zDelta = z2 - z1
    -- west (towards negative x)
    if xDelta == -1 then
        isOnMeridian = false
        return "(" .. x2 - distance .. ", " .. y2 .. ", " .. z2 .. ")"
    end
    -- east (towards positive x)
    if xDelta == 1 then
        isOnMeridian = false
        return "(" .. x2 + distance .. ", " .. y2 .. ", " .. z2 .. ")"
    end
    -- north (towards negative z)
    if zDelta == -1 then
        isOnMeridian = true
        return "(" .. x2 .. ", " .. y2 .. ", " .. z2 - distance .. ")"
    end
    -- south (towards positive z)
    if zDelta == 1 then
        isOnMeridian = true
        return "(" .. x2 .. ", " .. y2 .. ", " .. z2 + distance .. ")"
    end
end

local function checkIfIsOnFloor()
    local x, y, z = gps.locate()
    return origin[2] == y
end

local function checkIfOnCeiling(height)
    local x, y, z = gps.locate()
    return origin[2] + height - 1 == y
end

local function fillSurfaces(height)
    -- check for ceiling and fill
    if checkIfOnCeiling(height) then
        turtle.select(building)
        turtle.placeUp()
    elseif checkIfIsOnFloor() then
        turtle.select(building)
        turtle.placeDown()
    end
end

local function excavateLayer(width, height)
    local initAction
    local firstAction
    local secondAction
    local finalAction

    -- determine if we're on the floor or ceiling
    -- choose initial action
    if checkIfIsOnFloor() then
        firstAction = hturtle.up
        secondAction = hturtle.down
    else
        firstAction = hturtle.down
        secondAction = hturtle.up
    end

    -- check if starting on left or right
    local onRightmost = isOnMeridian and (x ~= origin[1]) or (z ~= origin[3])
    print(onRightmost)
    if onRightmost then
        initAction = turtle.turnLeft
        finalAction = turtle.turnRight
    else
        initAction = turtle.turnRight
        finalAction = turtle.turnLeft
    end

    -- start first layer
    hturtle.forward()
    initAction()

    -- traverse through the layer in an up-down pattern
    for i = 1, width do
        for j = 1, height - 1 do
            if fillSurfacesEnabled then
                fillSurfaces(height)
            end

            if i % 2 == 1 then
                firstAction()
            else
                secondAction()
            end
        end

        if fillSurfacesEnabled then
            fillSurfaces(height)
        end

        -- move to next column except for last column
        if i ~= width then
            hturtle.forward()
        else
            finalAction()
        end
    end
end

local function placeLight()
    local retVal
    -- TODO: dynamically find torches, impl out of torch condition
    turtle.select(light)
    if turtle.getItemDetail(light) ~= nil and turtle.getItemDetail(light)["name"] == "minecraft:torch" then
        turtle.turnRight()
        retVal, _ = turtle.place()
        turtle.turnLeft()
    else -- procedure for when light is a block (ex. froglight)
        hturtle.down()
        hturtle.up()
        retVal, _ = turtle.placeDown()
    end

    return retVal
end

local function disposeTrash()
    -- dig down 2 blocks and place lava
    turtle.select(lava) -- lava bucket
    hturtle.down()
    hturtle.down()
    hturtle.up()
    turtle.placeDown()

    -- iterate through inventory and throw out filtered items
    for i = 4, 16 do
        turtle.select(i)

        local itemDetail = turtle.getItemDetail(i)
        if (itemDetail ~= nil) and (valuable_loot[itemDetail["name"]] or valuable_loot_by_modname[stringUtils.split(itemDetail["name"], ":")[1]]) then
            turtle.dropDown()
        end
    end

    -- grab lava
    turtle.select(lava)
    turtle.placeDown()
    hturtle.up()

    -- fill floor
    if fillSurfacesEnabled then
        turtle.select(building) -- common building block
        turtle.placeDown()
    end
end

local function excavate(dist, width, height)
    local distFromOrigin = 0
    local blocksSinceLastTorch = 5
    while distFromOrigin < dist do
        excavateLayer(width, height)

        if checkIfIsOnFloor() then
            disposeTrash()

            if blocksSinceLastTorch > torchInterval then
                if placeLight() then
                    blocksSinceLastTorch = 0
                end
            end
        end

        distFromOrigin = distFromOrigin + 1
        blocksSinceLastTorch = blocksSinceLastTorch + 1
    end
end

local function init()
    helper.reset()

    helper.println("Welcome to rain's tunnel program! wip...")

    local dist = tonumber(helper.input("How far: "))
    local width = tonumber(helper.input("How wide: "))
    local height = tonumber(helper.input("How tall: "))
    local evcavation = width * height * dist

    helper.println("The turtle will go " .. dist .. " blocks to " .. calculateDestination(dist))
    helper.println("Okay, " ..
        os.getComputerLabel() .. " will mine " .. width .. " blocks wide and " .. height .. " blocks tall.")
    helper.println("This will excavate approximately " .. evcavation .. " blocks.")

    excavate(dist, width, height)
end

-- Start of Execution --
init()
