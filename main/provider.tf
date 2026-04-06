terraform {
  required_version = ">=1.5.5"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.95"
    }
  }
  backend "s3" {
    bucket = "tfstate-bucket-student-bucket-diploma"
    region = "ru-central1"
    key    = "main/terraform.tfstate"
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}

provider "yandex" {

  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  zone      = var.yc_default_zone
  token     = var.token
  #  service_account_key_file = file("~/authorized_key.json")
}

