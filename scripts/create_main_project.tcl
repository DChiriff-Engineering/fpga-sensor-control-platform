package require ::quartus::project

set script_dir [file dirname [file normalize [info script]]]
set root_dir   [file normalize [file join $script_dir ..]]
set proj_dir   [file join $root_dir quartus]
file mkdir $proj_dir
cd $proj_dir

set project_name fpga_sensor_control
project_new $project_name -overwrite

set_global_assignment -name FAMILY "MAX 10"
set_global_assignment -name DEVICE 10M50DAF484C7G
set_global_assignment -name TOP_LEVEL_ENTITY fpga_sensor_control_top
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
set_global_assignment -name SDC_FILE [file join $root_dir constraints de10_lite.sdc]

set source_dirs [list \
    [file join $root_dir rtl common] \
    [file join $root_dir rtl acquisition] \
    [file join $root_dir rtl sensor] \
    [file join $root_dir rtl dsp] \
    [file join $root_dir rtl control] \
    [file join $root_dir rtl memory] \
    [file join $root_dir rtl display] \
    [file join $root_dir rtl top]]

foreach dir $source_dirs {
    foreach source [lsort [glob -nocomplain [file join $dir *.sv]]] {
        if {[file tail $source] ne "de10_lite_smoke_top.sv"} {
            set_global_assignment -name SYSTEMVERILOG_FILE $source
        }
    }
}

export_assignments
project_close
puts "Created $proj_dir/$project_name.qpf"
puts "NEXT: quartus_sh -t scripts/import_de10_lite_pins.tcl $project_name <official-Golden-Top.qsf>"
