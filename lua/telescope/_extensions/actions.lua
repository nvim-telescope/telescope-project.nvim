local actions = {}

local project_dirs_file = vim.fn.stdpath('data') .. '/telescope-projects.txt'

actions.add_project = function(title, directory)
	print('adding project')
	local file = io.open(project_dirs_file, "a")
	io.output(file)
	io.write(title .. '=' .. directory)
	io.close(file)
end

actions.delete_project = function(title)
end

return actions
