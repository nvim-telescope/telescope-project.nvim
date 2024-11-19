---@class Project
---@field title string
---@field path string
---@field workspace string
---@field activated number
---@field last_accessed_time number|nil A number returned by os.time()
local Project = {}
Project.__index = Project

Project.sep = '='

---@param title string
---@param path string
---@param workspace string
---@param activated number
---@param last_accessed_time number?
---@return Project
function Project:new(title, path, workspace, activated, last_accessed_time)
  local obj = {
    title = title,
    path = path,
    workspace = workspace,
    last_accessed_time = last_accessed_time,
    activated = activated,
  }
  setmetatable(obj, Project)
  return obj
end

---@param sep string the separator being used, which must be escaped as well
---@param ... string the potentially-multiline strings
---@return string escape backslashes and newlines to make a recoverable oneline version of str
local function escape(sep, ...)
  local args = { n = select('#', ...), ... }
  local result = {}
  for _, val in ipairs(args) do
    local escaped = tostring(val)
    escaped = escaped:gsub('\\', '\\\\')
    escaped = escaped:gsub('\n', '\\n')
    escaped = escaped:gsub(sep, '\\'..sep)
    table.insert(result, escaped)
  end
  return unpack(result)
end

---@param sep string the separator being used, which must be escaped as well
---@param ... string the escaped string
---@return string the original string
local function unescape(sep, ...)
  local args = { n = select('#', ...), ... }
  local result = {}
  for _, str in ipairs(args) do
    local original = str:gsub('\\.', {
      ['\\\\'] = '\\',
      ['\\n'] = '\n',
      ['\\'..sep] = sep,
    })
    table.insert(result, original)
  end
  return unpack(result)
end

---@return string A oneline string that can later be decoded back into a project. There will not be any newlines in the string.
function Project:encode()
  local sep = Project.sep
  local escaped_parts
  if self.last_accessed_time then
    escaped_parts = { escape(sep, self.title, self.path, self.workspace, self.activated, self.last_accessed_time) }
  else
    escaped_parts = { escape(sep, self.title, self.path, self.workspace, self.activated) }
  end
  local line = table.concat(escaped_parts, sep)
  return line
end

Project.__tostring = Project.encode

---@overload fun(self: Project, line: string): Project
---@overload fun(line: string): Project
function Project.decode(self, line)
  if type(self) == 'string' then
    line = self
  end
  local sep = Project.sep
  local fields = vim.fn.split(line, [[\(\\\)\@<!=]], 1)
  local title, path, workspace, activated, last_accessed_time = unescape(sep, unpack(fields))
  if workspace == '' then
    workspace = 'w0'
  end
  activated = tonumber(activated)
  if not activated then
    activated = 1
  end
  return Project:new(title, path, workspace, activated, tonumber(last_accessed_time))
end

return Project
