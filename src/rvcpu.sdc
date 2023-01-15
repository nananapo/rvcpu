//Copyright (C)2014-2023 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.8.07 Education
//Created Time: 2023-01-15 13:09:21
create_clock -name clk20MHz -period 50 -waveform {0 25} [get_ports {clk}]
report_max_frequency -mod_ins {core}
