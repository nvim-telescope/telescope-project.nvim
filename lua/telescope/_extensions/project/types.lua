---@meta

---@class Project
---@field title string
---@field path string
---@field workspace string
---@field activated number
---@field last_accessed_time number? A number returned by [os.time](lua://os.time)

---@alias ProjectFieldName
---|"'title'"
---|"'path'"
---|"'workspace'"
---|"'activated'"
---|"'last_accessed_time'"

---@class BaseDirMaxDepth
---@field max_depth? integer Defaults to 3

---@class BaseDirArray: BaseDirMaxDepth
---@field [1] string The path

---@class BaseDirPath: BaseDirMaxDepth
---@field path string

---@class (exact) BaseDirNormal
---@field path string
---@field max_depth integer Defaults to 3

---@alias BaseDirSpec string|BaseDirArray|BaseDirPath

---@alias OrderBy
---|"'asc'" # compares alphabetically, case-insensitive
---|"'desc'"
---|"'recent'" # uses last_accessed_time, most recent first
