local has_telescope, telescope = pcall(require, 'telescope')

if not has_telescope then
	error('This plugins requires nvim-telescope/telescope.nvim')
end

local actions = require("telescope.actions")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values
local builtin = require("telescope.builtin")

local project_dirs_file = vim.fn.stdpath('data') .. '/telescope-projects.txt'

local function check_for_project_dirs_file()
	local f = io.open(project_dirs_file, "r")
	if f ~= nil then
		io.close(f)
		return true
	else
		error('No project file exists')
	end
end

local select_project = function(opts, projects, run_task_on_selected_project)
	pickers.new(opts, {
		prompt_title = 'Select a project',
		results_title = 'Projects',
		finder = finders.new_table {
			results = projects,
			entry_maker = function(entry)
				return {
					value = entry.value,
					display = entry.display,
					ordinal = entry.ordinal,
				}
			end,
		},
		sorter = conf.file_sorter(opts),
		attach_mappings = function(prompt_bufnr)
			local on_project_selected = function()
				local selection = actions.get_selected_entry(prompt_bufnr)
				actions.close(prompt_bufnr)
				run_task_on_selected_project(selection)
			end
			actions.goto_file_selection_edit:replace(on_project_selected)
			return true
		end
	}):find()
end

local project = function(opts)
	opts = opts or {}

	local project_dirs = {}

	check_for_project_dirs_file()

	-- format for projects is title of project=~/this/path/name
	for line in io.lines(project_dirs_file) do
		local title, path = line:match("^(.-)=(.-)$")
		project_dirs[title] = path
	end

	local projects = {}
	for k, v in pairs(project_dirs) do
		table.insert(projects, {
			value = v,
			display = k,
			ordinal = k,
		})
	end

	local search_selected_project = function(selection)
		builtin.find_files({cwd = selection.value})
	end

	-- TODO allow a way to choose between the above function and this one.
	local open_path_at_selected_project = function(selection)
		vim.api.nvim_command('Explore ' .. project_dirs[selection])
	end

	select_project(opts, projects, search_selected_project)
end

return telescope.register_extension {exports = {project = project}}
