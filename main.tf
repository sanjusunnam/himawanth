terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}

subscription_id  = "eac39c23-7271-422a-83d8-308404262b6f"
client_id         = "627127ec-9db6-4f2f-a66f-08690a79fdd7"
tenant_id         = "bd632c6f-ce29-451d-b6c4-bc2a2118ba1d"
client_secret     = "jwZ8Q~1XyaDeXhr8AcPOUBH6S4HqEPaJAKQPFbGi"

}

  resource "azurerm_resource_group" "rg1" {
  name     = "Nextopsvideos"
  location = "East Us"
}

resource "azurerm_virtual_network" "Vnet1" {
  name                = "NextopsVnet"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  address_space       = ["10.10.0.0/16"]
}
resource "azurerm_subnet" "subnet1" {
  name                 = "subnet1"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.Vnet1.name
  address_prefixes     = ["10.10.1.0/24"]
}
resource "azurerm_network_security_group" "nsg1" {
  name                = "Nextops-nsg1"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
}

resource "azurerm_network_security_rule" "rdp" {
  name                        = "rdp"
  priority                    = 102
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg1.name
  network_security_group_name = azurerm_network_security_group.nsg1.name
}
resource "azurerm_subnet_network_security_group_association" "nsg_subnet_assoc" {
  subnet_id                 = azurerm_subnet.subnet1.id
  network_security_group_id = azurerm_network_security_group.nsg1.id
}
resource "azurerm_network_interface" "nic1" {
  name                = "NextopsVM-nic"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "example" {
  name                = "NextopsVm"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
  network_interface_ids = [azurerm_network_interface.nic1.id]

source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}
