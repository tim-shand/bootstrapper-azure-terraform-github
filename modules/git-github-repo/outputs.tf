output "github_repository_name" {
  description       = "Repository name."
  value             = github_repository.gh_repo.name # data.github_repository.gh_repo.full_name
  sensitive         = false
}
