set script_dir [file dirname [file normalize [info script]]]
set root_dir   [file normalize [file join $script_dir ..]]
set sof_file   [file join $root_dir quartus output_files fpga_sensor_control.sof]

if {![file exists $sof_file]} {
    puts "ERROR: compiled SOF not found: $sof_file"
    puts "Run Quartus compilation first."
    exit 2
}

puts "Programming $sof_file over JTAG..."
exec quartus_pgm -m jtag -o "p;$sof_file"
