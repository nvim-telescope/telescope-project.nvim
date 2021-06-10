local has_telescope, telescope = pcall(require, 'telescope')

if not has_telescope then
  error('This plugins requires nvim-telescope/telescope.nvim')
end

-- telescope modules
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values

-- project telescope modules
local _actions = require("telescope._extensions.actions")
local _finders = require("telescope._extensions.finders")
local _utils = require("telescope._extensions.utils")

-- initialize telescope project file
if not _utils.file_exists(_utils.telescope_projects_file) then
  local newFile = io.open(_utils.telescope_projects_file, "w")
  newFile:write()
  newFile:close()
end

-- The main function.
-- This creates a picker with a list of all of the projects,
-- and attaches the appropriate mappings for associated
-- actions.
local project = function(opts)
  pickers.new(opts or {}, {
    prompt_title = 'Select a project',
    results_title = 'Projects',
    finder = _finders.project_finder(opts, _utils.get_projects()),
    sorter = conf.file_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)

      local refresh_projects = function()
        local picker = action_state.get_current_picker(prompt_bufnr)
        picker:refresh(_finders.project_finder(opts, _utils.get_projects()), {reset_prompt=true})
      end

      _utils.update_git_repos(opts)
      _actions.add_project:enhance({ post = refresh_projects })
      _actions.delete_project:enhance({ post = refresh_projects })
      _actions.rename_project:enhance({ post = refresh_projects })

      map('n', 'd', _actions.delete_project)
      map('n', 'r', _actions.rename_project)
      map('n', 'c', _actions.add_project)
      map('n', 'f', _actions.find_project_files)
      map('n', 'b', _actions.browse_project_files)
      map('n', 's', _actions.search_in_project_files)
      map('n', 'R', _actions.recent_project_files)
      map('n', 'w', _actions.change_working_directory)

      local on_project_selected = function()
        _actions.find_project_files(prompt_bufnr)
      end
      actions.select_default:replace(on_project_selected)
      return true
    end
  }):find()
end

return telescope.register_extension{ exports = { project = project }}
