local builtin = require("telescope.builtin")

local actions = {}

local project_dirs_file = vim.fn.stdpath('data') .. '/telescope-projects.txt'

actions.add_project = function(title, directory)
	print('adding project')
	local file = assert(io.open(project_dirs_file, "a"), "No project file exists")
	io.output(file)
	io.write(title .. '=' .. directory)
	io.close(file)
end

actions.delete_project = function(project_to_delete)
	local project_dirs_without_deleted_project = {}
	local file = assert(io.open(project_dirs_file, "w"), "No project file exists")
	io.output(file)
	for line in io.lines(project_dirs_file) do
		local title, path = line:match("^(.-)=(.-)$")
		if title ~= project_to_delete then
			project_dirs_without_deleted_project[title] = path
			io.write(title .. '=' .. path)
		end
	end
	io.close()
	print(project_dirs_without_deleted_project)
end

actions.open_path_at_selected_project = function(selection, project_dirs)
	vim.api.nvim_command('Explore ' .. project_dirs[selection])
end

actions.search_selected_project = function(selection)
	builtin.find_files({cwd = selection.value})
end

return actions
