## Generated SDC file "SDR_1.out.sdc"

## Copyright (C) 2018  Intel Corporation. All rights reserved.
## Your use of Intel Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Intel Program License 
## Subscription Agreement, the Intel Quartus Prime License Agreement,
## the Intel FPGA IP License Agreement, or other applicable license
## agreement, including, without limitation, that your use is for
## the sole purpose of programming logic devices manufactured by
## Intel and sold by Intel or its authorized distributors.  Please
## refer to the applicable agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 18.1.0 Build 625 09/12/2018 SJ Lite Edition"

## DATE    "Mon May 31 18:01:34 2021"

##
## DEVICE  "10M08SAE144C8G"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {clk48} -period 20.833 -waveform { 0.000 10.416 } [get_ports {clk48}]


#**************************************************************
# Create Generated Clock
#**************************************************************

create_generated_clock -name {clk664} -source [get_pins {pll0|altpll_component|auto_generated|pll1|inclk[0]}] -multiply_by 83 -divide_by 60 -master_clock {clk48} [get_pins {pll0|altpll_component|auto_generated|pll1|clk[0]}] 


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

set_clock_uncertainty -rise_from [get_clocks {clk664}] -rise_to [get_clocks {clk664}]  0.070  
set_clock_uncertainty -rise_from [get_clocks {clk664}] -fall_to [get_clocks {clk664}]  0.070  
set_clock_uncertainty -fall_from [get_clocks {clk664}] -rise_to [get_clocks {clk664}]  0.070  
set_clock_uncertainty -fall_from [get_clocks {clk664}] -fall_to [get_clocks {clk664}]  0.070  


#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

