package require ::quartus::project

if {$argc != 2} {
    puts "USAGE: quartus_sh -t scripts/import_de10_lite_pins.tcl <project-name> <official-Golden-Top.qsf>"
    exit 2
}

set project_name [lindex $argv 0]
set vendor_qsf   [file normalize [lindex $argv 1]]

if {![file exists $vendor_qsf]} {
    puts "ERROR: vendor QSF does not exist: $vendor_qsf"
    exit 2
}

set script_dir [file dirname [file normalize [info script]]]
set root_dir   [file normalize [file join $script_dir ..]]
set proj_dir   [file join $root_dir quartus]
cd $proj_dir

if {![file exists "${project_name}.qpf"]} {
    puts "ERROR: project not found: $proj_dir/${project_name}.qpf"
    exit 2
}

if {$project_name eq "fpga_sensor_smoke"} {
    set tokens {CLOCK_50 SW LEDR}
} else {
    set tokens {CLOCK_50 KEY SW LEDR HEX0 HEX1 HEX2 HEX3 HEX4 HEX5 GSENSOR VGA_R VGA_G VGA_B VGA_HS VGA_VS}
}

project_open $project_name
set fh [open $vendor_qsf r]
set imported 0
while {[gets $fh line] >= 0} {
    if {![regexp {^[[:space:]]*(set_location_assignment|set_instance_assignment)} $line]} {
        continue
    }

    set use_line 0
    foreach token $tokens {
        if {[string first $token $line] >= 0} {
            set use_line 1
            break
        }
    }

    if {$use_line} {
        # The caller supplies Terasic's trusted official QSF. Execute only
        # assignment commands for project-visible ports selected above.
        eval $line
        incr imported
    }
}
close $fh

export_assignments
project_close
puts "Imported $imported board pin/I/O assignments from $vendor_qsf into $project_name"
