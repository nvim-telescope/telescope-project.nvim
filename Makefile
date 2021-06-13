.PHONY: lint tests

lint:
	luacheck ./lua/telescope

tests:
	nvim --headless -c "PlenaryBustedDirectory lua/tests/ {minimal_init = 'lua/tests/minimal_init.vim'}"
