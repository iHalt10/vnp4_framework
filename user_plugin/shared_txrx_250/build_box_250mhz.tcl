read_verilog -quiet -sv common/axi_lite_if.sv
read_verilog -quiet -sv common/axi_lite_if_s_connector.sv
read_verilog -quiet -sv common/axi_stream_if.sv
read_verilog -quiet -sv common/axi_stream_if_m_connector.sv
read_verilog -quiet -sv common/axi_stream_if_s_connector.sv
read_verilog -quiet -sv common/axi_stream_vnp4_if.sv
read_verilog -quiet -sv common/direction_pkg.sv

read_verilog -quiet -sv ingress_switch.sv
read_verilog -quiet -sv egress_switch.sv
read_verilog -quiet -sv p2p_250mhz.sv

source ip/vitis_net_p4_core.tcl
source ip/axis_ingress_switch.tcl
