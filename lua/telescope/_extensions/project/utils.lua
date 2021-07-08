local Path = require('plenary.path')

local M = {}

-- Get project info for all (de)activated projects
M.get_project_objects = function()
  local projects = {}
  for line in io.lines(M.telescope_projects_file) do
    local project = M.parse_project_line(line)
    table.insert(projects, project)
  end
  return projects
end

-- Checks the last time a directory was last accessed
M.get_last_accessed_time = function(path)
  local expanded_path = vim.fn.expand(path)
  local fs_stat = vim.loop.fs_stat(expanded_path)
  return fs_stat and fs_stat.atime.sec or 0
end

-- Trim whitespace for strings
M.trim = function(s)
  return s:match( "^%s*(.-)%s*$" )
end

-- Check if value exists in table
M.has_value = function(tbl, val)
  for _, value in ipairs(tbl) do
    if M.trim(value) == M.trim(val) then
      return true
    end
  end
  return false
end

-- Change directory only when path exists
M.change_project_dir = function(project_path)
  if Path:new(project_path):exists() then
    vim.fn.execute("cd " .. project_path, "silent")
    return true
  else
    print("The path '" .. project_path .. "' does not exist")
    return false
  end
end

-- Normalize the base_dirs configurations
M.normalize_base_dir_configs = function(base_dirs)
  local normalize_path = function(dir)
    if type(dir) == "table" then
      return dir[1] or dir.path
    else -- string
      return dir
    end
  end
  local normalize_max_depth = function(dir)
    if type(dir) == "table" then
      return dir.max_depth or 3
    else
      return 3
    end
  end
  local normalized_base_dir_configs = {}
  for _, dir in ipairs(base_dirs) do
    table.insert(normalized_base_dir_configs, {
        path = normalize_path(dir),
        max_depth = normalize_max_depth(dir)
      })
  end
  return normalized_base_dir_configs
end

return M
