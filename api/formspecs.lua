--[[
  This file contains the logic used to render the guide formspec to the player.
]]

local modpath = minetest.get_modpath('guidebooks')

-- Helpers
----------

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

-- IDEA padding configurable via options?
local padding = {
  scroll_bar = 0.5,
  section_tab = 0.0,
  section_tab_icon = 0.25,
  section_buttons = 0.5,
  bar_spacing = 0.5,
  index_tiles = 0.5,
  page_tiles = 0.5,
  data_border = 0.5, -- used for both page and index
  data_height = 0.5, -- used for both page and index
  bookmark_tab = 0.0,
}

--[[
  Calculates a value to determine its length by using the provided data.

  count: number of objects
  size: size of one object
  padding: amount to pad between each object

  returns the total length
]]
local function expand_with_pad(count, size, padding)
  return math.max(count, 0) * size + (math.max(count, 1) - 1) * padding
end

-- Exported Helpers
-------------------

--[[
  Calculates exact dimension information for rendering a guidebook formspec

  options: the guidebook options containing rendering information, see
    api/init.lua guidebooks.new

  returns a table containing dimension information
]]
local function calculate_exact_dimensions(options)
  local tile = 1 -- IDEA configure this through options?
  local index = {
    width =
      expand_with_pad(options.dimensions.index, tile, padding.index_tiles) +
      2 * padding.data_border,
    height =
      expand_with_pad(options.dimensions.height, tile, padding.data_height) +
      2 * padding.data_border
  }
  local page = {
    width = expand_with_pad(options.dimensions.page, tile, padding.page_tiles) +
      2 * padding.data_border,
    height = index.height
  }
  local scroll_bar = {
    width = tile + padding.scroll_bar * 2,
    height = index.height
  }
  local top_bar = {
    width = index.width + page.width + scroll_bar.width,
    height = 2
  }
  local bottom_bar = {
    width = top_bar.width,
    height = top_bar.height
  }
  local section_tab = {
    width = 2,
    height = 2
  }
  local bookmark_tab = {
    width = 3,
    height = 1
  }

  return {
    width = section_tab.width + top_bar.width + bookmark_tab.width,
    height = 2 * top_bar.height + index.height,
    index = index,
    page = page,
    scroll_bar = scroll_bar,
    top_bar = top_bar,
    bottom_bar = bottom_bar,
    section_tab = section_tab,
    bookmark_tab = bookmark_tab
  }
end

--[[
  Calculates the exact amount of bookmarks this guidebook will display.

  options: the guidebook options containing rendering information, see
    api/init.lua guidebooks.new
  dims: if you already calculated the guidebook exact dimensions, you can pass
    them in here to avoid extra processing

  returns the number of bookmarks this guidebook will display
]]
local function calculate_bookmark_count(options, dims)
  dims = dims or calculate_exact_dimensions(options)
  local max_supported = 0
  while true do
    local next = expand_with_pad(max_supported + 1, dims.bookmark_tab.height,
      padding.bookmark_tab)

    if next <= dims.index.height then
      max_supported = max_supported + 1
    else
      break
    end
  end
  return math.floor(math.min(max_supported, options.max.bookmarks))
end

--[[
  Calculates the exact amount of section tabs this guidebook will display.

  options: the guidebook options containing rendering information, see
    api/init.lua guidebooks.new
  dims: if you already calculated the guidebook exact dimensions, you can pass
    them in here to avoid extra processing

  returns the number of section tabs this guidebook will display
]]
local function calculate_section_count(options, dims)
  dims = dims or calculate_exact_dimensions(options)
  local max_supported = 0
  while true do
    local next = expand_with_pad(max_supported + 1, dims.section_tab.height,
      padding.section_tab)

    if next <= dims.index.height then
      max_supported = max_supported + 1
    else
      break
    end
  end
  return max_supported
end

-- Formspec Rendering Functions
-------------------------------

--[[
  Renders the formspec for the top bar of the guidebook.

  guidebook: the guidebook to render a top bar for
  dims: exact dimensions of entire guidebook, provided for convenience

  return the rendered formspec snippet
]]
local function render_top_bar(guidebook, context, dims)
  local textures = guidebook.options.textures
  local top_bar = stubs.top_bar

  -- Calculate some things ahead of time
  local left_button_x = dims.top_bar.width - 0.5 - 2 * padding.bar_spacing - 3
  local page_number_x = left_button_x + 1 + padding.bar_spacing
  local right_button_x = page_number_x + 2 + padding.bar_spacing

  -- Replace Parameters
  top_bar = top_bar:gsub('@BAR_WIDTH@', dims.top_bar)
  top_bar =
    top_bar:gsub('@TOP_BAR_BACKING@', textures.top_bar)
  top_bar = top_bar:gsub('@GUIDEBOOK_DISPLAY@', guidebook.display)
  top_bar = top_bar:gsub('@LEFT_BUTTON_X@', left_button_x)
  top_bar = top_bar:gsub('@ARROW_LEFT', textures.arrow_left)
  top_bar = top_bar:gsub('@PAGE_NUMBER_X@', page_number_x)
  top_bar = top_bar:gsub('@PAGE_NUMBER@', context.volatile.page)
  top_bar = top_bar:gsub('@RIGHT_BUTTON_X@', right_button_x)
  top_bar = top_bar:gsub('@ARROW_RIGHT@', textures.arrow_right)

  -- Return Formspec Bits
  return top_bar
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
local function render_guide(guidebook, context)
  local formspec = stubs.guidebook
  local dims = calculate_exact_dimensions(guidebook.options)

  -- Set Width and Height
  formspec = formspec:gsub('@WIDTH@', dims.width)
  formspec = formspec:gsub('@HEIGHT@', dims.height)

  -- TODO Set Background Texture
  formspec =
    formspec:gsub('@BACKGROUND@', guidebook.options.textures.background)

  -- Fill Containers
  local top_bar = render_top_bar(guidebook, context, dims)
  local section_tabs = render_section_tabs(--[[TODO args]])
  local scroll_bar = render_scroll_bar(--[[TODO args]])
  local index = render_index(--[[TODO args]])
  local page = render_page(--[[TODO args]])
  local bookmark_tabs = render_bookmark_tabs(--[[TODO args]])
  local bottom_bar = render_bottom_bar(--[[TODO args]])

  -- Apply Containers
  formspec = formspec:gsub('@TOP_BAR_CONTAINER@', top_bar)
  formspec = formspec:gsub('@SECTION_TAB_CONTAINER@', section_tabs)
  formspec = formspec:gsub('@SCROLL_BAR_CONTAINER@', scroll_bar)
  formspec = formspec:gsub('@INDEX_CONTAINER@', index)
  formspec = formspec:gsub('@PAGE_CONTAINER@', page)
  formspec = formspec:gsub('@BOOKMARK_CONTAINER@', bookmark_tabs)
  formspec = formspec:gsub('@BOTTOM_BAR_CONTAINER@', bottom_bar)

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
