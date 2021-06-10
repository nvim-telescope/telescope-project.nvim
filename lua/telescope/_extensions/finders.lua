local finders = require("telescope.finders")
local utils = require("telescope.utils")
local entry_display = require("telescope.pickers.entry_display")

local M = {}

-- Creates a Telescope `finder` based on the given options
-- and list of projects
M.project_finder = function(opts, projects)
  local display_type = opts.display_type
  local widths = {
    title = 0,
    dir = 0,
  }

  -- Loop over all of the projects and find the maximum length of
  -- each of the keys
  for _,entry in pairs(projects) do
    if display_type == 'full' then
      entry.dir = '[' .. entry.path .. ']'
    else
      entry.dir = ''
    end
    for key, value in pairs(widths) do
      widths[key] = math.max(value, utils.strdisplaywidth(entry[key] or ''))
    end
  end

  local displayer = entry_display.create {
    separator = " ",
    items = {
      { width = widths.title },
      { width = widths.dir },
    }
  }
  local make_display = function(entry)
    return displayer {
      { entry.title },
      { entry.dir }
    }
  end

  return finders.new_table {
      results = projects,
      entry_maker = function(entry)
        entry.value = entry.path
        entry.ordinal = entry.title
        entry.display = make_display
        return entry
      end,
    }
end

return M
