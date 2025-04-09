if { [llength $argv] < 1 } {
    error "Usage: vivado -mode tcl get_devices.tcl --tclargs <HW_SERVER>"
}

set HW_SERVER [lindex $argv 0]

open_hw_manager
connect_hw_server -url $HW_SERVER -allow_non_jtag
open_hw_target

set devices [get_hw_devices]
set device_count [llength $devices]

puts "============================================================"

if {$device_count == 0} {
    puts "No devices found."
} else {
    puts "Number of devices detected: $device_count"
    for {set i 0} {$i < $device_count} {incr i} {
        set device [lindex $devices $i]
        set device_name [get_property NAME $device]
        puts "\[[expr {$i + 1}]\] DEVICE_NAME = $device_name"
    }
}
