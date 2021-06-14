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
  for _, project in pairs(projects) do
    if display_type == 'full' then
      project.display_path = '[' .. project.path .. ']'
    else
      project.display_path = ''
    end
    for key, value in pairs(widths) do
      widths[key] = math.max(value, utils.strdisplaywidth(project[key] or ''))
    end
  end

  local displayer = entry_display.create {
    separator = " ",
    items = {
      { width = widths.title },
      { width = widths.dir },
    }
  }
  local make_display = function(project)
    return displayer {
      { project.title },
      { project.display_path }
    }
  end

  return finders.new_table {
      results = projects,
      entry_maker = function(project)
        project.value = project.path
        project.ordinal = project.title
        project.display = make_display
        return project
      end,
    }
end

return M
