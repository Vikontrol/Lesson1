terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"

  backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "BAKET_NAME"
    region     = "ru-central1"
    key        = "FILE_NAME"
    shared_credentials_file = "storage.key"

    skip_region_validation      = true
    skip_credentials_validation = true
  }
}

provider "yandex" {
  service_account_key_file = "key.json"
  cloud_id                 = "CLOUD_ID"
  folder_id                = "FOLDER_ID"
  zone                     = "ru-central1-a"
}

resource "yandex_vpc_network" "test-vpc" {
  name = "nixys"
}

resource "yandex_vpc_subnet" "test-subnet" {
  v4_cidr_blocks = ["10.2.0.0/16"]
  network_id     = yandex_vpc_network.test-vpc.id
}

resource "yandex_vpc_security_group" "test-sg" {
  name        = "My security group"
  description = "description for my security group"
  network_id  = yandex_vpc_network.test-vpc.id

  labels = {
    my-label = "my-label-value"
  }

  dynamic "ingress" {
    for_each = ["80", "8080"]
    content {
      protocol       = "TCP"
      description    = "rule1 description"
      v4_cidr_blocks = ["0.0.0.0/0"]
      from_port      = ingress.value
      to_port        = ingress.value
    }
  }

  egress {
    protocol       = "ANY"
    description    = "rule2 description"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

resource "yandex_vpc_address" "test-ip" {
  name = "exampleAddress"

  external_ipv4_address {
    zone_id = "ru-central1-a"
  }
}

resource "yandex_compute_instance" "nixys" {
  name        = "nixys"
  platform_id = "standard-v1"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd83h3kff4ja27ejq0d9"
    }
  }

  network_interface {
    subnet_id      = yandex_vpc_subnet.test-subnet.id
    nat            = true
    nat_ip_address = yandex_vpc_address.test-ip.external_ipv4_address.0.address
  }

  metadata = {
    ssh-keys  = "debian:${file("/root/.ssh/id_rsa.pub")}"
    user-data = "${file("init.sh")}"
  }
}

output "external_ip" {
  value = yandex_vpc_address.test-ip.external_ipv4_address.0.address
}

output "external_ip-2" {
  value = yandex_compute_instance.nixys.network_interface.0.nat_ip_address
}