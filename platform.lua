---@diagnostic disable: undefined-global
local helper = require("helper")
local hturtle = require("turtle_miner")
local stringUtils = require("cc.strings")

-- TODO: read from list. generate filter list from connected chest at MOTHER computer
local building_blocks =
{
    ["twigs:cobblestone_bricks"] = true,
}

-- miner's inventory positions for key items
local light = 1

local torchInterval = 5  -- block interval for torch placement

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


local function checkIfOnLeftmost()
    local x, y, z = gps.locate()
    return isOnMeridian and (x == origin[1]) or (z == origin[3])
end

local function selectBuildingBlock()
    for i = 2, 16 do
        local itemDetail = turtle.getItemDetail(i)
        if itemDetail ~= nil then
            local itemName = itemDetail["name"]
            if building_blocks[itemName] then
                turtle.select(i)
                return
            end
        end
    end
end

local function excavateLayer(width, height)
    local initAction
    local finalAction

    -- check if starting on left or right
    if checkIfOnLeftmost() then
        initAction = turtle.turnRight
        finalAction = turtle.turnLeft
    else
        initAction = turtle.turnLeft
        finalAction = turtle.turnRight
    end

    -- start first layer
    hturtle.forward()
    initAction()

    -- lay platform below turtle
    for i = 1, width do
        selectBuildingBlock()
        turtle.placeDown()

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
    -- iterate through inventory and throw out non-whitelisted items
    for i = 2, 16 do
        turtle.select(i)

        local itemDetail = turtle.getItemDetail(i)
        if itemDetail ~= nil then
            local itemName = itemDetail["name"]
            if not building_blocks[itemName] then
                turtle.dropDown()
            end
        end
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
    local totalBlocks = width * dist

    -- TODO: ask for fillSurfacesEnabled

    helper.println("The turtle will go " .. dist .. " blocks to " .. calculateDestination(dist))
    helper.println("Okay, " ..
        os.getComputerLabel() .. " will lay a platform " .. width .. " blocks wide.")
    helper.println("This will lay approximately " .. totalBlocks .. " blocks.")

    excavate(dist, width, 1)
end

-- Start of Execution --
init()
