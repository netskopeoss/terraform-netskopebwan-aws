  #cloud-config
  password: ${netskope_gw_default_password}
  infiot:
    uri: ${netskope_tenant_url}
    token: ${netskope_gw_activation_key}
  write_files:
  - content: |
        {
          "frrCmdSets": [
            {
              "frrCmds": [
                "conf t",
                "ip prefix-list default seq 5 permit 0.0.0.0/0",
                "route-map advertise permit 10",
                "match ip address prefix-list default",
                "route-map set-med-peer permit 10",
                "set metric ${netskope_gw_bgp_metric}"
              ]
            },
            {
              "frrCmds": [
                "conf t",
                "router bgp ${netskope_gw_asn}",
                "neighbor ${transit_gw_peer_inside_ip1} disable-connected-check",
                "neighbor ${transit_gw_peer_inside_ip1} ebgp-multihop 2",
                "neighbor ${transit_gw_peer_inside_ip1} route-map set-med-peer out",
                "neighbor ${transit_gw_peer_inside_ip2} disable-connected-check",
                "neighbor ${transit_gw_peer_inside_ip2} ebgp-multihop 2",
                "neighbor ${transit_gw_peer_inside_ip2} route-map set-med-peer out"
              ]
            },
            {
              "frrCmds": [
                "conf t",
                "route-map To-Ctrlr-1 deny 5",
                "match ip address prefix-list default",
                "route-map To-Ctrlr-2 deny 5",
                "match ip address prefix-list default",
                "route-map To-Ctrlr-3 deny 5",
                "match ip address prefix-list default"
              ]
            }
          ]
        }
    path: /infroot/workdir/frrcmds-user.json
    permissions: '0644'
    owner: 'root:root'
