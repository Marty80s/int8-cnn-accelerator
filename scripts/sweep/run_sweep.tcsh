# ---------------------------------------------------------------------------
# run_sweep.tcsh - synthesize accel_top at a list of clock periods and
# collect one summary table. Run from the repo root in your Cadence tcsh:
#
#   tcsh scripts/sweep/run_sweep.tcsh                  (default periods)
#   tcsh scripts/sweep/run_sweep.tcsh 3.0 2.8 2.6      (your own list, ns)
#
# Output: runs/sweep/sweep_summary[_pipe][_nocg].csv and one folder per period.
# Variants (set before running; defaults reproduce Run 2):
#   setenv PIPE 1   pipelined MAC  (E4)   -> folders p<period>_pipe
#   setenv CG 0     no clock gating (E2)   -> folders p<period>_nocg
# Tip: keep it running after you log off with
#   nohup tcsh scripts/sweep/run_sweep.tcsh >& runs/sweep/sweep.log &
# ---------------------------------------------------------------------------
set root = /home/tumberpl/int8-cnn-accelerator
if ( $#argv > 0 ) then
  set periods = ( $argv )
else
  # 143 to 500 MHz
  set periods = ( 7.0 5.0 4.0 3.33 2.86 2.5 2.22 2.0 )
endif

mkdir -p $root/runs/sweep
if ( ! $?PIPE ) setenv PIPE 0
if ( ! $?CG ) setenv CG 1
set sfx = ""
if ( $PIPE == 1 ) set sfx = "${sfx}_pipe"
if ( $CG == 0 ) set sfx = "${sfx}_nocg"

set sum = $root/runs/sweep/sweep_summary$sfx.csv
# (csh applies a redirect on a one-line if even when the test is false,
#  which emptied the summary on every rerun - so use a block if)
if ( ! -e $sum ) then
  echo "period_ns,freq_MHz,wns,area_um2,cells,power,runtime_s,pipe,cg" > $sum
endif

foreach p ( $periods )
  set d = $root/runs/sweep/p$p$sfx
  echo "=== period $p ns (PIPE=$PIPE CG=$CG) ==="
  mkdir -p $d
  cd $d
  rm -f result.csv
  setenv PERIOD $p
  genus -files $root/scripts/sweep/synth_sweep.tcl -log genus_p$p >& genus_p$p.stdout
  if ( -e result.csv ) then
    cat result.csv >> $sum
    cat result.csv
  else
    echo "$p,,FAILED,,,,,$PIPE,$CG" >> $sum
    echo "period $p FAILED - see $d/genus_p$p.log"
  endif
end

echo ""
echo "=== SWEEP SUMMARY ($sum) ==="
column -t -s, $sum
