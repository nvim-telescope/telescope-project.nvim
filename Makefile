.PHONY: lint tests

lint:
	luacheck ./lua/telescope/_extensions/project

tests:
	nvim --headless -c "PlenaryBustedDirectory tests/project/ {minimal_init = 'tests/minimal_init.vim'}"
