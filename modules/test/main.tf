provider "netskopebwan" {
  baseurl  = "https://demo.api.stage1.infiot.net"
  apitoken = "WzEsIjYzNWNhZjViYmU5YzY3NGQ2ODliNTVmOSIsImJIcmJ0djZCcCswPSJd"
}

resource "netskopebwan_policy" "multicloud" {
  name = "test"
}

// Gateway Resource 
resource "netskopebwan_gateway" "primary" {
  name  = "test-gw"
  model = "iXVirtual"
  role  = "spoke"
  assigned_policy {
    id   = resource.netskopebwan_policy.multicloud.id
    name = resource.netskopebwan_policy.multicloud.name
  }
}

# Netskope GW creation can take a few seconds to
# create all dependent services in backend
resource "time_sleep" "primary_gw_propagation" {
  create_duration = "30s"

  triggers = {
    gateway_id = netskopebwan_gateway.primary.id
  }
}

output "t" {
  value = time_sleep.primary_gw_propagation.triggers["gateway_id"]
}