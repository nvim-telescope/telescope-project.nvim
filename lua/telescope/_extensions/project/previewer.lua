local previewers = require("telescope.previewers")
local utils = require('telescope.utils')
local defaulter = utils.make_default_callable

local M = {}

local function file_exists(name)
    local f = io.open(name,"r")
    if f ~= nil then io.close(f) return true else return false end
end

M.previewer = defaulter(function(user_opts)
    if user_opts.preview.disable == true then
        return nil
    end
    return previewers.new_buffer_previewer({
        title = "Preview",
        define_preview = function(self, entry, opts)
            -- Get the README or notes files, defaulting to displaying the folder
            local path = entry.path
            if user_opts.preview.dir_only == nil or user_opts.preview.dir_only == false then
                local default_readme_files = {
                    "README.md",
                    "README.txt",
                    "readme.md",
                    "readme.txt",
                }
                local readme_files = default_readme_files
                if user_opts.preview.additional_readmes then
                    readme_files = table.merge(default_readme_files, user_opts.preview.additional_readmes)
                end


                for _, f in pairs(readme_files) do
                    local f_path = entry.path .. "/" .. f
                    if file_exists(f_path) then
                        path = f_path
                        break
                    end
                end
            end

            -- Return the previewer
            return previewers.buffer_previewer_maker(path, self.state.bufnr, opts)
        end
    })
end, {})

return M

