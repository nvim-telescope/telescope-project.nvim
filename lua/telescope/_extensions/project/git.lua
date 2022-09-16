local _utils = require("telescope._extensions.project.utils")
local iter = require("plenary.iterators")
local path = require("plenary.path")
local scan = require("plenary.scandir")

local M = {}

-- Find and store git repos if base_dirs provided
M.update_git_repos = function(base_dirs)
  if base_dirs then
    local normalized_config = _utils.normalize_base_dir_configs(base_dirs)
    local repo_paths  = M.search_for_git_repos(normalized_config)
    local git_projects = M.parse_git_repo_paths(repo_paths)
    M.save_git_repos(git_projects)
  end
end

-- Recurses directories under base directories to find all git projects
M.search_for_git_repos = function(base_dirs)
  return iter.iter(base_dirs)
    :map(function(base_dir)
      local git_dirs = scan.scan_dir(vim.fn.expand(base_dir.path), {
        depth = base_dir.max_depth,
        add_dirs = true,
        hidden = true,
        search_pattern = "%.git$"
      })
      return iter.iter(git_dirs)
        :map(function(git_dir) return path:new(git_dir):parent() end)
    end)
    :flatten()
    :tolist()
end

-- Reads tmp file, converting paths to projects
M.parse_git_repo_paths = function(repo_paths)
  return iter.iter(repo_paths)
    :map(function(repo_path) return _utils.get_project_from_path(repo_path) end)
    :tolist()
end

-- Write project to telescope projects file
M.save_git_repos = function(git_projects)
  local project_paths = _utils.get_project_paths()
  local file = io.open(_utils.telescope_projects_file, "a")

  for _, project in pairs(git_projects) do
    local path_exists = _utils.has_value(project_paths, project.path)
    if not path_exists then
      _utils.store_project(file, project)
    end
  end
  file:close()
end

-- Attempt to locate git directory, else return cwd
M.try_and_find_git_path = function()
  local git_cmd = "git -C " .. vim.loop.cwd() .. " rev-parse --show-toplevel"
  local git_root = tostring(vim.fn.systemlist(git_cmd)[1]):gsub(".*","")
  local git_root_fatal = _utils.string_starts_with(git_root, 'fatal')

  if not git_root or git_root_fatal then
    return vim.loop.cwd()
  end
  return git_root
end

return M
