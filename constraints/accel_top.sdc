# Explicit units: nanoseconds and picofarads.
set_units -time ns -capacitance pF

# Initial target: 100 MHz. This is a target, not a measured result.
create_clock -name core_clk -period 10.0 [get_ports clk]

set_clock_uncertainty 0.10 [get_clocks core_clk]
set_clock_transition 0.10 [get_clocks core_clk]

# Assumed external interface timing.
# rst_n is synchronous and is included in these constraints.
set data_inputs [remove_from_collection [all_inputs] [get_ports clk]]

set_input_delay -max 2.0 -clock core_clk $data_inputs
set_input_delay -min 0.2 -clock core_clk $data_inputs
set_input_transition 0.10 $data_inputs

set_output_delay -max 2.0 -clock core_clk [all_outputs]
set_output_delay -min 0.2 -clock core_clk [all_outputs]

# Assumed output load: 10 fF per output.
set_load 0.01 [all_outputs]
