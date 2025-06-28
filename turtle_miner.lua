---@diagnostic disable: undefined-global
local helper = require("helper")


local function stuck()
    local x, y, z = gps.locate()
    -- TODO: broadcast over rednet
    helper.println("hey stepbro, i'm stuck...")
    helper.println("I'm currently located at (" .. x .. ", " .. y .. ", " .. z .. ")")
end

local function checkUp()

end

local function up()
    local attempt = 0
    while turtle.up() == false do
        turtle.digUp()
        turtle.attackUp()
        attempt = attempt + 1
        if attempt >= 10 then
            stuck()
        end
    end
end

local function down()
    local attempt = 0
    while turtle.down() == false do
        turtle.digDown()
        turtle.attackDown()
        attempt = attempt + 1
        if attempt >= 10 then
            stuck()
        end
    end
end

local function forward()
    local attempt = 0
    while turtle.forward() == false do
        turtle.dig()
        turtle.attack()
        attempt = attempt + 1
        if attempt >= 10 then
            stuck()
        end
    end
end

local function back()
    if turtle.back() == false then
        turtle.turnRight()
        turtle.turnRight()
        turtle.forward()
        turtle.turnRight()
        turtle.turnRight()
    end
end

return
{
    up = up,
    down = down,
    forward = forward,
    back = back
}
