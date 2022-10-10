local builtin = require("telescope.builtin")
local actions = require("telescope.actions")
local actions_state = require("telescope.actions.state")
local transform_mod = require('telescope.actions.mt').transform_mod

local _git = require("telescope._extensions.project.git")
local _utils = require("telescope._extensions.project.utils")

local M = {}

-- Extracts project title from current buffer selection
M.get_selected_title = function(prompt_bufnr)
  return actions_state.get_selected_entry(prompt_bufnr).ordinal
end

-- Extracts project path from current buffer selection
M.get_selected_path = function(prompt_bufnr)
  return actions_state.get_selected_entry(prompt_bufnr).value
end


local add_project_to_list = function(path)
  local projects = _utils.get_project_objects()
  local path_not_in_projects = true

  local file = io.open(_utils.telescope_projects_file, "w")
  for _, project in pairs(projects) do
    if project.path == path then
      project.activated = 1
      path_not_in_projects = false
    end
    _utils.store_project(file, project)
  end

  if path_not_in_projects then
    local new_project = _utils.get_project_from_path(path)
    _utils.store_project(file, new_project)
  end

  io.close(file)
  print('Project added: ' .. path)
end

-- Create a new project based on current cwd only and add it 
-- to the list in the `telescope_projects_file`
M.add_project_cwd = function()
  local path = vim.loop.cwd()
  add_project_to_list(path)
end

-- Create a new project and add it to the list in the `telescope_projects_file`
M.add_project = function()
  local path = _git.try_and_find_git_path()
  add_project_to_list(path)
end

-- Rename the selected project within the `telescope_projects_file`.
M.rename_project = function(prompt_bufnr)
  local selected_path = M.get_selected_path(prompt_bufnr)
  local selected_title = M.get_selected_title(prompt_bufnr)
  local new_title = vim.fn.input('Rename ' ..selected_title.. ' to: ', selected_title)
  local projects = _utils.get_project_objects()

  local file = io.open(_utils.telescope_projects_file, "w")
  for _, project in pairs(projects) do
    if project.path == selected_path then
      project.title = new_title
    end
    _utils.store_project(file, project)
  end

  io.close(file)
end

-- Change the selected projects workspace within the `telescope_projects_file`.
M.change_workspace = function(prompt_bufnr)
  local selected_path = M.get_selected_path(prompt_bufnr)
  local projects = _utils.get_project_objects()
  local new_workspace = vim.fn.input('Move project to workspace: ')

  local file = io.open(_utils.telescope_projects_file, "w")
  for _, project in pairs(projects) do
    if project.path == selected_path then
      project.workspace = 'w' .. new_workspace
    end
    _utils.store_project(file, project)
  end

  io.close(file)
end


-- Delete (deactivate) the selected project from the `telescope_projects_file`
M.delete_project = function(prompt_bufnr)
  local projects = _utils.get_project_objects()
  local selected_path = M.get_selected_path(prompt_bufnr)

  local file = io.open(_utils.telescope_projects_file, "w")
  for _, project in pairs(projects) do
    if project.path == selected_path then
      project.activated = 0
    end
    _utils.store_project(file, project)
  end

  io.close(file)
  print('Project deleted: ' .. selected_path)
end

-- Find files within the selected project using the
-- Telescope builtin `find_files`.
M.find_project_files = function(prompt_bufnr, hidden_files)
  local project_path = M.get_selected_path(prompt_bufnr)
  actions._close(prompt_bufnr, true)
  local cd_successful = _utils.change_project_dir(project_path)
  if cd_successful then
    vim.schedule(function()
      builtin.find_files({cwd = project_path, hidden = hidden_files})
    end)
  end
end

-- Browse through files within the selected project using
-- the Telescope builtin `file_browser`.
M.browse_project_files = function(prompt_bufnr)
  local ok, file_browser = pcall(require, "telescope._extensions.file_browser")
  if not ok then
    vim.notify( "telescope-file-browser.nvim is required to use this action!", vim.log.levels.ERROR, { title = "telescope-project.nvim" })
    return
  end
  local project_path = M.get_selected_path(prompt_bufnr)
  actions._close(prompt_bufnr, true)
  local cd_successful = _utils.change_project_dir(project_path)
  if cd_successful then
    vim.schedule(function()
      file_browser.exports.file_browser({ cwd = project_path })
    end)
  end
end

-- Search within files in the selected project using
-- the Telescope builtin `live_grep`.
M.search_in_project_files = function(prompt_bufnr)
  local project_path = M.get_selected_path(prompt_bufnr)
  actions._close(prompt_bufnr, true)
  local cd_successful = _utils.change_project_dir(project_path)
  if cd_successful then
    vim.schedule(function()
      builtin.live_grep({cwd = project_path})
    end)
  end
end

-- Search the recently used files within the selected project
-- using the Telescope builtin `oldfiles`.
M.recent_project_files = function(prompt_bufnr)
  local project_path = M.get_selected_path(prompt_bufnr)
  actions._close(prompt_bufnr, true)
  local cd_successful = _utils.change_project_dir(project_path)
  if cd_successful then
    vim.schedule(function()
      builtin.oldfiles({cwd_only = true})
    end)
  end
end

-- Change working directory to the selected project and close the picker.
M.change_working_directory = function(prompt_bufnr)
  local project_path = M.get_selected_path(prompt_bufnr)
  actions.close(prompt_bufnr)
  _utils.change_project_dir(project_path)
end

return transform_mod(M)
