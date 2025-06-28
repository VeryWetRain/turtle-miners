---@diagnostic disable: undefined-global
-- helper functions

-- clear terminal
local function reset()
  term.clear()
  term.setCursorPos(1,1)
end

-- print line without newline
local function print(str)
  io.write(str)
end

-- print line with newline
local function println(str)
  io.write(str .. "\n")
end

-- print line to center of screen
local function printCenter(text)
  local x, y = term.getCursorPos()
  local width, height = term.getSize()
  term.setCursorPos(math.floor((width - #text) / 2) + 1, y)
  term.write(text)
end

-- print line and return input from stdin
local function input(str)
  print(str)
  return io.read()
end

return
{
  reset = reset,
  print = print,
  println = println,
  input = input,
  printCenter = printCenter
}