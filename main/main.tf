# Создаём VPC, подсети в трёх зонах, группы безопасности,
# ВМ для мастер-ноды и воркер-нод (прерываемые для воркеров)

# Сеть
resource "yandex_vpc_network" "k8s_net" {
  name = "k8s-network"
}

# Подсети
resource "yandex_vpc_subnet" "subnet_a" {
  name           = "subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.k8s_net.id
  v4_cidr_blocks = ["10.1.0.0/24"]
}

resource "yandex_vpc_subnet" "subnet_b" {
  name           = "subnet-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.k8s_net.id
  v4_cidr_blocks = ["10.2.0.0/24"]
}

# Группа безопасности для доступа к API и ssh
resource "yandex_vpc_security_group" "k8s_sg" {
  name       = "k8s-security-group"
  network_id = yandex_vpc_network.k8s_net.id

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "SSH"
  }

  ingress {
    protocol       = "TCP"
    port           = 6443
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "Kubernetes API"
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "Allow all outbound"
  }
}

# Мастер-нода (непрерываемая, для стабильности)
resource "yandex_compute_instance" "master" {
  name        = "k8s-master"
  platform_id = "standard-v2"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = "fd8jjccig145ofgp5b9u" # Ubuntu 24.04 LTS
      size     = 20
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet_a.id
    security_group_ids = [yandex_vpc_security_group.k8s_sg.id]
    nat                = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

# Воркер-ноды (прерываемые)
resource "yandex_compute_instance" "worker" {
  count       = 2
  name        = "k8s-worker-${count.index}"
  platform_id = "standard-v2"
  zone        = count.index == 0 ? "ru-central1-a" : "ru-central1-b" # распределим по зонам

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = "fd8jjccig145ofgp5b9u"
      size     = 20
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = count.index == 0 ? yandex_vpc_subnet.subnet_a.id : yandex_vpc_subnet.subnet_b.id
    security_group_ids = [yandex_vpc_security_group.k8s_sg.id]
    nat                = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }

  scheduling_policy {
    preemptible = true
  }
}

resource "local_file" "kubespray_inventory" {
  content = templatefile("${path.module}/hosts.tftpl", {
    master  = yandex_compute_instance.master
    workers = yandex_compute_instance.worker
  })
  filename = "./inventory.ini"
}