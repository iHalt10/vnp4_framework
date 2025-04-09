source "$user_plugin/scripts/get_files.tcl"

set vitis_net_p4_core_ip "$build_dir/vivado_ip/custom/vitis_net_p4_core"

if {![file exists "$vitis_net_p4_core_ip/vitis_net_p4_core.xci"]} {
    error "Please execute 'make generate-p4-ip' and 'make alias-p4-ip'."
}

read_ip -quiet "$vitis_net_p4_core_ip/vitis_net_p4_core.xci"
lappend include_dirs "$vitis_net_p4_core_ip/src/verilog"

set user_externs_path "$vitis_net_p4_core_ip/src/verilog/user_externs"
set files [get_files "$user_externs_path"]

foreach file $files {
    set ext [file extension $file]
    if {$ext == ".sv" || $ext == ".v" || $ext == ".svh" || $ext == ".vh"} {
        puts "Loading Verilog file: $file"
        read_verilog -quiet $file
    } elseif {$ext == ".tcl"} {
        puts "Executing TCL script: $file"
        if {[catch {source $file} result]} {
            error "Error: $result"
        }
    } elseif {$ext == ".xdc"} {
        puts "Loading constraint file: $file"
        read_xdc $file
    } else {
        puts "Unsupported extension ($ext): $file"
    }
}
