if { [llength $argv] < 3 } {
    error "Usage: vivado -mode tcl program_mcs.tcl --tclargs <HW_SERVER> <DEVICE_NAME> <BIT_FILE>"
}

set HW_SERVER   [lindex $argv 0]
set DEVICE_NAME [lindex $argv 1]
set BIT_FILE    [lindex $argv 2]

open_hw_manager
connect_hw_server -url $HW_SERVER -allow_non_jtag
open_hw_target

set device [lindex [get_hw_devices $DEVICE_NAME] 0]
current_hw_device [get_hw_devices $DEVICE_NAME]
refresh_hw_device -update_hw_probes false $device

set_property PROBES.FILE {} $device
set_property FULL_PROBES.FILE {} $device
set_property PROGRAM.FILE $BIT_FILE $device
program_hw_devices $device
refresh_hw_device $device
