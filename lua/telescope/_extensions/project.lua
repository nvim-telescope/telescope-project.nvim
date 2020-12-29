local has_telescope, telescope = pcall(require, 'telescope')

if not has_telescope then
  error('This plugins requires nvim-telescope/telescope.nvim')
end

local actions = require("telescope.actions")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values

local project_actions = require("telescope._extensions.project_actions")

local project_dirs_file = vim.fn.stdpath('data') .. '/telescope-projects.txt'

require('telescope').setup {}

local function check_for_project_dirs_file()
  local f = io.open(project_dirs_file, "r")
  if f ~= nil then
    io.close(f)
    return true
  else
    print('Starting telescope-project')
    local newFile = io.open(project_dirs_file, "w")
    newFile:write()
    newFile:close()
  end
end

local select_project = function(opts, projects)
  pickers.new(opts, {
    prompt_title = 'Select a project',
    results_title = 'Projects',
    finder = finders.new_table {
      results = projects,
      entry_maker = function(entry)
        return {
          value = entry.path,
          display = entry.title,
          ordinal = entry.title,
        }
      end,
    },
    sorter = conf.file_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      map('n', 'd', project_actions.delete_project)
      map('n', 'c', project_actions.add_project)
      map('n', 'f', project_actions.find_project_files)
      local on_project_selected = function()
        project_actions.find_project_files(prompt_bufnr)
      end
      actions.goto_file_selection_edit:replace(on_project_selected)
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
