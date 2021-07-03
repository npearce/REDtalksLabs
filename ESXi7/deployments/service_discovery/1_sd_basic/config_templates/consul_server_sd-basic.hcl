datacenter        = "RTlab-dc-1"
data_dir          = "/opt/consul"
client_addr       = "0.0.0.0"
bind_addr         = "0.0.0.0"
server            = true
ui_config         = {
  enabled           = true
}
bootstrap_expect  = ${server_count}
retry_join        = [ ${servers_fqdn} ]
