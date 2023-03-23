-- telescope modules
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values
local themes = require "telescope.themes"

-- telescope-project modules
local _actions = require("telescope._extensions.project.actions")
local _finders = require("telescope._extensions.project.finders")
local _git = require("telescope._extensions.project.git")
local _utils = require("telescope._extensions.project.utils")

local M = {}

-- Variables that setup can change
local base_dirs
local hidden_files
local order_by
local on_project_selected

-- Allow user to set base_dirs
local theme_opts = {}
M.setup = function(setup_config)

  if setup_config.base_dir then
    error("'base_dir' is no longer a valid value for setup. See 'base_dirs'")
  end

  if setup_config.theme and setup_config.theme ~= "" then
    theme_opts = themes["get_" .. setup_config.theme]()
  end

  base_dirs = setup_config.base_dirs or nil
  hidden_files = setup_config.hidden_files or false
  order_by = setup_config.order_by or "recent"
  on_project_selected = setup_config.on_project_selected
  search_by = setup_config.search_by or "title"
  sync_with_nvim_tree = setup_config.sync_with_nvim_tree or false
  _git.update_git_repos(base_dirs)
end

-- This creates a picker with a list of all of the projects
M.project = function(opts)
  opts = vim.tbl_deep_extend("force", theme_opts, opts or {})
  pickers.new(opts, {
    prompt_title = 'Select a project',
    results_title = 'Projects',
    finder = _finders.project_finder(opts, _utils.get_projects(order_by)),
    sorter = conf.file_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)

      local refresh_projects = function()
        local picker = action_state.get_current_picker(prompt_bufnr)
        local finder = _finders.project_finder(opts, _utils.get_projects(order_by))
        picker:refresh(finder, { reset_prompt = true })
      end

      _actions.add_project:enhance({ post = refresh_projects })
      _actions.add_project_cwd:enhance({ post = refresh_projects })
      _actions.delete_project:enhance({ post = refresh_projects })
      _actions.rename_project:enhance({ post = refresh_projects })

      -- Project key mappings
      map('n', 'd', _actions.delete_project)
      map('n', 'r', _actions.rename_project)
      map('n', 'c', _actions.add_project)
      map('n', 'C', _actions.add_project_cwd)
      map('n', 'f', _actions.find_project_files)
      map('n', 'b', _actions.browse_project_files)
      map('n', 's', _actions.search_in_project_files)
      map('n', 'R', _actions.recent_project_files)
      map('n', 'w', _actions.change_working_directory)

      map('i', '<c-d>', _actions.delete_project)
      map('i', '<c-v>', _actions.rename_project)
      map('i', '<c-a>', _actions.add_project)
      map('i', '<c-A>', _actions.add_project_cwd)
      map('i', '<c-f>', _actions.find_project_files)
      map('i', '<c-b>', _actions.browse_project_files)
      map('i', '<c-s>', _actions.search_in_project_files)
      map('i', '<c-r>', _actions.recent_project_files)
      map('i', '<c-l>', _actions.change_working_directory)

      -- Workspace key mappings
      map('i', '<c-w>', _actions.change_workspace)

      local handler = function()
        if on_project_selected then
          on_project_selected(prompt_bufnr)
        else
          _actions.find_project_files(prompt_bufnr, hidden_files)
        end
      end
      actions.select_default:replace(handler)
      return true
    end
  }):find()
end

return M
