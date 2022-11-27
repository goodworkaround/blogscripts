variable "resource_naming_prefix" {
    type = string
}

variable "resource_group_name" {
    type = string
    default = "bastion"
}

variable "location" {
    type = string
    default = "westeurope"
}

variable "tags" {
    type = map
    default = {
        deletiondate = "2022-12-01"
    }
}