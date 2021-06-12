local M = {}

-- The file path to telescope projects
M.telescope_projects_file = vim.fn.stdpath('data') .. '/telescope-projects.txt'

-- Initialize file if does not exist
M.init_file = function()
  if not M.file_exists(M.telescope_projects_file) then
    local newFile = io.open(M.telescope_projects_file, "w")
    newFile:write()
    newFile:close()
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
  local title, path, activated = line:match("^(.-)=(.-)=(.-)$")
  if not activated then
    title, path = line:match("^(.-)=(.-)$")
    activated = 1
  end
  return {
    title = title,
    path = path,
    last_accessed = M.get_last_accessed_time(path),
    activated = activated
  }
end

-- Parses path into project object (activated by default)
M.get_project_from_path = function(path)
    local title = path:match("[^/]+$")
    local activated = 1
    local line = title .. "=" .. path .. "=" .. activated
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
  local line = project.title .. "=" .. project.path .. "=" .. project.activated .. "\n"
  file:write(line)
end

-- Checks if file exists at a given path
M.file_exists = function(path)
   local file = io.open(path, "r")
   if file ~= nil then
     io.close(file)
     return true
   else
     return false
   end
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

M.string_starts_with = function(text, start)
   return string.sub(text, 1, string.len(start)) == start
end

return M
