local actions = require("telescope.actions")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local sorters = require("telescope.sorters")

return require("telescope").register_extension {
    exports = {
        configurations = function(opts)
            opts = opts or {}
            -- TODO check for existing projects

            if vim.tbl_isempty(configurations) then
                return
            end

            pickers.new(
                opts,
                {
                    prompt_title = "Project Launch",
                    finder = finders.new_table {
                        results = configurations
                    },
                    sorter = sorters.get_generic_fuzzy_sorter(),
                    attach_mappings = function(prompt_bufnr, map)
                        local search_project = function(prompt_bufnr, map)
                            local selection = actions.get_selected_entry(prompt_bufnr)
                            -- TODO start new search with cwd option
                        end

                        map("i", "<CR>", search_project)
                        map("n", "<CR>", search_project)

                        return true
                    end
                }
            ):find()
        end
    }
}
