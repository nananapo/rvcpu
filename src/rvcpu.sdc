//Copyright (C)2014-2023 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.8.07 Education
//Created Time: 2023-03-17 00:57:16
create_clock -name clk -period 50 -waveform {0 25} [get_ports {clk}]
report_max_frequency -mod_ins {core}
report_max_frequency -mod_ins {memory}
report_max_frequency -mod_ins {txModule}