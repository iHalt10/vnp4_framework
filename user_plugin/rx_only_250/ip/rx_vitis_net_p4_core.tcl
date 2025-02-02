set p4_file rx.p4
set vitis_net_p4 rx_vitis_net_p4_core
create_ip -name vitis_net_p4 -vendor xilinx.com -library ip -module_name $vitis_net_p4
set_property -dict [list CONFIG.P4_FILE "$user_plugin/p4/$p4_file"] [get_ips $vitis_net_p4]
generate_target all [get_ips $vitis_net_p4]
