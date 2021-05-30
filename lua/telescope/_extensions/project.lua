local has_telescope, telescope = pcall(require, 'telescope')

if not has_telescope then
  error('This plugins requires nvim-telescope/telescope.nvim')
end

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values
local entry_display = require("telescope.pickers.entry_display")
local utils = require("telescope.utils")

local project_actions = require("telescope._extensions.project_actions")

local project_dirs_file = vim.fn.stdpath('data') .. '/telescope-projects.txt'

-- Checks if the file containing the list of project
-- directories already exists.
-- If it doesn't exist, it creates it.
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

-- Creates a Telescope `finder` based on the given options
-- and list of projects
local create_finder = function(opts, projects)
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

local get_last_accessed_time = function(path)
  local expanded_path = vim.fn.expand(path)
  local fs_stat = vim.loop.fs_stat(expanded_path)
  if fs_stat then
    return fs_stat.atime.sec
  else
    return 0
  end
end

-- Get information on all of the projects in the
-- `project_dirs_file` and output it as a list
local get_projects = function()
  check_for_project_dirs_file()
  local projects = {}

  for line in io.lines(project_dirs_file) do
    local title, path = line:match("^(.-)=(.-)$")
    local last_accessed = get_last_accessed_time(path)
    table.insert(projects, {
      title = title,
      path = path,
      last_accessed = last_accessed
    })
  end

  table.sort(projects, function(a,b)
    return a.last_accessed > b.last_accessed
  end)

  return projects
end

-- The main function.
-- This creates a picker with a list of all of the projects,
-- and attaches the appropriate mappings for associated
-- actions.
local project = function(opts)
  opts = opts or {}

  local projects = get_projects()
  local new_finder = create_finder(opts, projects)

  pickers.new(opts, {
    prompt_title = 'Select a project',
    results_title = 'Projects',
    finder = new_finder,
    sorter = conf.file_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      local refresh_projects = function()
        local picker = action_state.get_current_picker(prompt_bufnr)
        picker:refresh(create_finder(opts,get_projects()), {reset_prompt=true})
      end
      project_actions.add_project:enhance({ post = refresh_projects })
      project_actions.delete_project:enhance({ post = refresh_projects })
      project_actions.rename_project:enhance({ post = refresh_projects })

      map('n', 'd', project_actions.delete_project)
      map('n', 'r', project_actions.rename_project)
      map('n', 'c', project_actions.add_project)
      map('n', 'f', project_actions.find_project_files)
      map('n', 'b', project_actions.browse_project_files)
      map('n', 's', project_actions.search_in_project_files)
      map('n', 'R', project_actions.recent_project_files)
      map('n', 'w', project_actions.change_working_directory)
      local on_project_selected = function()
        project_actions.find_project_files(prompt_bufnr)
      end
      actions.select_default:replace(on_project_selected)
      return true
    end
  }):find()
end

return telescope.register_extension {exports = {project = project}}
