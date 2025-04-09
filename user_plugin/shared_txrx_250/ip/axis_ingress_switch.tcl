set axis_switch axis_ingress_switch
create_ip -name axis_switch -vendor xilinx.com -library ip -version 1.1 -module_name $axis_switch

set num_slaves [expr $num_qdma * $num_phys_func + $num_cmac_port]
set axis_ingress_switch_config [dict create]
set tdata_num_bytes 64
set arb_on_max_xfers [expr {($max_pkt_len + $tdata_num_bytes - 1) / $tdata_num_bytes}]

dict set axis_ingress_switch_config CONFIG.NUM_MI 1
dict set axis_ingress_switch_config CONFIG.NUM_SI $num_slaves
dict set axis_ingress_switch_config CONFIG.TDATA_NUM_BYTES $tdata_num_bytes
dict set axis_ingress_switch_config CONFIG.TUSER_WIDTH 20
dict set axis_ingress_switch_config CONFIG.ROUTING_MODE 0
dict set axis_ingress_switch_config CONFIG.HAS_TKEEP 1
dict set axis_ingress_switch_config CONFIG.HAS_TLAST 1
dict set axis_ingress_switch_config CONFIG.HAS_TREADY 1
dict set axis_ingress_switch_config CONFIG.COMMON_CLOCK 1
dict set axis_ingress_switch_config CONFIG.ARB_ON_TLAST 1
dict set axis_ingress_switch_config CONFIG.ARB_ON_MAX_XFERS $arb_on_max_xfers

for {set i 0} {$i < $num_slaves} {incr i} {
    dict set axis_ingress_switch_config "CONFIG.M00_S[format %02d $i]_CONNECTIVITY" 1
}

set_property -dict $axis_ingress_switch_config [get_ips $axis_switch]
