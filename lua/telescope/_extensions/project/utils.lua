local Path = require('plenary.path')

local M = {}

-- The file path to telescope projects
M.telescope_projects_file = vim.fn.stdpath('data') .. '/telescope-projects.txt'
-- The file path to telescope workspaces
M.telescope_workspaces_file = vim.fn.stdpath('data') .. '/telescope-workspaces.txt'

-- Initialize file if does not exist
M.init_files = function()
  local projects_file_path = Path:new(M.telescope_projects_file)
  if not projects_file_path:exists() then
    projects_file_path:touch()
  end
  local workspaces_file_path = Path:new(M.telescope_workspaces_file)
  if not workspaces_file_path:exists() then
    workspaces_file_path:touch()
  end
end

-- Fetches project information to be passed to picker
M.get_projects = function()
  local filtered_projects = {}
  for _, project in pairs(M.get_project_objects()) do
    local is_activated = tonumber(project.activated) == 1
    if is_activated then
      table.insert(filtered_projects, project)
    end
  end
  table.sort(filtered_projects, function(a,b)
    return a.last_accessed > b.last_accessed
  end)
  return filtered_projects
end

-- Get project info for all (de)activated projects
M.get_project_objects = function()
  local projects = {}
  for line in io.lines(M.telescope_projects_file) do
    local project = M.parse_project_line(line)
    table.insert(projects, project)
  end
  return projects
end

-- Extract paths from all project objects
M.get_project_paths = function()
  local paths = {}
  for _, project in pairs(M.get_project_objects()) do
    table.insert(paths, project.path)
  end
  return paths
end

-- Extracts information from telescope projects line
M.parse_project_line = function(line)
  local title, path, workspace, activated = line:match("^(.-)=(.-)=(.-)=(.-)$")
  if not workspace then
    title, path = line:match("^(.-)=(.-)$")
    workspace = 'w0'
  end
  if not activated then
    title, path, workspace = line:match("^(.-)=(.-)=(.-)$")
    activated = 1
  end
  return {
    title = title,
    path = path,
    workspace = workspace,
    last_accessed = M.get_last_accessed_time(path),
    activated = activated
  }
end

-- Parses path into project object (activated by default)
M.get_project_from_path = function(path)
    -- `tostring` to use plenary path and paths defined as strings
    local title = tostring(path):match("[^/]+/?$")
    local workspace = 'w0'
    local activated = 1
    local line = title .. "=" .. path .. "=" .. workspace .. "=" .. activated
    return M.parse_project_line(line)
end

-- Checks the last time a directory was last accessed
M.get_last_accessed_time = function(path)
  local expanded_path = vim.fn.expand(path)
  local fs_stat = vim.loop.fs_stat(expanded_path)
  return fs_stat and fs_stat.atime.sec or 0
end

-- Standardized way of storing project to file
M.store_project = function(file, project)
  local line = project.title .. "=" .. project.path .. "=" .. project.workspace .. "=" .. project.activated .. "\n"
  file:write(line)
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

-- Check that string starts with given value
M.string_starts_with = function(text, start)
   return string.sub(text, 1, string.len(start)) == start
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
