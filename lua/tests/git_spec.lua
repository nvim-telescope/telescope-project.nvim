local path = require("plenary.path")

describe("git", function()

  local git = require("telescope._extensions.project.git")
  local path_to_projects = path:new("/tmp/git_spec_projects")
  local example_project_path = path:new(path_to_projects.filename .. "/example")
  example_project_path:mkdir({ parents = true })
  os.execute("git init --quiet " .. example_project_path.filename)

  it("try and find path", function()
    vim.fn.execute("cd " .. example_project_path.filename, "silent")
    local git_path = git.try_and_find_git_path()
    assert.equal(example_project_path.filename, git_path)
  end)

  it("search for repos", function()
    git.tmp_path = "/tmp/found_projects_git_spec.txt"
    git.search_for_git_repos(path_to_projects.filename, 2)
    local git_projects = git.parse_git_repo_paths()

    local found_git_project = false
    for _, git_project in pairs(git_projects) do
      if git_project.path == example_project_path.filename then
        found_git_project = true
      end
    end
    assert.equal(true, found_git_project)
  end)

  path:new(git.tmp_path):rm()
  path_to_projects:rm({ recursive = true })

end)
