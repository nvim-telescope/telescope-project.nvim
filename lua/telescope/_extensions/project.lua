local has_telescope, telescope = pcall(require, 'telescope')

if not has_telescope then
	error('This plugins requires nvim-telescope/telescope.nvim')
end
local actions = require("telescope.actions")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local sorters = require("telescope.sorters")
local builtin = require("telescope.builtin")

ProjectDirectories = {["init.vim"] = "~/.config/nvim"}

return telescope.register_extension {
	exports = {
		project = function(opts)
			opts = opts or {}

			local projects = {}

			local search_selected_project = function(selection)
				print(ProjectDirectories[selection])
				local selected_directory = ProjectDirectories[selection]
				builtin.find_files({cwd = selected_directory})
			end

			local n = 0
			for k in pairs(ProjectDirectories) do
				n = n + 1
				projects[n] = k
			end

			local select_project = function()
				pickers.new(opts, {
					prompt_title = 'Select a project',
					results_title = 'Projects',
					finder = finders.new_table {results = projects},
					sorter = sorters.get_generic_fuzzy_sorter(),
					attach_mappings = function(prompt_bufnr, map)
						local on_project_selected = function()
							local selection = actions.get_selected_entry(prompt_bufnr)
							actions.close(prompt_bufnr)
							search_selected_project(selection.value)
						end

						map('i', '<CR>', on_project_selected)
						map('n', '<CR>', on_project_selected)

						return true
					end
				}):find()
			end
			select_project()
		end
	}
}
