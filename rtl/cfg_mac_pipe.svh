// Build option for experiment E4 (pipelined MAC). Put this file FIRST in the
// file list to build the pipelined version; leave it out for the original.
//   Genus  : read_hdl -sv [list rtl/cfg_mac_pipe.svh rtl/mac_int8.sv ...]
//   Xcelium: xrun -sv rtl/cfg_mac_pipe.svh rtl/mac_int8.sv ...   (or +define+MAC_PIPE=1)
`define MAC_PIPE 1
