local _utils = require("telescope._extensions.project.utils")

local M = {}

-- Temporary store for git repo list
M.tmp_path = "/tmp/found_projects.txt"

-- Find and store git repos if base_dir provided
M.update_git_repos = function(base_dir, max_depth)
  if base_dir then
    M.search_for_git_repos(base_dir, max_depth)
    local git_projects = M.parse_git_repo_paths()
    M.save_git_repos(git_projects)
  end
end

-- Recurses directories under base directory to find all git projects
M.search_for_git_repos = function(base_dir, max_depth)
  local max_depth_arg = " -maxdepth " .. max_depth
  local find_args = " -type d -name .git -printf '%h\n'"
  local shell_cmd = "find " .. base_dir .. max_depth_arg .. find_args
  os.execute(shell_cmd .. " > " .. M.tmp_path)
end

-- Reads tmp file, converting paths to projects
M.parse_git_repo_paths = function()
  local git_projects = {}
  for path in io.lines(M.tmp_path) do
    local project = _utils.get_project_from_path(path)
    table.insert(git_projects, project)
  end
  return git_projects
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
  local git_root = vim.fn.systemlist(git_cmd)[1]
  local git_root_fatal = _utils.string_starts_with(git_root, 'fatal')

  if not git_root or git_root_fatal then
    return vim.loop.cwd()
  end
  return git_root
end

return M
