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
  -- TODO define backing for guidebooks:new
end

-- Backing for guidebooks:register(guidebook, options)
local function register(guidebook, options)
  -- Define locals
  local formname = options.formname or guidebook.name
  local craftitem = options.craftitem or guidebook.name
  local definition = {
    description = options.description,
    inventory_image = options.inventory_image,
    on_use =
      function(itemstack, user, pointed_thing)
        if user.is_player() then
          local should_show = true
          if options.use_callback then
            should_show = options.use_callback(itemstack, user, pointed_thing)
          end

          if should_show then
            guidebook.show(user.get_player_name(), formname)
          end
        end
      end,
  }
  setmetatable(definition, { __index = options.definition })
  local defaults = {
    description = guidebook.name .. ': A Guide',
    -- inventory_image = TODO add default texture
  }

  -- this is required to honor nested metatables for options.definition..
  -- we could loop down the rabbit hole.. but that would be antagonizing...
  for key, value in pairs(defaults) do
    if definition[key] == nil then
      definition[key] = value
    end
  end

  -- Catch points of failure:
  if
    options.recipeitem == nil or
    minetest.registered_craftitems[craftitem] ~= nil
  then
    return false
  end

  -- Cache the Guide
  guides[guidebook.name] = {
    guide = guidebook,
    options = options,
  }

  -- Register CraftItem and Craft
  minetest.register_craftitem(craftitem, definition)
  if compatibility.should_register_craft() then
    minetest.register_craft(
      {
        output = craftitem,
        type = "shapeless",
        recipe = {compatibility.get_book(), options.recipeitem}
      }
    )
  end

  -- Register Receive Fields
  minetest.register_on_player_recieve_fields(
    function(player, in_formname, fields)
      if in_formname ~= formname then
        return false
      end

      return guidebooks.receive(player, fields)
    end
  )

  -- We're done!
  return true
end

-- Backing for guidebooks:unregister(identifier)
local function unregister(identifier)
  -- TODO define backing for guidebooks:unregister
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

-- Global Registration Functions
--------------------------------

-- TODO add global registration functions for persisting / managing context?

-- Return API
-------------

return
{
    new = new,
    register = register,
    unregister = unregister,
    locate = locate,
}
