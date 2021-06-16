-- telescope modules
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values

-- telescope-project modules
local _actions = require("telescope._extensions.project.actions")
local _finders = require("telescope._extensions.project.finders")
local _git = require("telescope._extensions.project.git")
local _utils = require("telescope._extensions.project.utils")

local M = {}

-- Variables that setup can change
local base_dir
local max_depth

-- Allow user to set base_dir and max_depth in setup
M.setup = function(setup_config)
  base_dir = setup_config.base_dir or nil
  max_depth = setup_config.max_depth or 3
  _git.update_git_repos(base_dir, max_depth)
end

-- This creates a picker with a list of all of the projects
M.project = function(opts)
  pickers.new(opts or {}, {
    prompt_title = 'Select a project',
    results_title = 'Projects',
    finder = _finders.project_finder(opts, _utils.get_projects()),
    sorter = conf.file_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)

      local refresh_projects = function()
        local picker = action_state.get_current_picker(prompt_bufnr)
        local finder = _finders.project_finder(opts, _utils.get_projects())
        picker:refresh(finder, { reset_prompt = true })
      end

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

return M
