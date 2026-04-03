# Создание сервисного аккаунта
resource "yandex_iam_service_account" "terraform" {
  name        = "terraform-sa-diploma"
  description = "Service account for Terraform"
}

# Назначение ролей (минимально необходимые)
resource "yandex_resourcemanager_folder_iam_member" "editor" {
  folder_id = var.yc_folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.terraform.id}"
}

# Статический ключ доступа для работы с Object Storage
resource "yandex_iam_service_account_static_access_key" "terraform_sa_key" {
  service_account_id = yandex_iam_service_account.terraform.id
  description        = "Static access key for Terraform to manage bucket"
}

# Создание бакета для хранения стейта
resource "yandex_storage_bucket" "tfstate" {
  bucket     = "tfstate-bucket-${var.bucket_suffix}"
  access_key = yandex_iam_service_account_static_access_key.terraform_sa_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.terraform_sa_key.secret_key
}

