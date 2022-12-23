local finders = require("telescope.finders")
local Path = require('plenary.path')
local strings = require("plenary.strings")
local entry_display = require("telescope.pickers.entry_display")

local M = {}

-- Creates a Telescope `finder` based on the given options
-- and list of projects
M.project_finder = function(opts, projects)
  local display_type = opts.display_type
  local widths = {
    title = 0,
    display_path = 0,
  }

  -- Loop over all of the projects and find the maximum length of
  -- each of the keys
  for _, project in pairs(projects) do
    if display_type == 'full' then
      project.display_path = '[' .. project.path .. ']'
    elseif display_type == 'two-segment' then
      project.display_path = '[' .. string.match(project.path, '([^/]+/[^/]+)/?$') .. ']'
    else
      project.display_path = ''
    end
    local project_path_exists = Path:new(project.path):exists()
    if not project_path_exists then
      project.title = project.title .. " [deleted]"
    end
    for key, value in pairs(widths) do
      widths[key] = math.max(value, strings.strdisplaywidth(project[key] or ''))
    end
  end

  local displayer = entry_display.create {
    separator = " ",
    items = {
      { width = widths.title },
      { width = widths.workspace },
      { width = widths.display_path },
    }
  }
  local make_display = function(project)
    return displayer {
      { project.title },
      { project.workspace },
      { project.display_path }
    }
  end

  return finders.new_table {
      results = projects,
      entry_maker = function(project)
        project.value = project.path
        project.ordinal = project[search_by]
        project.display = make_display
        return project
      end,
    }
end

return M
