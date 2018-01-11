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

--[[
  Determines which special sections are enabled for this guidebook.

  guidebook: the guidebook to test for special sections

  returns a tuple: (home_section is enabled, shared_section is enabled)
]]
local function special_sections_enabled(guidebook)
  local home_section = #guidebook.section_groups > 1
  local shared_section = guidebook.options.max.shared > 0
  return home_section, shared_section
end

local function generate_home_section(section_group)
  -- TODO
end

local function generate_shared_section(guidebook, context)
  -- TODO
end

--[[
  Gets the current section displayed by the context.  Accounts for the two
  special sections which are inserted into the beginning of the currently
  displayed section_group if necessary
]]
local function get_section(guidebook, context)
  local has_home_section, has_shared_section =
    special_sections_enabled(guidebook)
  local offset = (has_home_section and 1 or 0) + (has_shared_section and 1 or 0)

  local section_group = guidebook.section_groups[context.volatile.section_group]
  if offset == 0 then
    return section_group.sections[index]
  elseif offset == 1 then
    if has_home_section then
      return generate_home_section(section_group)
    else
      return generate_shared_section(guidebook, context)
    end
  elseif offset == 2 then
    return section_group.sections[context.volatile.section - offset]
  end
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
  context: the context for the player who the guidebook is being rendered for
  dims: exact dimensions of entire guidebook, provided for convenience

  returns the rendered formspec snippet
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

--[[
  Renders the section tabs.

  guidebook: the guidebook to render a top bar for
  context: the context for the player who the guidebook is being rendered for
  dims: exact dimensions of entire guidebook, provided for convenience

  returns the rendered formspec snippet
]]
local function render_section_tabs(guidebook, context, dims)
  local section_group = guidebook.section_groups[context.volatile.section_group]
  local home, shared = special_sections_enabled(guidebook)
  local special_tabs =  (home and 1 or 0) + (shared and 1 or 0)
  local max_tabs = calculate_section_count(guidebook.options, dims)
  local total_tabs = #section_group.sections + special_tabs
  local target = math.min(max_tabs, total_tabs)

  local formspec = 'container[0,' .. dims.top_bar.height .. ']'
  -- Render Up Arrow Button
  local x = dims.section_tab.width / 2 - 0.5
  local y = -1.5 -- move up from tabs a bit
  formspec = formspec .. 'image_button[' .. x .. ',' .. y .. ';1,1;' ..
    guidebooks.options.textures.arrow_up .. ';section_up;]'

  -- Render Tabs
  for i=1,target do
    local offset = context.volatile.scroll.section_group

    y = i * dims.section_tab.height
    local w = dims.section_tab.width
    local h = dims.section_tab.height

    formspec = formspec .. 'image[0,' .. y .. ';' .. w .. ',' .. h .. ';' ..
      guidebook.options.textures.section_tab .. ']'

    local tex_name, name
    if home and shared and offset <= 2 then
      if offset == 1 then
        tex_name = guidebook.options.textures.home_icon
        name = 'section_home'
      else
        tex_name = guidebook.options.textures.share_icon
        name = 'section_shared'
      end
    elseif home and offset == 1 then
      tex_name = guidebook.options.textures.home_icon
      name = 'section_home'
    elseif shared and offset == 1 then
      tex_name = guidebook.options.textures.share_icon
      name = 'section_shared'
    else
      local section = section_group.sections[offset - special_tabs]
      tex_name = section.icon
      name = 'section_user_' .. section.name
    end

    local x = padding.section_tab
    y = y + padding.section_tab
    w = dims.section_tab.width - 2 * padding.section_tab
    h = dims.section_tab.height - 2 * padding.section_tab
    formspec = formspec .. 'image_button[' .. x .. ',' .. y .. ';' ..
      w .. ',' .. h .. ';' .. tex_name .. ';' .. name .. ';]'
  end

  -- Render Down Arrow Button
  y = y + dims.section_tab.height + 0.5 -- y contains last section_tab y
  formspec = formspec .. 'image_button[' .. x .. ',' .. y .. ';1,1;' ..
    guidebooks.options.textures.arrow_down .. ';section_down;]'

  -- Close Formspec
  formspec = formspec .. 'container_end[]'

  return formspec
end

--[[
  Renders the scrollbar for the index panel.

  context: the context for the player who the guidebook is being rendered for
  dims: exact dimensions of entire guidebook, provided for convenience

  returns the rendered formspec snippet
]]
local function render_scroll_bar(context, dims)
  local x = dims.section_tab.width
  local y = dims.top_bar.height

  -- IDEA convert to stub?
  local formspec = 'container[' .. x .. ',' .. y .. ']' ..
    'scrollbar[' .. padding.scroll_bar .. ',' .. padding.scroll_bar .. ';' ..
    dims.scroll_bar.width .. ',' .. dims.scroll_bar.height .. ';vertical;' ..
    'scroll_index;' .. context.volatile.scroll.index .. ']' ..
    'container_end[]'
  return formspec
end

--[[
  Renders the index as a grid of tiles.

  section: the section defined in the guidebook via guidebooks.new
  context: the context for the player who the guidebook is being rendered for
  dims: exact dimensions of entire guidebook, provided for convenience

  returns a formspec representing the index.
]]
local function render_index_tiled(section, context, dims)
  -- TODO
end

--[[
  Renders the index as a set of rows with a tile icon and text.

  section: the section defined in the guidebook via guidebooks.new
  context: the context for the player who the guidebook is being rendered for
  dims: exact dimensions of entire guidebook, provided for convenience

  returns a formspec representing the index.
]]
local function render_index_tile_with_text(section, context, dims)
  -- TODO
end

--[[
  Renders the index as rows of text.

  section: the section defined in the guidebook via guidebooks.new
  context: the context for the player who the guidebook is being rendered for
  dims: exact dimensions of entire guidebook, provided for convenience

  returns a formspec representing the index.
]]
local function render_index_text(section, context, dims)
  -- TODO
end

--[[
  A quick lookup table for index style functions.
]]
local index_generators = {
  [1] = render_index_tiled,
  [2] = render_index_tile_with_text,
  [3] = render_index_text
}

--[[
  Renders an index for a section through delegation.

  guidebook: the guidebook to render a top bar for
  context: the context for the player who the guidebook is being rendered for
  dims: exact dimensions of entire guidebook, provided for convenience

  returns a formspec representing the index.
]]
local function render_index(guidebook, context, dims)
  local section = get_section(guidebook, context)
  return index_generators[section.index](section, context, dims)
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

  -- Set Background Texture
  formspec =
    formspec:gsub('@BACKGROUND@', guidebook.options.textures.background)

  -- Fill Containers
  local top_bar = render_top_bar(guidebook, context, dims)
  local section_tabs = render_section_tabs(guidebook, context, dims)
  local scroll_bar = render_scroll_bar(context, dims)
  local index = render_index(guidebook, context, dims)
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
