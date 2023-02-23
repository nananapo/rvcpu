//Copyright (C)2014-2023 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.8.07 Education
//Created Time: 2023-01-19 15:13:30
create_clock -name clk27MHz -period 37.037 -waveform {0 18.518} [get_ports {clk}]
report_max_frequency -mod_ins {core}
