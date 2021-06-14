local builtin = require("telescope.builtin")
local actions = require("telescope.actions")
local transform_mod = require('telescope.actions.mt').transform_mod

local _git = require("telescope._extensions.project.git")
local _utils = require("telescope._extensions.project.utils")

local M = {}

-- Extracts project title from current buffer selection
M.get_selected_title = function(prompt_bufnr)
  return actions.get_selected_entry(prompt_bufnr).ordinal
end

-- Extracts project path from current buffer selection
M.get_selected_path = function(prompt_bufnr)
  return actions.get_selected_entry(prompt_bufnr).value
end

-- Create a new project and add it to the list in the `telescope_projects_file`
M.add_project = function()
  local path = _git.try_and_find_git_path()
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

-- Rename the selected project within the `telescope_projects_file`.
M.rename_project = function(prompt_bufnr)
  local selected_title = M.get_selected_title(prompt_bufnr)
  local new_title = vim.fn.input('Rename ' ..selected_title.. ' to: ', selected_title)
  local projects = _utils.get_project_objects()

  local file = io.open(_utils.telescope_projects_file, "w")
  for _, project in pairs(projects) do
    if project.title == selected_title then
      project.title = new_title
    end
    _utils.store_project(file, project)
  end

  io.close(file)
end

-- Delete (deactivate) the selected project from the `telescope_projects_file`
M.delete_project = function(prompt_bufnr)
  local projects = _utils.get_project_objects()
  local selected_title = M.get_selected_title(prompt_bufnr)

  local file = io.open(_utils.telescope_projects_file, "w")
  for _, project in pairs(projects) do
    if project.title == selected_title then
      project.activated = 0
    end
    _utils.store_project(file, project)
  end

  io.close(file)
  print('Project deleted: ' .. selected_title)
end

-- Find files within the selected project using the
-- Telescope builtin `find_files`.
M.find_project_files = function(prompt_bufnr)
  local dir = actions.get_selected_entry(prompt_bufnr).value
  actions._close(prompt_bufnr, true)
  vim.fn.execute("cd " .. dir, "silent")
  builtin.find_files({cwd = dir})
end

-- Browse through files within the selected project using
-- the Telescope builtin `file_browser`.
M.browse_project_files = function(prompt_bufnr)
  local dir = actions.get_selected_entry(prompt_bufnr).value
  actions._close(prompt_bufnr, true)
  vim.fn.execute("cd " .. dir, "silent")
  builtin.file_browser({cwd = dir})
end

-- Search within files in the selected project using
-- the Telescope builtin `live_grep`.
M.search_in_project_files = function(prompt_bufnr)
  local dir = actions.get_selected_entry(prompt_bufnr).value
  actions._close(prompt_bufnr, true)
  vim.fn.execute("cd " .. dir, "silent")
  builtin.live_grep({cwd = dir})
end

-- Search the recently used files within the selected project
-- using the Telescope builtin `oldfiles`.
M.recent_project_files = function(prompt_bufnr)
  local dir = actions.get_selected_entry(prompt_bufnr).value
  actions._close(prompt_bufnr, true)
  vim.fn.execute("cd " .. dir, "silent")
  builtin.oldfiles({cwd_only = true})
end

-- Change working directory to the selected project and close the picker.
M.change_working_directory = function(prompt_bufnr)
  local dir = actions.get_selected_entry(prompt_bufnr).value
  actions.close(prompt_bufnr)
  vim.fn.execute("cd " .. dir, "silent")
end

return transform_mod(M)
