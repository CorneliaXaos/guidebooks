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
                    (will span an inventory tile)
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
          be nil
          {
            dimensions: table containing dimensions of the index and page areas
              {
                index = 4, -- width of the index section in displayed tiles
                page = 5, -- width of the page section in displayed tiles
                height = 5, -- height of both the index and page section
              }
            textures: table containing texture overrides to customize the
              visual appearance of the formspec
              {
                TODO
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
        show(player): shows this guidebook to the specified player
        receive(player, fields): should be called when receiving fields in
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
      -- TODO
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
