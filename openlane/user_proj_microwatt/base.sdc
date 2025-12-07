# ===========================
# openframe_project_wrapper.sdc
# ===========================

# Environment variables
set clk_port "gpio_in[0]"
set clk_period 20.0 ;# 50 MHz (adjust as needed)
create_clock -name core_clk -period $clk_period [get_ports $clk_port]
set_propagated_clock [get_clocks core_clk]

# Default IO delay as % of clock
set io_pct 0.1
set input_delay_value  [expr $clk_period * $io_pct]
set output_delay_value [expr $clk_period * $io_pct]
puts "\[INFO\]: IO delays set to ${input_delay_value} ns"

# ===========================
# Core Inputs / Outputs
# ===========================

# Clock and reset
set_input_delay $input_delay_value  -clock [get_clocks core_clk] -add_delay [get_ports {gpio_in[0]}]
set_input_delay $input_delay_value  -clock [get_clocks core_clk] -add_delay [get_ports {gpio_in[1]}]

# UART
set_input_delay  $input_delay_value -clock [get_clocks core_clk] -add_delay [get_ports {gpio_in[2]}]   ;# RXD
set_output_delay $output_delay_value -clock [get_clocks core_clk] -add_delay [get_ports {gpio_out[13]}] ;# TXD

# SPI Flash
set_output_delay $output_delay_value -clock [get_clocks core_clk] -add_delay [get_ports {gpio_out[11]}] ;# CS#
set_output_delay $output_delay_value -clock [get_clocks core_clk] -add_delay [get_ports {gpio_out[12]}] ;# CLK
foreach i {7 8 9 10} {
    set_input_delay  $input_delay_value  -clock [get_clocks core_clk] -add_delay [get_ports {gpio_in[$i]}]
    set_output_delay $output_delay_value -clock [get_clocks core_clk] -add_delay [get_ports {gpio_out[$i]}]
}

# JTAG (optional second clock domain)
create_clock -name jtag_clk -period 100 [get_ports {gpio_in[3]}]
set_propagated_clock [get_clocks jtag_clk]
set_clock_groups -name exclusive_clocks -logically_exclusive \
    -group [get_clocks core_clk] -group [get_clocks jtag_clk]
foreach sig {gpio_in[3] gpio_in[4] gpio_in[5] gpio_in[6]} {
    set_input_delay 10 -clock [get_clocks jtag_clk] -add_delay [get_ports $sig]
}
set_output_delay 10 -clock [get_clocks jtag_clk] -add_delay [get_ports {gpio_out[14]}]

# GPIO bus for user extensions (used by microwatt)
foreach i {15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43} {
    set_input_delay  $input_delay_value  -clock [get_clocks core_clk] -add_delay [get_ports gpio_in[$i]]
    set_output_delay $output_delay_value -clock [get_clocks core_clk] -add_delay [get_ports gpio_out[$i]]
}

# ===========================
# Global synthesis constraints
# ===========================

# Default fanout limit
set_max_fanout 6 [current_design]

# Load / drive assumptions
set_driving_cell -lib_cell "sky130_fd_sc_hd__buf_2" -pin "A" [all_inputs]
set_load 0.005 [all_outputs]

# Clock uncertainty and transition
set_clock_uncertainty 0.2 [get_clocks core_clk]
set_clock_transition 0.1 [get_clocks core_clk]

# Timing derates for OCV (On-Chip Variation)
set_timing_derate -early 0.95
set_timing_derate -late 1.05

puts "\[INFO\]: base.sdc for openframe_project_wrapper loaded."
