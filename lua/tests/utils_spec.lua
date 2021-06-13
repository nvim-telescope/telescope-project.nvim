local path = require("plenary.path")

describe("utils", function()

  local utils = require("telescope._extensions.project.utils")

  local patch_projects_file = function()
    local test_file = "/tmp/dummy_project_file.txt"
    utils.telescope_projects_file = test_file
    utils.init_file()
    return path:new(test_file)
  end

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

  end)

  describe("project", function()

    it("create, save, and read from file", function()

      local test_project_path = "/test/project"
      local test_path = patch_projects_file()

      -- extract project information from path
      local project = utils.get_project_from_path(test_project_path)
      assert.equal(project.path, test_project_path)

      -- store project in test file
      local file = io.open(test_path.filename, "w")
      utils.store_project(file, project)
      io.close(file)

      -- retrieve projects from test file
      local projects = utils.get_projects()

      -- check that test project was found
      local found_test_project = false
      for _, stored_project in pairs(projects) do
        if stored_project.path == test_project_path then
          found_test_project = true
        end
      end
      assert.equal(true, found_test_project)

      -- cleanup
      test_path:rm()
    end)

  end)

end)
