local has_telescope, telescope = pcall(require, 'telescope')
local main = require('telescope._extensions.project.main')

if not has_telescope then
  error('This plugins requires nvim-telescope/telescope.nvim')
end

return telescope.register_extension{
  setup = main.setup,
  exports = { project = main.project }
}
