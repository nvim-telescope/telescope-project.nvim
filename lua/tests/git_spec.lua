local path = require("plenary.path")

describe("git", function()

  local git = require("telescope._extensions.project.git")
  local path_to_projects = path:new("/tmp/git_spec_projects")

  -- Create test projects
  local project_paths = (function()
    local project_names = { 
      "project1",  
      "project2",  
      "project3",  
      "project4",  
    }

    local project_paths = {}
    for _, project_name in ipairs(project_names) do
      -- Create project path
      local project_path = path_to_projects:joinpath(project_name)
      table.insert(project_paths, project_path)

      -- Create project directory
      project_path:mkdir({parents = true})
      os.execute("git init --quiet " .. project_path.filename)
    end

    return project_paths
  end)()

  it("try and find path", function()
    local path = project_paths[2]
    vim.fn.execute("cd " .. path.filename, "silent")
    local git_path = git.try_and_find_git_path()
    assert.equal(path.filename, git_path)
  end)

  it("search for repos", function()
    git.tmp_path = "/tmp/found_projects_git_spec.txt"
    git.search_for_git_repos({{path = path_to_projects.filename, max_depth = 2}})
    local git_projects = git.parse_git_repo_paths()

    local project_found = function(path)
      for _, project_path in ipairs(project_paths) do
        if project_path.filename == path then
          return true
        end
      end
      return false
    end

    local found_all_projects = true
    for _, git_project in pairs(git_projects) do
      if not project_found(git_project.path) then
        found_all_projects = false
      end
    end
    assert.equal(true, found_all_projects)
  end)

  path:new(git.tmp_path):rm()
  path_to_projects:rm({ recursive = true })

end)
