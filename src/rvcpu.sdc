//Copyright (C)2014-2023 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.8.07 Education
//Created Time: 2023-06-06 17:44:15
create_clock -name clk27MHz -period 37.037 -waveform {0 18.518} [get_ports {clk27MHz}]
report_max_frequency -mod_ins {core}
report_max_frequency -mod_ins {core/decodestage}
report_max_frequency -mod_ins {core/dataselectstage}
report_max_frequency -mod_ins {core/executestage}
report_max_frequency -mod_ins {core/csrstage}
report_max_frequency -mod_ins {core/memorystage}
report_max_frequency -mod_ins {core/wbstage}
report_max_frequency -mod_ins {memory}