set p4_file rx.p4
set vitis_net_p4 rx_vitis_net_p4_core

create_ip -name vitis_net_p4 -vendor xilinx.com -library ip -module_name $vitis_net_p4

set vitis_net_p4_config [dict create]
dict set vitis_net_p4_config CONFIG.P4_FILE              "$user_plugin/p4/$p4_file"
dict set vitis_net_p4_config CONFIG.AXIS_CLK_FREQ_MHZ    250.0
dict set vitis_net_p4_config CONFIG.CAM_MEM_CLK_FREQ_MHZ 250.0
dict set vitis_net_p4_config CONFIG.PKT_RATE             250.0
dict set vitis_net_p4_config CONFIG.TDATA_NUM_BYTES      64
dict set vitis_net_p4_config CONFIG.CAM_MEM_CLK_ENABLE   1
set_property -dict $vitis_net_p4_config [get_ips $vitis_net_p4]

if {[get_property CONFIG.S_AXI_ADDR_WIDTH [get_ips $vitis_net_p4]] == 0} {
    set_property CONFIG.S_AXI_ADDR_WIDTH 20 [get_ips $vitis_net_p4]
}

generate_target all [get_ips $vitis_net_p4]
