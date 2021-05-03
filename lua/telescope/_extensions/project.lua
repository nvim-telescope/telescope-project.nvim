local has_telescope, telescope = pcall(require, 'telescope')

if not has_telescope then
  error('This plugins requires nvim-telescope/telescope.nvim')
end

local actions = require("telescope.actions")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values
local entry_display = require("telescope.pickers.entry_display")
local utils = require("telescope.utils")

local project_actions = require("telescope._extensions.project_actions")

local project_dirs_file = vim.fn.stdpath('data') .. '/telescope-projects.txt'

local function check_for_project_dirs_file()
  local f = io.open(project_dirs_file, "r")
  if f ~= nil then
    io.close(f)
    return true
  else
    local newFile = io.open(project_dirs_file, "w")
    newFile:write()
    newFile:close()
  end
end

local select_project = function(opts, projects)
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
      widths[key] = math.max(value,utils.strdisplaywidth(entry[key] or ''))
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

  pickers.new(opts, {
    prompt_title = 'Select a project',
    results_title = 'Projects',
    finder = finders.new_table {
      results = projects,
      entry_maker = function(entry)
        entry.value = entry.path
        entry.ordinal = entry.title
        entry.display = make_display
        return entry
      end,
    },
    sorter = conf.file_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      map('n', 'd', project_actions.delete_project)
      map('n', 'r', project_actions.rename_project)
      map('n', 'c', project_actions.add_project)
      map('n', 'f', project_actions.find_project_files)
      map('n', 's', project_actions.search_in_project_files)
      map('n', 'w', project_actions.change_working_directory)
      local on_project_selected = function()
        project_actions.find_project_files(prompt_bufnr)
      end
      actions.select_default:replace(on_project_selected)
      return true
    end
  }):find()
end

local project = function(opts)
  opts = opts or {}

  check_for_project_dirs_file()
  local projects = {}

  -- format for projects is title of project=~/this/path/name
  for line in io.lines(project_dirs_file) do
    local title, path = line:match("^(.-)=(.-)$")
    table.insert(projects, {
      title = title,
      path = path,
    })
  end

  select_project(opts, projects)
end

return telescope.register_extension {exports = {project = project}}
