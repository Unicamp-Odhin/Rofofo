read_verilog -sv main.sv
read_verilog -sv ../../rtl/Rofofo.sv
read_verilog -sv ../../modules/I2S_Microphone/rtl/i2s_capture.sv
read_verilog -sv ../../modules/I2S_Microphone/rtl/sample_reduce.sv
read_verilog -sv ../../modules/I2S_Microphone/rtl/spi_slave.sv
read_verilog -sv ../../modules/I2S_Microphone/rtl/i2s.sv
read_verilog -sv ../../modules/I2S_Microphone/rtl/fir_filter.sv
read_verilog -sv ../../modules/DRAM_Wrapper/rtl/wrapper.sv
read_verilog -sv ../../modules/DRAM_Wrapper/rtl/async_fifo.sv
read_verilog -sv ../../modules/MFCC_Core/rtl/base2log.sv ../../modules/MFCC_Core/rtl/complex_pkg.sv ../../modules/MFCC_Core/rtl/dct.sv ../../modules/MFCC_Core/rtl/fft_radix2.sv ../../modules/MFCC_Core/rtl/fifo.sv ../../modules/MFCC_Core/rtl/hamming_window.sv ../../modules/MFCC_Core/rtl/mel.sv ../../modules/MFCC_Core/rtl/MFCC_Core.sv ../../modules/MFCC_Core/rtl/mfcc_pkg.sv ../../modules/MFCC_Core/rtl/pre_emphasis.sv ../../modules/MFCC_Core/rtl/window_buffer.sv

# Adiciona o IP LiteDram
read_verilog litedram_core.v
#read_xdc     constraints/litedram_core.xdc
read_xdc     constraints/pinout_ddr3.xdc

read_verilog ../../modules/thirdparty/VexRiscv.v
read_verilog ../../modules/thirdparty/VexiiRiscv.v

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
synth_design -top "top" -part "xc7k325tffg676-2"

# place and route
opt_design
place_design

report_utilization -hierarchical -file reports/utilization_hierarchical_place.rpt
report_utilization -file               reports/utilization_place.rpt
report_io -file                        reports/io.rpt
report_control_sets -verbose -file     reports/control_sets.rpt
report_clock_utilization -file         reports/clock_utilization.rpt

route_design

report_timing_summary -no_header -no_detailed_paths
report_route_status -file                            reports/route_status.rpt
report_drc -file                                     reports/drc.rpt
report_timing_summary -datasheet -max_paths 10 -file reports/timing.rpt
report_power -file                                   reports/power.rpt

# write bitstream
write_bitstream -force "./build/out.bit"

exit
