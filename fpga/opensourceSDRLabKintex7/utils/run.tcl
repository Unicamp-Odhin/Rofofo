read_verilog -sv main.sv
read_verilog -sv ../../rtl/wrapper.sv
read_verilog -sv ../../rtl/async_fifo.sv

set_msg_config -id {Common 17-55} -new_severity {Warning}

# Adiciona o IP LiteDram
read_verilog litedram_core.v
#read_xdc     constraints/litedram_core.xdc
read_xdc     constraints/pinout_ddr3.xdc

read_verilog {/eda/litex/pythondata-cpu-vexriscv/pythondata_cpu_vexriscv/verilog/VexRiscv.v}

# Adiciona o IP clk_wiz_0
read_verilog ./ip/clk_wiz_0/clk_wiz_0_clk_wiz.v
read_verilog ./ip/clk_wiz_0/clk_wiz_0.v
read_xdc     ./ip/clk_wiz_0/clk_wiz_0.xdc

read_xdc constraints/pinout.xdc
#set_property PROCESSING_ORDER EARLY [get_files constraints/litedram_core.xdc]
set_property PROCESSING_ORDER EARLY [get_files constraints/pinout.xdc]
set_property PROCESSING_ORDER EARLY [get_files ./ip/clk_wiz_0/clk_wiz_0.xdc]
set_property PROCESSING_ORDER EARLY [get_files constraints/pinout_ddr3.xdc]

# synth
synth_design -top "top" -part "xc7k325tffg676-2" -directive default

# place and route
opt_design   -directive default
place_design -directive default


report_utilization -hierarchical -file reports/utilization_hierarchical_place.rpt
report_utilization -file               reports/utilization_place.rpt
report_io -file                        reports/io.rpt
report_control_sets -verbose -file     reports/control_sets.rpt
report_clock_utilization -file         reports/clock_utilization.rpt

route_design -directive default
phys_opt_design -directive default

report_timing_summary -no_header -no_detailed_paths
report_route_status -file                            reports/route_status.rpt
report_drc -file                                     reports/drc.rpt
report_timing_summary -datasheet -max_paths 10 -file reports/timing.rpt
report_power -file                                   reports/power.rpt

# write bitstream
write_bitstream -force "./build/out.bit"

exit