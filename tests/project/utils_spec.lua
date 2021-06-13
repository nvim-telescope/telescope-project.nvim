describe("utils", function()

  local path = require("plenary.path")
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

  end)

end)
