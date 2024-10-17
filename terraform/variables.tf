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
