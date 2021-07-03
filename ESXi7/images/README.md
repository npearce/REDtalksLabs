# REDtalks.Lab Images

## Summary

This is where a summary goes.

## Images

1. HashiStack               - `ESXi7/debian_base`
  1. Vanilla Debian Image
  2. HashiStack Image - Consul, Vault, Nomad
  3. Lab Automation Image - Consul, Terraform
2. More Comming Soon

## Use

Enter the relevant variables into the `*.auto.pkrvars.hcl` file. 

Execute:

`packer build .`

The OVA file will appear in a directory prefixed with `output-`, e.g. `output-rtlLabBaseVM`

## Details

### 1. HashiStack

Debian 10.9 ISO install with the following additions:

Debian installer packages: 
* ssh-server
* web-server

Additional packages:
* sudo
* wget
* curl
* open-vm-tools
* software-properties-common
* gnupg2
* git
* consul
* vault
* nomad

### 2. More Comming Soon