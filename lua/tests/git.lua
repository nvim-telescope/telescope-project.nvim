describe("git", function()

  local git = require("telescope._extensions.project.git")

  it("try and find git path", function()
    local git_path = git.try_and_find_git_path()
    assert.equal("/home/arch/projects/telescope-project.nvim", git_path)
  end)

end)
