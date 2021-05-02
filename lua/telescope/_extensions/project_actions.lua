local builtin = require("telescope.builtin")
local actions = require("telescope.actions")
local transform_mod = require('telescope.actions.mt').transform_mod

local project_actions = {}

local project_dirs_file = vim.fn.stdpath('data') .. '/telescope-projects.txt'

function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

project_actions.add_project = function(prompt_bufnr)
  local git_root = vim.fn.systemlist("git -C " .. vim.loop.cwd() .. " rev-parse --show-toplevel")[
    1
  ]

  local project_directory = git_root
  if not git_root or string.starts(git_root,'fatal') then
    project_directory = vim.loop.cwd()
  end

  local project_title = project_directory:match("[^/]+$")
  local project_to_add = project_title .. "=" .. project_directory .. "\n"

  local file = assert(
    io.open(project_dirs_file, "a"),
    "No project file exists"
  )

  local project_already_added = false
  for line in io.lines(project_dirs_file) do
    local project_exists_check = line .. "\n" == project_to_add
    if project_exists_check then
      project_already_added = true
      print('This project already exists.')
      return
    end
  end

  if not project_already_added then
    io.output(file)
    io.write(project_to_add)
    print('project added: ' .. project_title)
  end
  io.close(file)
  actions.close(prompt_bufnr)
  require 'telescope'.extensions.project.project()
end

project_actions.rename_project = function(prompt_bufnr)
  local oldName = actions.get_selected_entry(prompt_bufnr).display
  local newName = vim.fn.input('Rename ' ..oldName.. ' to: ', oldName)
  local newLines = ""
  for line in io.lines(project_dirs_file) do
    local title, path = line:match("^(.-)=(.-)$")
    if title ~= oldName then
      newLines = newLines .. title .. '=' .. path .. '\n'
    else
      newLines = newLines .. newName .. '=' .. actions.get_selected_entry(prompt_bufnr).value .. '\n'
    end
  end
  local file = assert(
    io.open(project_dirs_file, "w"),
    "No project file exists"
  )
  file:write(newLines)
  file:close()
  print('Project renamed: ' .. actions.get_selected_entry(prompt_bufnr).display .. ' -> ' .. newName)
  actions.close(prompt_bufnr)
  require 'telescope'.extensions.project.project()
end

project_actions.delete_project = function(prompt_bufnr)
  local newLines = ""
  for line in io.lines(project_dirs_file) do
    local title, path = line:match("^(.-)=(.-)$")
    if title ~= actions.get_selected_entry(prompt_bufnr).display then
      newLines = newLines .. title .. '=' .. path .. "\n"
    end
  end
  local file = assert(
    io.open(project_dirs_file, "w"),
    "No project file exists"
  )
  file:write(newLines)
  file:close()
  print('Project deleted: ' .. actions.get_selected_entry(prompt_bufnr).display)
  actions.close(prompt_bufnr)
  require 'telescope'.extensions.project.project()
end

project_actions.find_project_files = function(prompt_bufnr)
  local dir = actions.get_selected_entry(prompt_bufnr).value
  actions._close(prompt_bufnr, true)
  vim.fn.execute("cd " .. dir, "silent")
  builtin.find_files({cwd = dir})
end

project_actions.search_in_project_files = function(prompt_bufnr)
  local dir = actions.get_selected_entry(prompt_bufnr).value
  actions._close(prompt_bufnr, true)
  vim.fn.execute("cd " .. dir, "silent")
  builtin.live_grep({cwd = dir})
end

project_actions.change_working_directory = function(prompt_bufnr)
  local dir = actions.get_selected_entry(prompt_bufnr).value
  actions.close(prompt_bufnr)
  vim.fn.execute("cd " .. dir, "silent")
end

project_actions = transform_mod(project_actions);
return project_actions
