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
    local display_path = project.path:gsub('\n', '\\n') -- otherwise the picker might not open due to a 'Cursor position outside buffer' error
    if display_type == 'full' then
      project.display_path = '[' .. display_path .. ']'
    elseif display_type == 'two-segment' then
      project.display_path = '[' .. string.match(display_path, '([^/]+/[^/]+)/?$') .. ']'
    else
      project.display_path = ''
    end
    project.display_title = project.title:gsub('\n', '\\n')
    local project_path_exists = Path:new(project.path):exists()
    if not project_path_exists then
      project.display_title = project.display_title .. " [deleted]"
    end
    for key, value in pairs(widths) do
      widths[key] = math.max(value, strings.strdisplaywidth(project[key] or ''))
    end
  end

  local create_opts = {
    separator = " ",
    items = {
      { width = widths.title },
      { width = widths.display_path },
    }
  }

  local displayer = entry_display.create(create_opts)
  local make_display = function(project)
    local display_opts = {
      { project.display_title },
      { project.display_path }
    }

    return displayer(display_opts)
  end

  return finders.new_table {
      results = projects,
      entry_maker = function(project)
        project.value = project.path
        if type(search_by) == "string" then
          project.ordinal = project[search_by]
        end
        if type(search_by) == "table" then
          project.ordinal = ""
          for _, property in ipairs(search_by) do
            project.ordinal = project.ordinal .. " " .. project[property]
          end
        end
        project.display = make_display
        return project
      end,
    }
end

return M
