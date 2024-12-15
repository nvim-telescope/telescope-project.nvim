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

---@class Config
---@field base_dirs nil | BaseDirSpec[] Array of project base directory configurations
---@field hidden_files boolean Show hidden files in selected project
---@field order_by OrderBy "recent", or alphabetically "asc" or "desc"
---@field on_project_selected fun(prompt_bufnr: number, hidden_files: boolean) Custom handler when project is selected
---@field hide_workspace boolean
---@field display_type string
---|"'full'"
---|"'minimal'" (default)
---@field search_by ProjectFieldName
---@field sync_with_nvim_tree boolean
---@field cd_scope table Array of cd scopes: tab, window, global
---@field theme string | nil a telescope theme name
---@field mappings table telescope-format table of mappings for the project telescope picker
local default_config = {
  base_dirs = nil,
  hidden_files = false,
  order_by = "recent",
  on_project_selected = _actions.find_project_files,
  hide_workspace = false,
  display_type = 'minimal',
  search_by = 'title',
  sync_with_nvim_tree = false,
  cd_scope = { "tab", "window" },
  theme = nil,
  mappings = {
    n = {
      ['d'] = _actions.delete_project,
      ['r'] = _actions.rename_project,
      ['c'] = _actions.add_project,
      ['C'] = _actions.add_project_cwd,
      ['f'] = _actions.find_project_files,
      ['b'] = _actions.browse_project_files,
      ['s'] = _actions.search_in_project_files,
      ['R'] = _actions.recent_project_files,
      ['w'] = _actions.change_working_directory,
      ['o'] = _actions.next_cd_scope,
    },
    i = {
      ['<c-d>'] = _actions.delete_project,
      ['<c-v>'] = _actions.rename_project,
      ['<c-a>'] = _actions.add_project,
      ['<c-A>'] = _actions.add_project_cwd,
      ['<c-f>'] = _actions.find_project_files,
      ['<c-b>'] = _actions.browse_project_files,
      ['<c-s>'] = _actions.search_in_project_files,
      ['<c-r>'] = _actions.recent_project_files,
      ['<c-l>'] = _actions.change_working_directory,
      ['<c-o>'] = _actions.next_cd_scope,
      ['<c-w>'] = _actions.change_workspace,
    },
  },
}

-- copy of default_config that setup can change
local config

-- Allow user to set base_dirs
local theme_opts = {}
M.setup = function(setup_config)
  config = vim.tbl_deep_extend('force', default_config, setup_config)
  if config.base_dir then
    error("'base_dir' is no longer a valid value for setup. See 'base_dirs'")
  end

  if config.theme and config.theme ~= "" then
    theme_opts = themes["get_" .. config.theme]()
  end
  _actions.set_cd_scope(config.cd_scope)
  _git.update_git_repos(config.base_dirs)
end

-- This creates a picker with a list of all of the projects
M.project = function(opts)
  opts = vim.tbl_deep_extend("force", theme_opts, config, opts or {})
  pickers.new(opts, {
    prompt_title = 'Select a project ' .. '(' .. _actions.get_cd_scope() .. ')',
    results_title = 'Projects',
    finder = _finders.project_finder(opts, _utils.get_projects(config.order_by)),
    sorter = conf.file_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      local refresh_projects = function()
        local picker = action_state.get_current_picker(prompt_bufnr)
        local finder = _finders.project_finder(opts, _utils.get_projects(config.order_by))
        picker:refresh(finder, { reset_prompt = true })
      end

      _actions.add_project:enhance({ post = refresh_projects })
      _actions.add_project_cwd:enhance({ post = refresh_projects })
      _actions.delete_project:enhance({ post = refresh_projects })
      _actions.rename_project:enhance({ post = refresh_projects })

      for mode, maps in pairs(config.mappings) do
        for keys, action in pairs(maps) do
          map(mode, keys, action)
        end
      end

      local handler = function()
        config.on_project_selected(prompt_bufnr, config.hidden_files)
      end
      actions.select_default:replace(handler)
      return true
    end
  }):find()
end

return M
