package require ::quartus::project

set script_dir [file dirname [file normalize [info script]]]
set root_dir   [file normalize [file join $script_dir ..]]
set proj_dir   [file join $root_dir quartus]
file mkdir $proj_dir
cd $proj_dir

set project_name fpga_sensor_smoke
project_new $project_name -overwrite

set_global_assignment -name FAMILY "MAX 10"
set_global_assignment -name DEVICE 10M50DAF484C7G
set_global_assignment -name TOP_LEVEL_ENTITY de10_lite_smoke_top
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files_smoke
set_global_assignment -name SYSTEMVERILOG_FILE [file join $root_dir rtl top de10_lite_smoke_top.sv]
set_global_assignment -name SDC_FILE [file join $root_dir constraints de10_lite.sdc]

export_assignments
project_close
puts "Created $proj_dir/$project_name.qpf"
puts "NEXT: quartus_sh -t scripts/import_de10_lite_pins.tcl $project_name <official-Golden-Top.qsf>"
