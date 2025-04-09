
proc get_files {directory} {
    set result [list]
    foreach file [glob -nocomplain -directory $directory *] {
        if {[file isfile $file]} {
            lappend result $file
        }
    }
    foreach sub_directory [glob -nocomplain -directory $directory -type d *] {
        set sub_directory_files [get_files $sub_directory]
        set result [concat $result $sub_directory_files]
    }

    return $result
}
