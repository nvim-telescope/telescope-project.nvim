# telescope-project.nvim

An extension for [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) that allows you to switch projects.

## Demo

![Demo](./demo.gif)

## Setup

You can setup the extension by adding the following to your config:

```lua
require'telescope'.load_extension('project')
```

## Available functions:

### Project

The projects picker.

```lua
require'telescope'.extensions.project.project{}
```

## Example config: 

```lua
vim.api.nvim_set_keymap(
	'n',
	'<C-p>',
	":lua require'telescope'.extensions.project.project{}<CR>",
	{noremap = true, silent = true}
)
```

## Default mappings (normal mode):
d: delete currently selected project\
c: create a project (defaults to your git root if used inside a git project, otherwise will use your current working directory)\
s: search inside files within your project\
w: change to the selected project's directory without opening it\
f: find a file within your project (this works the same as \<CR\>)

## Roadmap :blue_car:
- workspaces :construction:
