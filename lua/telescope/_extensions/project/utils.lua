local M = {}

-- The file path to telescope projects
M.telescope_projects_file = vim.fn.stdpath('data') .. '/telescope-projects.txt'

-- Checks if file exists at a given path
M.file_exists = function(path)
   local file = io.open(path, "r") if file ~= nil then io.close(file) return true else return false end
end

-- Initialize file if does not exist
M.init_file = function()
  if not M.file_exists(M.telescope_projects_file) then
    local newFile = io.open(M.telescope_projects_file, "w")
    newFile:write()
    newFile:close()
  end
end

-- Trim whitespace for strings
M.trim = function(s)
  return s:match( "^%s*(.-)%s*$" )
end

-- Check if value exists in table
M.has_value = function(tbl, val)
  for _, value in ipairs(tbl) do
    if value == val
      then return true
    end
  end
  return false
end

-- Checks the last time a directory was last accessed
M.get_last_accessed_time = function(path)
  local expanded_path = vim.fn.expand(path)
  local fs_stat = vim.loop.fs_stat(expanded_path)
  return fs_stat and fs_stat.atime.sec or 0
end

-- Extracts information from telescope projects line
-- example line: myproject=/home/user/projects/myproject
M.get_project_info = function(line)
  local title, path = line:match("^(.-)=(.-)$")
  local last_accessed = M.get_last_accessed_time(path)
  return { title = title, path = path, last_accessed = last_accessed }
end

-- Reads in the telescope projects file, returning projects table
M.get_projects = function()
  local projects = {}

  for line in io.lines(M.telescope_projects_file) do
    local project_info = M.get_project_info(line)
    table.insert(projects, project_info)
  end

  table.sort(projects, function(a,b)
    return a.last_accessed > b.last_accessed
  end)

  return projects
end

-- Read tmpfile, converting paths to proper format
-- example: /home/user/projects/myproject =>
--          myproject=/home/user/projects/myproject
M.extract_projects_from_tmpfile = function(tmp_path)
  local git_projects = {}
  for path in io.lines(tmp_path) do
    local title = path:match("[^/]+$")
    local project_line = title .. "=" .. path .. "\n"
    table.insert(git_projects, project_line)
  end
  return git_projects
end

-- Recurses directories under base directory to find all git projects
M.find_git_projects = function(base_dir)
  local shell_cmd = "find " .. base_dir .. " -type d -name .git -printf '%h\n'"
  local tmp_path = "/tmp/found_projects.txt"
  os.execute(shell_cmd .. " > " .. tmp_path)
  return M.extract_projects_from_tmpfile(tmp_path)
end

-- Write project to telescope projects file
M.save_git_repos = function(git_projects)
  local current_projects = {}
  for line in io.lines(M.telescope_projects_file) do
    table.insert(current_projects, line)
  end

  local projectsFile = io.open(M.telescope_projects_file, "a")
  for _, line in pairs(git_projects) do
    local path_exists = M.has_value(current_projects, M.trim(line))
    if not path_exists then projectsFile:write(line) end
  end
end

-- Initialize project, finding git repos if base_dir provided
M.update_git_repos = function(base_dir)
  local git_projects = base_dir and M.find_git_projects(base_dir) or {}
  M.save_git_repos(git_projects)
end

return M
