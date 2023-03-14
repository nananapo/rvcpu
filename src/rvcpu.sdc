//Copyright (C)2014-2023 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.8.07 Education
//Created Time: 2023-03-15 06:57:24
create_clock -name clk24MHz -period 41.667 -waveform {0 20.834} [get_ports {clk}]
report_max_frequency -mod_ins {core}
