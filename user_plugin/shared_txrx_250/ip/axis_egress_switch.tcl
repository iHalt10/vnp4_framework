set axis_switch axis_egress_switch
create_ip -name axis_switch -vendor xilinx.com -library ip -version 1.1 -module_name $axis_switch

set num_masters [expr $num_qdma * $num_phys_func + $num_cmac_port]
set axis_egress_switch_config [dict create]

dict set axis_egress_switch_config CONFIG.NUM_SI 1
dict set axis_egress_switch_config CONFIG.NUM_MI $num_masters
dict set axis_egress_switch_config CONFIG.TDATA_NUM_BYTES 64
dict set axis_egress_switch_config CONFIG.TUSER_WIDTH 48
dict set axis_egress_switch_config CONFIG.TDEST_WIDTH 4
dict set axis_egress_switch_config CONFIG.HAS_TKEEP 1
dict set axis_egress_switch_config CONFIG.HAS_TLAST 1
dict set axis_egress_switch_config CONFIG.HAS_TREADY 1

set i 0
set j 0

for {set x 0} {$x < 2} {incr x} {
    for {set y 0} {$y < 4} {incr y} {
        if {$x < $num_qdma && $y < $num_phys_func} {
            dict set axis_egress_switch_config "CONFIG.M[format %02d $j]_AXIS_BASETDEST" "0x0000000$i"
            dict set axis_egress_switch_config "CONFIG.M[format %02d $j]_AXIS_HIGHTDEST" "0x0000000$i"
            incr j
        }
        incr i
    }
}

for {set x 0} {$x < 2} {incr x} {
    if {$x < $num_cmac_port} {
        dict set axis_egress_switch_config "CONFIG.M[format %02d $j]_AXIS_BASETDEST" "0x0000000$i"
        dict set axis_egress_switch_config "CONFIG.M[format %02d $j]_AXIS_HIGHTDEST" "0x0000000$i"
        incr j
    }
    incr i
}

set_property -dict $axis_egress_switch_config [get_ips $axis_switch]
