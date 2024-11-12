variable "zone" {
  default = "ru-central1-a"
}

variable "folder_id" {
  default = null
}

variable "network" {
  default = {
    subnets = ["10.1.0.0/16"]
  }
}

variable "git_username" {
  sensitive = true
  type      = string
  default   = ""
}

variable "git_token" {
  sensitive = true
  type      = string
  default   = ""
}

variable "git_url" {
  type    = string
  default = "https://github.com/mishikama/my-k8s"
}

variable "git_ref" {
  type    = string
  default = "refs/heads/main"
}

variable "git_path" {
  type    = string
  default = "gitops/clusters/cluster"
}
