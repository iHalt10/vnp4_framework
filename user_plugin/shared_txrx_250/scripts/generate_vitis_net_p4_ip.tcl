if { [llength $argv] < 3 } {
    error "Usage: vivado -mode tcl generate_vitis_net_p4_ip.tcl --tclargs <BOARD_SETTING_TCL_FILE> <IP_PATH> <P4_FILE> <USER_EXTERNS_PATH>"
}

set BOARD_SETTING_TCL_FILE [lindex $argv 0]
set IP_PATH [lindex $argv 1]
set P4_FILE [lindex $argv 2]
set USER_EXTERNS_PATH [lindex $argv 3]
set vitis_net_p4 vitis_net_p4_core

if {![file exists "$IP_PATH"] || ![file isdirectory "$IP_PATH"]} {
    error "IP directory not found. (directory: $IP_PATH)"
}

if {![file exists $P4_FILE]} {
    error "P4 file not found. (file: $P4_FILE)"
}

if {[file exists "$IP_PATH/$vitis_net_p4"]} {
    file delete -force "$IP_PATH/$vitis_net_p4"
}

source "$BOARD_SETTING_TCL_FILE"

create_project -in_memory -part $part
create_ip -name vitis_net_p4 -vendor xilinx.com -library ip -module_name $vitis_net_p4 -dir $IP_PATH

set vitis_net_p4_config [dict create]
dict set vitis_net_p4_config CONFIG.P4_FILE              "$P4_FILE"
dict set vitis_net_p4_config CONFIG.AXIS_CLK_FREQ_MHZ    250.0
dict set vitis_net_p4_config CONFIG.CAM_MEM_CLK_FREQ_MHZ 250.0
dict set vitis_net_p4_config CONFIG.PKT_RATE             250.0
dict set vitis_net_p4_config CONFIG.TDATA_NUM_BYTES      64
dict set vitis_net_p4_config CONFIG.CAM_MEM_CLK_ENABLE   1
set_property -dict $vitis_net_p4_config [get_ips $vitis_net_p4]

if {[get_property CONFIG.S_AXI_ADDR_WIDTH [get_ips $vitis_net_p4]] == 0} {
    set_property CONFIG.S_AXI_ADDR_WIDTH 20 [get_ips $vitis_net_p4]
}

set_property CONFIG.USER_META_DATA_WIDTH 34 [get_ips $vitis_net_p4]
set_property CONFIG.RESTORE_METADATA_PORTS true [get_ips $vitis_net_p4]

generate_target all [get_ips $vitis_net_p4]

if {[get_property CONFIG.NUM_USER_EXTERNS [get_ips $vitis_net_p4]] == 0} {
    file mkdir "$IP_PATH/$vitis_net_p4/src/verilog/user_externs"
    set svh_file "$IP_PATH/$vitis_net_p4/src/verilog/user_externs/user_externs.svh"
    set fh [open $svh_file w]
    puts $fh "`ifndef USER_EXTERNS_SVH"
    puts $fh "`define USER_EXTERNS_SVH"
    puts $fh ""
    puts $fh "// `define ENABLED_USER_EXTERNS"
    puts $fh ""
    puts $fh "`endif // USER_EXTERNS_SVH"
    close $fh
} else {
    if {![file exists "$USER_EXTERNS_PATH"] || ![file isdirectory "$USER_EXTERNS_PATH"]} {
        error "User Externs Directory not found. (directory: $USER_EXTERNS_PATH)"
    }
    file link -symbolic "$IP_PATH/$vitis_net_p4/src/verilog/user_externs" "$USER_EXTERNS_PATH"
}
