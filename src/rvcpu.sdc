//Copyright (C)2014-2023 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.8.07 Education
//Created Time: 2023-03-17 05:58:45
create_clock -name clk27MHz -period 37.037 -waveform {0 18.518} [get_ports {clk27MHz}]
report_max_frequency -mod_ins {core}
report_max_frequency -mod_ins {memory}
