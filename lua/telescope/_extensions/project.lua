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
      map('n', 'r', project_actions.rename_project)
      map('n', 'c', project_actions.add_project)
      map('n', 'f', project_actions.find_project_files)
      map('n', 's', project_actions.search_in_project_files)
      map('n', 'w', project_actions.change_working_directory)
      local on_project_selected = function()
        project_actions.find_project_files(prompt_bufnr, opts.change_dir)
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

  for line in io.lines(project_dirs_file) do
    local title, path = line:match("^(.-)=(.-)$")
    local last_accessed = vim.loop.fs_stat(path).atime.sec
    table.insert(projects, {
      title = title,
      path = path,
      last_accessed = last_accessed
    })
  end

  table.sort(projects, function(a,b) 
    return a.last_accessed > b.last_accessed
  end)

  select_project(opts, projects)
end

return telescope.register_extension {exports = {project = project}}
