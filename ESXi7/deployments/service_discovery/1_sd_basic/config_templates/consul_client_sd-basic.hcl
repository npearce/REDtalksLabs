datacenter    = "RTlab-dc-1"
data_dir      = "/opt/consul"
client_addr   = "0.0.0.0"
bind_addr     = "0.0.0.0"
retry_join    = [ ${servers_fqdn} ]
service {
  id            = "${service_id}"
  name          = "${service_name}"
}