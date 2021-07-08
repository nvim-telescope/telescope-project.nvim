local path = require("plenary.path")

describe("utils", function()

  local utils = require("telescope._extensions.project.utils")

  describe("general", function()

    it("trim whitespace (left and right)", function()
      local input_str = " text "
      assert.equal("text", utils.trim(input_str))
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
      assert.equal(true, utils.change_project_dir(test_dir.filename))
      test_dir:rmdir()
      assert.equal(false, utils.change_project_dir(test_dir.filename))
    end)

  end)

  describe("project", function()

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
