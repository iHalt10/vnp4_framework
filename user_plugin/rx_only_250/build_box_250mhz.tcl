read_verilog -quiet -sv common/axi_lite_if.sv
read_verilog -quiet -sv common/axi_lite_if_s_connector.sv
read_verilog -quiet -sv common/axi_stream_if.sv
read_verilog -quiet -sv common/axi_stream_if_m_connector.sv
read_verilog -quiet -sv common/axi_stream_if_s_connector.sv

read_verilog -quiet -sv p2p_250mhz.sv
source ip/rx_vitis_net_p4_core.tcl
