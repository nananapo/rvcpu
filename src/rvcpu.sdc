//Copyright (C)2014-2023 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.8.07 Education
//Created Time: 2023-01-19 01:33:02
create_clock -name clk20MHz -period 100 -waveform {0 50} [get_ports {clk}]
report_max_frequency -mod_ins {core}
