# ===========================
# microwatt_wrapper_usb.sdc
# ===========================

# ---------------------------
# Core clock (SoC side)
# ---------------------------
set core_clk_port "ext_clk"
set core_clk_period 30 ;# 50 MHz

create_clock -name core_clk -period $core_clk_period [get_ports $core_clk_port]
set_propagated_clock [get_clocks core_clk]

# ---------------------------
# ULPI clock (PHY side)
# ---------------------------
# 60 MHz ULPI reference from external PHY
set ulpi_clk_period 16.667
create_clock -name ulpi_clk -period $ulpi_clk_period [get_ports {ulpi_clk60_i}]
set_propagated_clock [get_clocks ulpi_clk]

# ---------------------------
# JTAG clock (slow debug)
# ---------------------------
create_clock -name jtag_clk -period 100.0 [get_ports {jtag_tck}]
set_propagated_clock [get_clocks jtag_clk]

# ---------------------------
# Clock relationships
# ---------------------------
# Treat core, ULPI, and JTAG as asynchronous domains
set_clock_groups -asynchronous \
    -group [get_clocks core_clk] \
    -group [get_clocks ulpi_clk] \
    -group [get_clocks jtag_clk]

# ---------------------------
# Default IO delays (~10% of period)
# ---------------------------
set io_pct 0.1
set core_input_delay_value   [expr $core_clk_period * $io_pct]
set core_output_delay_value  [expr $core_clk_period * $io_pct]
set ulpi_input_delay_value   [expr $ulpi_clk_period * $io_pct]
set ulpi_output_delay_value  [expr $ulpi_clk_period * $io_pct]

puts "\[INFO\]: core IO delays = ${core_input_delay_value} / ${core_output_delay_value} ns"
puts "\[INFO\]: ulpi IO delays = ${ulpi_input_delay_value} / ${ulpi_output_delay_value} ns"

# ==========================================================
# CORE-DOMAIN I/O (relative to core_clk on ext_clk)
# ==========================================================

# Clock and resets
set_input_delay $core_input_delay_value   -clock [get_clocks core_clk] -add_delay \
    [get_ports {ext_clk}]
set_input_delay $core_input_delay_value   -clock [get_clocks core_clk] -add_delay \
    [get_ports {ext_rst}]
set_input_delay $core_input_delay_value   -clock [get_clocks core_clk] -add_delay \
    [get_ports {alt_reset}]

# Treat resets as async (don’t time from them into flops)
set_false_path -from [get_ports {ext_rst alt_reset}]
set_false_path -from [get_ports {ext_rst alt_reset}] -to [all_registers]

# UART0
set_input_delay  $core_input_delay_value  -clock [get_clocks core_clk] -add_delay \
    [get_ports {uart0_rxd}]
set_output_delay $core_output_delay_value -clock [get_clocks core_clk] -add_delay \
    [get_ports {uart0_txd}]

# SPI flash (SoC is master, all core_clk domain)
set_input_delay  $core_input_delay_value  -clock [get_clocks core_clk] -add_delay \
    [get_ports {spi_flash_sdat_i_q}]
set_output_delay $core_output_delay_value -clock [get_clocks core_clk] -add_delay \
    [get_ports {spi_flash_cs_n spi_flash_clk spi_flash_sdat_o_q spi_flash_sdat_oe_q[*]}]

# GPIO bundle (user-side, synchronous to core_clk)
set_input_delay  $core_input_delay_value  -clock [get_clocks core_clk] -add_delay \
    [get_ports {gpio_in_q[*]}]
set_output_delay $core_output_delay_value -clock [get_clocks core_clk] -add_delay \
    [get_ports {gpio_out_q[*] gpio_dir_q[*]}]

# JTAG outputs driven by core domain logic
set_output_delay $core_output_delay_value -clock [get_clocks core_clk] -add_delay \
    [get_ports {tck_o tms_o tdi_o trst_o expose_o jtag_tdo}]

# ==========================================================
# JTAG-DOMAIN INPUTS (relative to jtag_clk)
# ==========================================================
# JTAG inputs from external debugger
foreach sig {jtag_tck jtag_tdi jtag_tms jtag_trst} {
    set_input_delay 10.0 -clock [get_clocks jtag_clk] -add_delay [get_ports $sig]
}

# Don’t try to time JTAG clock into core/ULPI flops
set_false_path -from [get_ports jtag_tck]

# ==========================================================
# ULPI-DOMAIN I/O (relative to ulpi_clk)
# ==========================================================

# ULPI inputs from PHY
set_input_delay $ulpi_input_delay_value -clock [get_clocks ulpi_clk] -add_delay \
    [get_ports {ulpi_clk60_i}]
set_input_delay $ulpi_input_delay_value -clock [get_clocks ulpi_clk] -add_delay \
    [get_ports {ulpi_dir_i ulpi_nxt_i ulpi_data_out_i[*]}]

# ULPI outputs to PHY
set_output_delay $ulpi_output_delay_value -clock [get_clocks ulpi_clk] -add_delay \
    [get_ports {ulpi_data_in_o[*] ulpi_stp_o}]

# ==========================================================
# Global synthesis / timing constraints
# ==========================================================

# Default fanout limit
set_max_fanout 6 [current_design]

# Load / drive assumptions
set_driving_cell -lib_cell "sky130_fd_sc_hd__buf_2" -pin "A" [all_inputs]
set_load 0.005 [all_outputs]

# Clock uncertainty and transition on core clock
set_clock_uncertainty 0.2 [get_clocks core_clk]
set_clock_transition 0.1  [get_clocks core_clk]

# A bit of generic OCV derating
set_timing_derate -early 0.95
set_timing_derate -late 1.05


