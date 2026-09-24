# Run these commands in the configured university tcsh session.
# Load the approved Cadence setup separately; retain its container aliases.
# Run from the root of ai_accel_pd after importing all six source files.
# Check each command's output before proceeding. This is a command guide.
mkdir -p runs/mac runs/array runs/controller
cd runs/mac
xrun -64bit -sv ../../rtl/mac_int8.sv ../../tb/tb_mac_int8.sv -top tb_mac_int8 -l mac_sim.log
cd ../array
xrun -64bit -sv ../../rtl/mac_int8.sv ../../rtl/mac_array_4x4.sv ../../tb/tb_mac_array_4x4.sv -top tb_mac_array_4x4 -l array_sim.log
cd ../controller
xrun -64bit -sv ../../rtl/mac_int8.sv ../../rtl/mac_array_4x4.sv ../../rtl/matmul_4x4.sv ../../tb/tb_matmul_4x4.sv -top tb_matmul_4x4 -l controller_sim.log
cd ../..
