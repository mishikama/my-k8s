variable "zone" {
  default = "ru-central1-a"
}

variable "folder_id" {
  description = "Yandex Cloud Folder ID where resources will be created"
  default     = null
}

variable "network" {
  default = {
    subnets = ["10.1.0.0/16"]
  }
}

variable "git_token" {
  sensitive = true
  type      = string
  default   = ""
}

variable "git_url" {
  type    = string
  default = null
}

variable "git_ref" {
  type    = string
  default = "refs/heads/main"
}

variable "git_path" {
  type    = string
  default = null
}
