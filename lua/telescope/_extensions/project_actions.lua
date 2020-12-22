local builtin = require("telescope.builtin")
local actions = require("telescope.actions")
local transform_mod = require('telescope.actions.mt').transform_mod;

local project_actions = {}

local project_dirs_file = vim.fn.stdpath('data') .. '/telescope-projects.txt'

project_actions.add_project = function()
	local git_root = vim.fn.systemlist("git -C " .. vim.loop.cwd() .. " rev-parse --show-toplevel")[1]
	if not git_root then
		print('Telescope-project adds projects based on a git root. No project found. Please refer to documentation to add projects manually')
		return
	end

	local project_title = git_root:match("[^/]+$")
	local project_to_add = project_title .. "=" .. git_root

	local file = assert(io.open(project_dirs_file, "a"), "No project file exists")
	if not file then
		return
	end

	local project_already_added = false
	for line in io.lines(project_dirs_file) do
		local project_exists_check = line == project_to_add
			if project_exists_check then
				project_already_added = true
				print('This project already exists.')
				return
		end
	end

	if not project_already_added then
		io.output(file)
		io.write(project_to_add)
		print('project added')
	end
	io.close(file)
end

project_actions.delete_project = function(prompt_bufnr)
	local newLines = ""
	for line in io.lines(project_dirs_file) do
		local title, path = line:match("^(.-)=(.-)$")
		if title ~= actions.get_selected_entry(prompt_bufnr).display then
			newLines = newLines .. title .. '=' .. path .. "\n"
		end
	end
	local file = assert(io.open(project_dirs_file, "w"), "No project file exists")
	file:write(newLines)
	file:close()
	print('deleted project: ' .. actions.get_selected_entry(prompt_bufnr).display)
end

project_actions.find_project_files = function(prompt_bufnr)
	builtin.find_files({cwd = actions.get_selected_entry(prompt_bufnr).value})
end

project_actions = transform_mod(project_actions);
return project_actions
