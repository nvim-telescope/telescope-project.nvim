local builtin = require("telescope.builtin")
local actions = require("telescope.actions")
local transform_mod = require('telescope.actions.mt').transform_mod
local _utils = require("telescope._extensions.project.utils")
local _project = require("project")
local init_project_from_path = require("project.utils").init_project_from_path
local iter = require("plenary.iterators").iter

local M = {}

-- Extracts project title from current buffer selection
M.get_selected_title = function(prompt_bufnr)
  return actions.get_selected_entry(prompt_bufnr).ordinal
end

-- Extracts project path from current buffer selection
M.get_selected_path = function(prompt_bufnr)
  return actions.get_selected_entry(prompt_bufnr).value
end

-- Create a new project and add it to the list in the `projects_file`
M.add_project = function()
  local path = _project.get_root()
  local project = init_project_from_path(path)
  _project.add_projects({project})
  print('Project added: ' .. path)
end

-- Rename the selected project within the `projects_file`.
M.rename_project = function(prompt_bufnr)
  local selected_path = M.get_selected_path(prompt_bufnr)
  local selected_title = M.get_selected_title(prompt_bufnr)
  local new_title = vim.fn.input('Rename ' ..selected_title.. ' to: ', selected_title)
  local projects = _project.read_projects()
  local selected_project = iter(projects):find(function(p) return p.path == selected_path end)
  selected_project.title = new_title
  _project.write_projects(projects)
end

-- Delete (deactivate) the selected project from the `projects_file`
M.delete_project = function(prompt_bufnr)
  local projects = _project.read_projects()
  local selected_path = M.get_selected_path(prompt_bufnr)
  local selected_project = iter(projects):find(function(p) return p.path == selected_path end)
  selected_project.activated = false
  _project.write_projects(projects)
  print('Project deleted: ' .. selected_path)
end

-- Find files within the selected project using the
-- Telescope builtin `find_files`.
M.find_project_files = function(prompt_bufnr)
  local project_path = M.get_selected_path(prompt_bufnr)
  actions._close(prompt_bufnr, true)
  local cd_successful = _utils.change_project_dir(project_path)
  if cd_successful then builtin.find_files({cwd = project_path}) end
end

-- Browse through files within the selected project using
-- the Telescope builtin `file_browser`.
M.browse_project_files = function(prompt_bufnr)
  local project_path = M.get_selected_path(prompt_bufnr)
  actions._close(prompt_bufnr, true)
  local cd_successful = _utils.change_project_dir(project_path)
  if cd_successful then builtin.file_browser({cwd = project_path}) end
end

-- Search within files in the selected project using
-- the Telescope builtin `live_grep`.
M.search_in_project_files = function(prompt_bufnr)
  local project_path = M.get_selected_path(prompt_bufnr)
  actions._close(prompt_bufnr, true)
  local cd_successful = _utils.change_project_dir(project_path)
  if cd_successful then builtin.live_grep({cwd = project_path}) end
end

-- Search the recently used files within the selected project
-- using the Telescope builtin `oldfiles`.
M.recent_project_files = function(prompt_bufnr)
  local project_path = M.get_selected_path(prompt_bufnr)
  actions._close(prompt_bufnr, true)
  local cd_successful = _utils.change_project_dir(project_path)
  if cd_successful then builtin.oldfiles({cwd_only = true}) end
end

-- Change working directory to the selected project and close the picker.
M.change_working_directory = function(prompt_bufnr)
  local project_path = M.get_selected_path(prompt_bufnr)
  actions.close(prompt_bufnr)
  _utils.change_project_dir(project_path)
end

return transform_mod(M)
