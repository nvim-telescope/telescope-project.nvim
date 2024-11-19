local Path = require('plenary.path')
local Project = require("telescope._extensions.project.project")

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
M.get_projects = function(order_by)
  local filtered_projects = {}
  for _, project in pairs(M.get_project_objects()) do
    local is_activated = tonumber(project.activated) == 1
    if is_activated then
      table.insert(filtered_projects, project)
    end
  end

  table.sort(filtered_projects, function(a,b)
    if order_by == "asc" then
        return a.title:lower() > b.title:lower()
    elseif order_by == "desc" then
        return a.title:lower() < b.title:lower()
    else
      if a.last_accessed_time and b.last_accessed_time then
        return a.last_accessed_time > b.last_accessed_time
      end
    end
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
---@param line string should not have a newline
---@return Project The project encoded by the input line
M.parse_project_line = function(line)
  return Project:decode(line)
end

-- Parses path into project object (activated by default)
M.get_project_from_path = function(path)
    -- `tostring` to use plenary path and paths defined as strings
    local title = tostring(path):match("[^/]+/?$")
    local workspace = 'w0'
    local activated = 1
    return Project:new(title, path, workspace, activated)
end

-- Standardized way of storing project to file
---@param file file* file handle from io.open()
---@param project Project
M.store_project = function(file, project)
  local line_contents = Project.encode(project) -- this doesn't have a newline
  file:write(line_contents .. '\n')
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

M.open_in_nvim_tree = function(project_path)
    local status_ok, nvim_tree_api = pcall(require, "nvim-tree.api")
    if status_ok then
      local tree = nvim_tree_api.tree
      tree.change_root(project_path)
      tree.open(project_path)
      vim.cmd('wincmd p')
    end
end

-- Update last accessed time on project change
M.update_last_accessed_project_time = function(project_path)
  local projects = M.get_project_objects()
  local file = io.open(M.telescope_projects_file, "w")
  for _, project in pairs(projects) do
    if project.path == project_path then
      project.last_accessed_time = os.time()
    end
    M.store_project(file, project)
  end

  io.close(file)
end

-- Change directory only when path exists
M.change_project_dir = function(project_path, cd_scope)
  if not cd_scope then
    cd_scope = "tcd"
  end

  if Path:new(project_path):exists() then
    M.update_last_accessed_project_time(project_path)
    vim.fn.execute(cd_scope .. " " .. project_path, "silent")
    if sync_with_nvim_tree then
      M.open_in_nvim_tree(project_path)
    end

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
