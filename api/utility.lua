--[[
  This file contains various utility functions used by the guidebooks API.  It
  may or may not be made availalbe to users of the API.
]]

local modpath = minetest.get_modpath('guidebooks')
local defaults = dofile(modpath .. '/api/defaults.lua')

-- Guidebook Options Verification Functions
-------------------------------------------

--[[
  Utility function for comparing types and quickly determining the value to set.

  value: the value to compare
  type: the string type name
  predicate: an additional test to perform, function takes value as argument

  return the value to set.
]]
local function match_type(value, type_name, predicate)
  if type(value) == type_name then
    if predicate and not predicate(value) then
      return nil -- fails custom test, return nil
    else
      return value
    end
  else
    return nil -- wrong type, return nil
  end
end

--[[
  Rectifies the dimensions subtable of the guidebook options table.

  dimensions: the subtable governing dimensions
]]
local function rectify_dimensions(dimensions)
  -- Predicate: is_positive
  local is_positive = function(value) return value > 0 end

  -- Check members for types:
  dimensions.index = match_type(dimensions.index, 'number', is_positive)
  dimensions.page = match_type(dimensions.page, 'number', is_positive)
  dimensions.height = match_type(dimensions.height, 'number', is_positive)

  -- Apply Defaults
  setmetatable(dimensions, defaults.options.dimensions)
end

--[[
  Rectifies the textures subtable of the guidebook options table.

  textures: the subtable governing formspec textures
]]
local function rectify_textures(textures)
  -- Predicate: is_not_empty
  local is_not_empty = function(value) return value ~= '' end

  -- Check members for types:
  -- TODO need to determine what textures we'll have

  -- Apply Defaults
  setmetatable(textures, defaults.options.textures)
end

--[[
  Rectifies the max values subtable of the guidebook options table.

  max: the subtable governing max values
]]
local function rectify_max(max)
  -- Predicate: is_not_negative
  local is_not_negative = function(value) return value >= 0 end

  -- Check members for types:
  match_type(max.bookmarks, 'number', is_not_negative)
  match_type(max.shared, 'number', is_not_negative)

  -- Apply Defaults
  setmetatable(max, defaults.options.max)
end

local function rectify_options(options)
  -- Make sure we have a valid table
  options = options or {}
  options.dimensions = options.dimensions or {}
  options.textures = options.textures or {}
  options.max = options.max or {}

  -- Correct and Apply Defaults
  rectify_dimensions(options.dimensions)
  rectify_textures(options.textures)
  rectify_max(options.max)

  -- Return validated options table
  return options
end

-- Guidebook Verification Functions
-----------------------------------
-- TODO add error reporting for why a guidebook 'primitive' is invalid.

--[[
  This function verifies a page 'primitive'.

  page: See api/init.lua / guidebooks:new

  returns true if the page is valid, false otherwise.
]]
local function verify_page(page)
  -- At the moment, pages are simply functions that return formspec strings
  return type(page) == 'function'
end

--[[
  This function verifies the contents of a single page_group.

  page_group: See api/init.lua / guidebooks:new

  returns true if the page_group is valid, false otherwise.
]]
local function verify_page_group(page_group)
  -- A page_group needs a name and a table of pages
  if
    type(page_group) ~= 'table' or
    type(page_group.name) ~= 'string' or
    page_group.name == '' or
    type(page_group.pages) ~= 'table'
  then
    return false
  end

  -- Validate all pages
  for _, page in ipairs(page_group.pages) do
    if not verify_page(page) then
      return false
    end
  end

  -- page_group is valid
  return true
end

--[[
  This function verifies the contents of a section.

  section: See api/init.lua / guidebooks:new

  returns true if the section is valid, false otherwise.
]]
local function verify_section(section)
  -- A section needs a name, an icon, an index style, and a set of page_groups
  if
    type(section) ~= 'table' or
    type(section.name) ~= 'string' or
    section.name == '' or
    type(section.icon) ~= 'string' or
    section.icon == '' or
    type(section.index) ~= 'number' or
    section.index < 1 or section.index > 3 or
    type(section.page_groups) ~= 'table'
  then
    return false
  end

  -- Validate all page_groups.
  for _, page_group in ipairs(section.page_groups) do
    if not verify_page_group(page_group) then
      return false
    end
  end

  -- section is valid.
  return true
end

--[[
  This function verifies the contents of a section_group.

  section_group: See api/init.lua / guidebooks:new
]]
local function verify_section_group(section_group)
  -- A section_group needs a name and a table of sections
  if
    type(section_group) ~= 'table' or
    type(section_group.name) ~= 'string' or
    section_group.name == '' or
    type(section_group.sections) ~= 'table'
  then
    return false
  end

  -- Validate all sections
  for _, section in ipairs(section_group.sections) do
    if not verify_section(section) then
      return false
    end
  end

  -- section_group is valid
  return true
end

--[[
  This function verifies the contents of a guidebook definition.

  definition: See api/init.lua / guidebooks:new

  returns true if the definition is valid, false otherwise.
]]
local function verify_guide(definition)
  -- Make sure the guidebook has a valid name.
  if
    type(definition.name) ~= 'string' or
    definition.name == ''
  then
    return false
  end

  -- Make sure the guidebook has a valid display string.
  if
    type(definition.display) ~= 'string' or
    definition.display == ''
  then
    return false
  end

  -- Check that the guide has at least one section_group and all are valid
  if
    type(definition.section_groups) ~= 'table' or
    #defintion.section_groups < 1
  then
    return false
  end

  for _, section_group in ipairs(defintion.section_groups) do
    if not verify_section_group(section_group) then
      return false
    end
  end

  -- Definition is valid.
  return true
end

-- Export Utility
-----------------

return {
  rectify_options = rectify_options,
  verify_guide = verify_guide,
}
