--[[
  This file contains the implementation for the api.  The developer wishing to
  create a guidebook doesn't need to look at this file.  This file pulls most
  of the heavy logic out of the api/init.lua file so that it is an easy to read
  and understand file.
]]

-- Local Helper Objects
------------------------

local modpath = minetest.get_modpath('guidebooks')
local compatibility = dofile(modpath .. '/api/compatibility.lua')
local settings = dofile(modpath .. '/common/settings.lua')

-- API Objects
--------------

--[[
  Contains registered guides in a key-value table where the key is the
  registered name of the guide and the value is a table of the form:
    {
      guide = the guidebook table itself,
      options = the options used when registering the guidebook
    }
]]
local guides = {}

-- API Functions
----------------

-- Backing for guidebooks:new(definition)
local function new(definition)
  -- TODO
end

-- Backing for guidebooks:register(guidebook, options)
local function register(guidebook, options)
  -- TODO
end

-- Backing for guidebooks:unregister(identifier)
local function unregister(identifier)
  -- TODO
end

-- Backing for guidebooks:locate(name)
local function locate(name)
  local entry = guides[name]
  if entry ~= nil then
    return entry.guide
  else
    return nil
  end
end

-- Return API
-------------

return
{
    new = new,
    register = register,
    unregister = unregister,
    locate = locate,
}
