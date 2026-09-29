# Source from the repository root in an already configured Cadence tcsh.
# Example: source scripts/run_top.tcsh
# For the pipeline variant: setenv PIPE 1 before sourcing.
set cfg = ()
set variant = baseline
if ( $?PIPE ) then
  if ( "$PIPE" == "1" ) then
    set cfg = ( rtl/cfg_mac_pipe.svh )
    set variant = pipe
  endif
endif
mkdir -p runs/top_$variant
xrun -64bit -sv $cfg rtl/mac_int8.sv rtl/mac_array_4x4.sv rtl/matmul_4x4_k.sv rtl/operand_memory.sv rtl/operand_reader.sv rtl/accel_top.sv tb/tb_accel_top.sv -top tb_accel_top -xmlibdirname runs/top_$variant/identity.d -l runs/top_$variant/identity.log
if ( $status != 0 ) then
  echo "Identity simulation failed; inspect runs/top_$variant/identity.log"
else
  xrun -64bit -sv $cfg rtl/mac_int8.sv rtl/mac_array_4x4.sv rtl/matmul_4x4_k.sv rtl/operand_memory.sv rtl/operand_reader.sv rtl/accel_top.sv tb/tb_accel_top_accum.sv -top tb_accel_top_accum -xmlibdirname runs/top_$variant/accum.d -l runs/top_$variant/accum.log
endif
