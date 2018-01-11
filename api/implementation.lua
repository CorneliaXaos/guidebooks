--[[
  This file contains the implementation for the api.  The developer wishing to
  create a guidebook doesn't need to look at this file.  This file pulls most
  of the heavy logic out of the api/init.lua file so that it is an easy to read
  and understand file.
]]

-- Local Helper Objects
------------------------

local modpath = minetest.get_modpath('guidebooks')
local modstorage = minetest.get_mod_storage()
local compatibility = dofile(modpath .. '/api/compatibility.lua')
local formspecs = dofile(modpath .. '/api/formspecs.lua')
local settings = dofile(modpath .. '/common/settings.lua')
local utility = dofile(modpath .. '/api/utility.lua')

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
local formnames = {}

-- API Functions
----------------

-- Backing for guidebooks:new(definition)
local function new(definition)
  local guide = {}

  -- Verify Incoming Definition
  if not utility.verify_guide(definition) then
    return nil
  end

  -- Rectify Options
  definition.options = rectify_options(definition.options)

  -- Assign Defintion Data
  guide.name = definition.name
  guide.display = definition.display
  guide.section_groups = definition.section_groups
  guide.options = definition.options

  -- Gen New Tables
  guide.context = {}

  -- Assign Operating Functions
  -- IDEA these functions could be moved out of here into their own file
  function guide:show(player_name, formname)
    local formspec = formspecs.render_guide(self)
    context.volatile.open = true
    minetest.show_formspec(player_name, formname, formspec)
  end

  function guide:receive(player_name, fields)
    -- TODO receive code
  end

  -- Return Guidebook
  return guide
end

-- Backing for guidebooks:register(guidebook, options)
local function register(guidebook, options)
  options.formname = options.formname or guidebook.name
  options.craftitem = options.craftitem or guidebook.name

  -- Define locals
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
    inventory_image = 'guidebooks_inventory_image.png'
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
    guides[guidebook.name] ~= nil or
    formnames[options.formname] ~= nil or
    options.recipeitem == nil or
    minetest.registered_craftitems[craftitem] ~= nil
  then
    return false
  end

  -- Cache the Guide Data
  guides[guidebook.name] = {
    guide = guidebook,
    options = options,
  }
  formnames[options.formname] = guidebook.name

  -- Register CraftItem and Craft
  minetest.register_craftitem(options.craftitem, definition)
  if compatibility.should_register_craft() then
    minetest.register_craft(
      {
        output = craftitem,
        type = "shapeless",
        recipe = {compatibility.get_book(), options.recipeitem}
      }
    )
  end

  -- We're done!
  return true
end

-- Backing for guidebooks:unregister(identifier)
local function unregister(identifier)
  -- First, find our guidebook
  local guidebook, options
  do -- initialize guidebook
    local type = type(identifier)
    if type == "string" then
      if guides[identifier] ~= nil then
        guidebook = guides[identifier].guide
        options = guides[identifier].options
      else
        return false
      end
    elseif type == "table" then
      if identifier.name ~= nil then
        if identifier == guides[identifer.name].guide then
          guidebook = identifier
          options = guides[guidebook.name].options
        else
          return false
        end
      else
        return false
      end
    else
      return false
    end
  end

  -- attempt to unregister craft
  if compatibility.should_register_craft() then
    minetest.clear_craft(options.craftitem)
  end

  -- clear craftitem
  minetest.unregister_item(options.craftitem)

  -- clear cache
  guides[guidebook.name] = nil
  formnames[guidebook.options.formname] = nil

  -- success
  return true
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

-- Local Helper Functions
-------------------------
-- IDEA move this to a `persist.lua` ?

local function persist_clean(player_name)
  for _, entry in pairs(guides) do
    entry.guide.context[player_name] = nil
  end
end

local function persist_load(player_name)
  local stored = modstorage.get_string(player_name)
  local persist

  -- It looks as if unset strings will return the empty string..
  -- We'll check both to be safe.
  if stored ~= nil and stored ~= '' then
      persist = minetest.deserialize(stored)
  end

  return persist
end

local function persist_player(player_name)
  local persist = {}
  for name, entry in pairs(guides) do
    persist[name] = entry.guide.context[player_name].persist
  end
  local to_store = minetest.serialize(persist)

  modstorage.set_string(player_name, to_store)
end

local function persist_global()
  for _, player in ipairs(minetest.get_connected_players()) do
    persist_player(player.get_player_name())
  end
end

-- Global Registration Functions
--------------------------------

minetest.register_on_player_recieve_fields(
  function(player, formname, fields)
    local guide_name = formnames[formname]

    if guide_name ~= nil then
      local guide = guides[guide_name].guide
      return guide.receive(player.get_player_name(), fields)
    else
      return false
    end
  end
)

minetest.register_on_joinplayer(
  -- IDEA add "context initializer" callback to guides
  function(player)
    local player_name = player.get_player_name()

    -- grab persisted data for this player
    -- data for removed guidebooks is automatically discarded
    local persist = persist_load(player_name) or {}

    -- set up contexts for all registered guides
    for name, entry in pairs(guides) do
      entry.guide.context[player_name] = {}
      entry.guide.context[player_name].volatile = {
        open = false,
        section_group = 1,
        section = 1,
        page_group = 1,
        page = 1,
        scroll = {
          section_group = 0, -- no offset, start at top
          index = 0, -- index scrollbar is least amount of scrolled
        }
      }

      entry.guide.context[player_name] = persist[name] or {
        bookmarks = {},
        shared = {}
      }
    end
  end
)

minetest.register_on_leaveplayer(
  function(player, timed_out)
    local player_name = player.get_player_name()
    persist_player(player_name)
    persist_clean(player_name)
  end
)

minetest.register_on_shutdown(persist_global)

minetest.after(settings.persist.rate,
  function()
     -- HACK I dunno why.. but this feels hacky. :P
    local rabbit_hole
    rabbit_hole = function()
      persist_global()
      minetest.after(settings.persist.rate, rabbit_hole)
    end

    rabbit_hole() -- down we go!
  end
)

-- Return API
-------------

return
{
    new = new,
    register = register,
    unregister = unregister,
    locate = locate,
}
