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

  end)

  describe("project", function()

    it("create, save, and read from file", function()

      -- initialize projects file where projects are stored
      local test_projects_file = "/tmp/telescope-projects-test.txt"
      utils.telescope_projects_file = test_projects_file
      utils.init_file()
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

      -- remove example project and run cleanup
      path:new(example_project_path):rm()
      utils.cleanup_missing_projects()

      -- recheck that example project was not found now that it is gone
      projects = utils.get_projects()
      found_test_project = false
      for _, stored_project in pairs(projects) do
        if stored_project.path == example_project_path then
          found_test_project = true
        end
      end
      assert.equal(false, found_test_project)

      -- cleanup
      test_projects_path:rm()
    end)

  end)

end)
