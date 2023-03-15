//Copyright (C)2014-2023 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.8.07 Education
//Created Time: 2023-03-15 08:59:07
create_clock -name clk22MHz -period 45.455 -waveform {0 22.727} [get_ports {clk}]
report_max_frequency -mod_ins {core}
