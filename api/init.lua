--[[
  This init file serves to initialize the main guidebooks api.  It creates
  the global guidebooks object and sets up the necessary structures for
  guidebooks to be created by this mod or by others.
]]

-- Declare local helper variables
---------------------------------
local modpath = minetest.get_modpath('guidebooks')
local implementation = dofile(modpath .. '/api/implementation.lua')

-- Initialize the public facing guidebooks api objects
-------------------------------
guidebooks = {}
local guides = {} -- key-value table of registered guides

--[[
  Creates a new guidebook.  The guidebook is not registered into the system
  automatically in case the developer wishes to manually handle faculties
  such as recipe and item registration.

  definition:
    {

    }

  returns the created guidebook.
]]
guidebooks.new(definition) = implementation.new

--[[
  Registers a guidebook with the management api.  Registered books go through
  a common system for creating the crafting recipes and items for the books
  allowing guidebooks to handle compatibility between other mods.  Guides don't
  need to be registered if the developer wishes to handle these things
  themselves.

  guidebook:  the guidebook created by a call to `guidebooks:new`
  options:
    {

    }

  returns true if the registration was successful, false otherwise.
]]
guidebooks.register(guidebook, options) = implementation.register

--[[
  Unregisters a guidebook that was previously registered.

  identifier: either...
    - a string identifying the name of the guidebook, or...
    - the guidebook table itself

  returns true if the guidebook was previously registered and was successfully
    unregistered, false otherwise.
]]
guidebooks.unregister(identifier) = implementation.unregister

--[[
  Locates a registered guidebook via the name it was registered with.

  name:  the string identifying the guidebooks

  returns the guidebook table, or nil if no guidebook was found.
]]
guidebooks.locate(name) = implementation.locate

-- Package Finalization
-----------------------

return guidebooks
