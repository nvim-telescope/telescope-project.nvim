local path = require("plenary.path")

describe("utils", function()

  local utils = require("telescope._extensions.project.utils")

  describe("general", function()

    it("trim whitespace (left and right)", function()
      local input_str = " text "
      assert.equal("text", utils.trim(input_str))
    end)

    it("string start with 'fatal'", function()
      -- expected text when running git.try_and_find_git_path()
      local input_str = "fatal: not a git repository (or any parent up to mount point /)"
      assert.equal(true, utils.string_starts_with(input_str, "fatal"))
    end)

    it("table has a value (whitespace ignored)", function()
      local paths = {"/projects/A", "/projects/B"}
      assert.equal(true, utils.has_value(paths, "/projects/A"))
      assert.equal(true, utils.has_value(paths, "/projects/B "))
      assert.equal(false, utils.has_value(paths, "/projects/C"))
    end)

    it ("change project directory works", function()
      local test_dir = path:new("/tmp/test_dir")
      test_dir:mkdir()
      assert.equal(true, utils.change_project_dir(test_dir.filename, "cd"))
      assert.equal(0, vim.api.nvim_call_function("haslocaldir", {1}))
      test_dir:rmdir()
      assert.equal(false, utils.change_project_dir(test_dir.filename))
    end)

    it ("local project directory works", function()
      local test_dir = path:new("/tmp/test_dir")
      test_dir:mkdir()
      assert.equal(true, utils.change_project_dir(test_dir.filename, "lcd"))
      assert.equal(1, vim.api.nvim_call_function("haslocaldir", {1}))
      test_dir:rmdir()

      -- Reset cwd
      vim.fn.execute("cd")
    end)

    it ("tab project directory works", function()
      local test_dir = path:new("/tmp/test_dir")
      test_dir:mkdir()
      assert.equal(true, utils.change_project_dir(test_dir.filename, "tcd"))
      assert.equal(1, vim.api.nvim_call_function("haslocaldir", {-1}))
      test_dir:rmdir()

      -- Reset cwd
      vim.fn.execute("cd")
    end)

  end)

  describe("project", function()

    it("create, save, and read from file", function()

      -- initialize projects file where projects are stored
      local test_projects_file = "/tmp/telescope-projects-test.txt"
      utils.telescope_projects_file = test_projects_file
      utils.init_files()
      local test_projects_path = path:new(test_projects_file)

      -- extract project information from path
      local example_project_path = "/projects/my_project"
      local project = utils.get_project_from_path(example_project_path)
      assert.equal(project.path, example_project_path)
      assert.equal(project.title, "my_project")
      assert.equal(project.activated, "1")

      -- store project in test file
      local file = io.open(test_projects_path.filename, "w")
      utils.store_project(file, project)
      io.close(file)

      -- check that test project was found
      local projects = utils.get_projects()
      local found_test_project = false
      for _, stored_project in pairs(projects) do
        if stored_project.path == example_project_path then
          found_test_project = true
        end
      end

      assert.equal(true, found_test_project)
      test_projects_path:rm()
    end)

    it("normalize base_dirs configuration", function()

      -- assert helper function
      local config_has = function(config, path, max_depth)
        return config.path == path and config.max_depth == max_depth
      end

      -- test base_dirs config
      local base_dirs = {
        'path1',
        {'path2'},
        {'path3', max_depth = 4},
        {path = 'path4'},
        {path = 'path5', max_depth = 2}
      }

      -- normalize the configurations
      local normalized_configs = utils.normalize_base_dir_configs(base_dirs)

      assert.equal(true, config_has(normalized_configs[1], 'path1', 3))
      assert.equal(true, config_has(normalized_configs[2], 'path2', 3))
      assert.equal(true, config_has(normalized_configs[3], 'path3', 4))
      assert.equal(true, config_has(normalized_configs[4], 'path4', 3))
      assert.equal(true, config_has(normalized_configs[5], 'path5', 2))

    end)

  end)

end)
