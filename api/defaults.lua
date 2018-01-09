--[[
  This file is used to easily procure default values.
]]

-- Guidebook Options
--------------------

local options = {
  dimensions = {
    index = 4,
    page = 5,
    height = 5
  },

  textures = {
    arrow_left = 'guidebooks_arrow_left.png',
    arrow_right = 'guidebooks_arrow_right.png',
    arrow_up = 'guidebooks_arrow_up.png',
    arrow_down = 'guidebooks_arrow_down.png',
    share_icon = 'guidebooks_share_icon.png',
    bookmark_icon = 'guidebooks_bookmark_icon.png',
    section_tab = 'guidebooks_section_tab.png',
    bookmark_tab = 'guidebooks_bookmark_tab.png',
    top_bar = 'guidebooks_top_bar.png',
    bottom_bar = 'guidebooks_bottom_bar.png',
    scroll_bar_backing = 'guidebooks_scroll_bar_backing.png',
    index_backing = 'guidebooks_index_backing.png',
    page_backing = 'guideboks_page_backing.png',
  },

  max = {
    bookmarks = 5,
    shared = 15
  }
}

-- Return Defaults
------------------

return {
  options = options
}
