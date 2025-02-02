if { [llength $argv] < 4 } {
    error "Usage: vivado -mode tcl program_mcs.tcl --tclargs <HW_SERVER> <DEVICE_NAME> <MCS_FILE> <FLASH_PART>"
}

set HW_SERVER   [lindex $argv 0]
set DEVICE_NAME [lindex $argv 1]
set MCS_FILE    [lindex $argv 2]
set FLASH_PART  [lindex $argv 3]

open_hw_manager
connect_hw_server -url $HW_SERVER -allow_non_jtag
open_hw_target

set device [lindex [get_hw_devices $DEVICE_NAME] 0]
current_hw_device [get_hw_devices $DEVICE_NAME]
refresh_hw_device -update_hw_probes false $device

create_hw_cfgmem -hw_device $device [lindex [get_cfgmem_parts $FLASH_PART] 0]
set cfgmem [get_property PROGRAM.HW_CFGMEM $device]

array set prog_props {
   BLANK_CHECK 0
   ERASE 1
   CFG_PROGRAM 1
   VERIFY 1
   CHECKSUM 0
}

foreach {prop value} [array get prog_props] {
   set_property PROGRAM.$prop $value $cfgmem
}
refresh_hw_device $device

set_property PROGRAM.ADDRESS_RANGE {use_file} $cfgmem
set_property PROGRAM.FILES [list $MCS_FILE] $cfgmem
set_property PROGRAM.PRM_FILE {} $cfgmem
set_property PROGRAM.UNUSED_PIN_TERMINATION {pull-none} $cfgmem

foreach {prop value} [array get prog_props] {
   set_property PROGRAM.$prop $value $cfgmem
}

startgroup 
create_hw_bitstream -hw_device $device [get_property PROGRAM.HW_CFGMEM_BITFILE $device]
program_hw_devices $device
refresh_hw_device $device
program_hw_cfgmem -hw_cfgmem $cfgmem
endgroup
