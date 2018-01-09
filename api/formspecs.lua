--[[
  This file contains the logic used to render the guide formspec to the player.
]]

local modpath = minetest.get_modpath('guidebooks')

-- Stubs
--------

local function read_stub(stub)
  local stub
  local file = io.open(stub, 'r')
  if file then
    stub = file:read('*all')
    file:close()
  end
  if stub then stub = stub:gsub('[\r\n]') end -- remove newlines
  return stub
end

local stubs = {
  guidebook = read_stub(modpath .. '/formspecs/guidebook.stub'),
  top_bar = read_stub(modpath .. '/formspecs/top_bar.stub'),
  bottom_bar = read_stub(modpath .. '/formspecs/bottom_bar.stub')
}

-- Helper Functions
-------------------

local function calculate_bookmark_count(guidebook)
  -- TODO implement calculate_bookmark_count
end

local function calculate_exact_dimensions(options)
  -- TODO implement calculate_exact_dimensions
end

local function calculate_section_count(guidebook)
  -- TODO implement calculate_section_count
end

-- Formspec Rendering Functions
-------------------------------

local function render_top_bar()
  -- TODO
end

local function render_section_tabs()
  -- TODO
end

local function render_scroll_bar()
  -- TODO
end

local function render_index_tiled()
  -- TODO
end

local function render_index_tile_with_text()
  -- TODO
end

local function render_index_text()
  -- TODO
end

local function render_index()
  -- TODO
end

local function render_page()
  -- TODO
end

local function render_bookmark_tabs()
  -- TODO
end

local function render_bottom_bar()
  -- TODO
end

--[[
  This function renders a guidebook by constructing the appropriate formspec.

  guidebook:  the guidebook produced by guidebooks.new

  return a string formspec
]]
local function render_guide(guidebook)
  local formspec = stubs.guidebook
  local dims = calculate_exact_dimensions(guidebook.options)

  -- Set Width and Height
  formspec = formspec:gsub('%WIDTH%', dims.total_width)
  formspec = formspec:gsub('%HEIGHT%', dims.total_height)

  -- TODO Set Background Texture
  formspec =
    formspec:gsub('%BACKGROUND%', guidebook.options.textures.background)

  -- Fill Containers
  local top_bar = render_top_bar(--[[TODO args]])
  local section_tabs = render_section_tabs(--[[TODO args]])
  local scroll_bar = render_scroll_bar(--[[TODO args]])
  local index = render_index(--[[TODO args]])
  local page = render_page(--[[TODO args]])
  local bookmark_tabs = render_bookmark_tabs(--[[TODO args]])
  local bottom_bar = render_bottom_bar(--[[TODO args]])

  -- Apply Containers
  formspec = formspec:gsub('%TOP_BAR_CONTAINER%', top_bar)
  formspec = formspec:gsub('%SECTION_TAB_CONTAINER%', section_tabs)
  formspec = formspec:gsub('%SCROLL_BAR_CONTAINER%', scroll_bar)
  formspec = formspec:gsub('%INDEX_CONTAINER%', index)
  formspec = formspec:gsub('%PAGE_CONTAINER%', page)
  formspec = formspec:gsub('%BOOKMARK_CONTAINER%', bookmark_tabs)
  formspec = formspec:gsub('%BOTTOM_BAR_CONTAINER%', bottom_bar)

  -- return formspec
  return formspec
end

-- Return Formspec Object
-------------------------
return {
  helpers = {
    calculate_bookmark_count = calculate_bookmark_count,
    calculate_exact_dimensions = calculate_exact_dimensions,
    calculate_section_count = calculate_section_count
  },
  render_guide = render_guide
}
