local path = require("plenary.path")
local iter = require("plenary.iterators")

describe("git", function()

  local git = require("telescope._extensions.project.git")
  local path_to_projects = path:new("/tmp/git_spec_projects")

  local project_names = { 
    "project1",  
    "project2",  
    "project3",  
    "project4",  
  }
  -- Create test projects
  local project_paths = iter.iter(project_names)
    :map(function(project_name)
      -- Create project path
      local project_path = path_to_projects:joinpath(project_name)

      -- Create project directory
      project_path:mkdir({parents = true})
      os.execute("git init --quiet " .. project_path.filename)

      return project_path
    end)
    :tolist()


  it("try and find path", function()
    local path = project_paths[2]
    vim.fn.execute("cd " .. path.filename, "silent")
    local git_path = git.try_and_find_git_path()
    assert.equal(path.filename, git_path)
  end)

  it("search for repos", function()
    local repo_paths = git.search_for_git_repos({{path = path_to_projects.filename, max_depth = 2}})
    local git_projects = git.parse_git_repo_paths(repo_paths)
    local found_all_projects = true

    for _, git_project in pairs(git_projects) do
      if not iter.iter(project_paths):find(function(p) return p.filename == git_project.path end) then
        found_all_projects = false
      end
    end
    assert.equal(true, found_all_projects)
  end)

  path_to_projects:rm({ recursive = true })

end)
