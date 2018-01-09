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

--[[
  Creates a new guidebook.  The guidebook is not registered into the system
  automatically in case the developer wishes to manually handle faculties
  such as recipe and item registration.

  definition:
    {
      name: the unique string identifying this guidebook (i.e. 'mymod:guide'),
      display: the string used in the display of this guidebook,
      section_groups: table containing groups of sections used for configuring
        the section tabs; only one section group is displayed at a time; at
        least ONE is required
        {
          {
            name: a string name for the section_group (i.e. Beginner)
            sections: a table of sections
              {
                { -- a section
                  name: string name of section (i.e. Getting Started)
                  icon: image icon used to visually identify section
                    (will span an inventory tile or so, is square9)
                  index: an integer that's either...
                    1, (index entries are tiled images)
                    2, (index entry is an image with text occupying a line)
                    3, (index entry is a line of text)
                  page_groups: table containing groups of pages, each page
                    group gets an entry in the index
                    {
                      { -- a page group
                        name: string name of the page group (i.e. How To Build)
                        pages: a table containing page generating functions;
                          each function returns a snippet of formspec code used
                          to render the page; the function is of the form:
                          function(name_of_page_group, index, guidebook_options)
                          where guidebook_options is the options table that is
                          attached to the returned guidebook
                          {
                            [1] = get_formspec,
                            [2] = get_formspec,
                            more 'pages', etc.
                          }
                      }
                    }
                },
                more sections, etc.
              }
            },
          more section groups, etc.
        }
        options: a table containing customization options for the guidebook;
          this options table is different from the one used when registering
          the guidebook; everything wihtin this table is optional unless
          otherwise stated; additionally, these are only REQUESTS, if the api
          cannot honor them they will be adjusted when appropriate; the adjusted
          options are returned attached to the guidebook table even if this
          table wasn't provided (the defaults are used, then); this field may
          be nil; this function modifies the passed in table!
          {
            dimensions: table containing dimensions of the index and page areas
              these values do NOT include padding so the end result MAY be
              larger!
              {
                index = 4, -- number of displayed, horizontal tiles in the index
                page = 5, -- number of displayed, horizontal tiles along a page
                height = 5, -- number of displayed, vertical tiles in both
              }
            textures: table containing texture overrides to customize the
              visual appearance of the formspec
              {
                background: a background image spanning the entire formspec
                arrow_left: arrow icon pointing to the left
                arrow_right: arrow icon pointing to the right
                arrow_up: arrow icon pointing up
                arrow_down: arrow icon pointing down
                share_icon: button icon for sharing
                bookmark_icon: button icon for bookmarking
                section_tab: section tab backing
                bookmark_tab: bookmark tab backing
                top_bar: top bar backing (contains name, and page controls)
                bottom_bar: bottom bar backing (contains search bar and other
                  controls)
                scroll_bar_backing: backing image for behind the scrollbar
                  controlling the index
                index_backing: backing image for behind the index
                page_backing: backing image for behind the page
              }
            max: table containing limits on certain functions, actual values
              may be less than requested
              {
                bookmarks = 5,
                shared = 15, -- limit on list of last shared pages, older pages
                  are removed
              }
          }
    }

  returns the created guidebook which is a table with the following properties:
    {
      -- defintion information, see above
      name,
      display,
      section_groups,
      options,

      -- additional information
      context: table containing state-based information for the guidebook;
        you can use this to perform housekeeping of your own; guidebooks will
        also use this same table and specific fields are outlined below when
        present and probably shouldn't be modified by hand
        {
          ["player_name"]: a table identifying the context for a particular
            player by name; i.e. the context for a player named "Cornelia" can
            be obtained by accessing: `myguidebook.context["Cornelia"]`
            {
              volatile: context table of information that is lost between
                user sessions and server sessions
                {
                  open: is the player viewing the guidebook?
                  section_group: index of active section group
                  section: index of active section within the group
                  page_group: index of active page_group within section
                  page: index of active page within page group
                  scroll: table containing scrolling information
                    {
                      section_group: index offset inside sections for scrolling
                      index: scroll value for index scrollbar
                    }
                }
              persist: context table containing information that guidebooks
                will preserve between user sessions and server sessions; since
                this data will be written using internal minetest functions it
                must not contain any function references or userdata;
                additionally, this feature only functions properly if the
                guidebook has been registered with the API using
                `guidebooks.register`
                {
                  bookmarks: table of bookmarks saved by the user, string names
                    are used to identify the section_group, section, and
                    page_group that were bookmarked as indices may change when
                    the developer updates their guidebooks.  Pages within a page
                    group are not bookmarkable since they should not contain
                    data that is that granular; create a separate section /
                    page_group for those (that's why those layers exist!)
                    {
                      { -- a bookmark
                        section_group: name of group,
                        section: name of section,
                        page_group: name of page_group,
                      },
                      more bookmarks, etc.
                    }
                  shared: table containing pages that were shared to this user;
                    only contains the last N pages as specified by the options
                    {
                      { -- a shared page
                        section_group: name of group,
                        section: name of section,
                        page_group: name of page_group
                      },
                      more shared pages, etc.
                    }
                }
            }
        }

        -- functions
        show(player_name, formname): shows this guidebook to a specified player
        receive(player_name, fields): should be called when receiving fields in
          order to handle guidebook specific functions, returns true if it
          handled something (and there's probably nothing left to do), false
          otherwise
    }
]]
guidebooks.new--[[(definition)]] = implementation.new

--[[
  Registers a guidebook with the management api.  Registered books go through
  a common system for creating the crafting recipes and items for the books
  allowing guidebooks to handle compatibility between other mods.  Guides don't
  need to be registered if the developer wishes to handle these things
  themselves.

  guidebook:  the guidebook created by a call to `guidebooks:new`
  options:
    {
      recipeitem: a string identifying a single item to combine with the
        (compatibility determined) book item in a shapeless recipe; for
        example, if creating a guidebook about wood, the item might be
        'default:wood', in which case the API would likely generate a recipe
        involving 'default:book' and 'default:wood' (since your mod would
        rely on the default mod; this mod can function WITHOUT default and
        may use a different 'book' item as the crafting base)
      craftitem: an OPTIONAL string indicating the name of the craftitem
        produced when a player crafts this guidebook (i.e. 'mymod:guide');
        if one is not provided the API attempts to use the name of the
        guidebook itself (i.e. `guidebook.name`); THE DEVELOPER SHOULD NOT
        REGISTER THIS CRAFTITEM WITH MINETEST, the API will handle that.
      description: an OPTIONAL string to use as the description for this guide;
        if not provided, than the following is used:
        `guidebook.name .. ': A Guide'`
      inventory_image: an OPTIONAL image string for identifying the texture to
        use as this item's inventory_image.  If one is not provided, a default
        one from within guidebooks is used.
      definition: an OPTIONAL table used for registering the entire craftitem;
        allows developers to set complex craftitem options; the entries within
        this table can be overwritten by the ones above.  Note that the "on_use"
        parameter is IGNORED.  Use the below `use_callback` option for
        specifying custom logic.
      formname: an OPTIONAL string overriding the Formspec formname for this
        guidebook; the API uses the guidebook's name by default.
      use_callback: an OPTIONAL function callback to call before the guidebook
        is displayed to the user; this function MUST return a boolean indicating
        if guidebooks should show the guidebook or not.
    }

  returns true if the registration was successful, false otherwise.
]]
guidebooks.register--[[(guidebook, options)]] = implementation.register

--[[
  Unregisters a guidebook that was previously registered.

  identifier: either...
    - a string identifying the name of the guidebook, or...
    - the guidebook table itself

  returns true if the guidebook was previously registered and was successfully
    unregistered, false otherwise.
]]
guidebooks.unregister--[[(identifier)]] = implementation.unregister

--[[
  Locates a registered guidebook via the name it was registered with.

  name: the string identifying the guidebook

  returns the guidebook table, or nil if no guidebook was found.
]]
guidebooks.locate--[[(name)]] = implementation.locate

-- Package Finalization
-----------------------

return guidebooks
