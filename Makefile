################################################################################
# Makefile for vivado Project
#
# quick usage:
#   $ make             # Build OpenNIC Shell including custom user plugins
#   $ make program-bit # Program FPGA with bitstream
#   $ make program-mcs # Program flash memory with MCS file
#   $ make p4-drivers  # Copy & Build p4-drivers
#   $ make sw          # Build table management sw based on p4-drivers
#   $ make log         # Show open-nic-shell/script/vivado.log
#   $ make ide         # Open vivado GUI
#   $ make clean-log   # Remove vivado log files
#   $ make clean       # Remove all generated files
################################################################################
.PHONY: all program-bit program-mcs p4-drivers sw log ide clean-log clean

###########################################################################
##### OpenNIC Build Script Options (open-nic-shell/script/build.tcl)
###########################################################################
## Build options
BOARD           := au50
TAG             := vnp4_nic
JOBS            := $(shell nproc)
SYNTH_IP        := 1
IMPL            := 1
POST_IMPL       := 1

USER_PLUGIN     := $(abspath user_plugin/rx_only_250)

## Design parameters
BUILD_TIMESTAMP := $(shell date +%y%m%d%H%M)
MIN_PKT_LEN     := 64
MAX_PKT_LEN     := 1514
NUM_PHYS_FUNC   := 1
NUM_QDMA        := 1
NUM_CMAC_PORT   := 1

###########################################################################
##### Program Options
###########################################################################
PROGRAM_HW_SERVER   := 127.0.0.1:3121
PROGRAM_DEVICE_NAME := xcu50_u55n_0
PROGRAM_FLASH_PART  := mt25qu01g-spi-x1_x2_x4

###########################################################################
##### Config Defines
###########################################################################
IMPLE_PATH := open-nic-shell/build/$(BOARD)_$(TAG)/open_nic_shell/open_nic_shell.runs/impl_1
BIT_FILE := $(IMPLE_PATH)/open_nic_shell.bit
MCS_FILE := $(IMPLE_PATH)/open_nic_shell.mcs

IP_PATH := open-nic-shell/build/$(BOARD)_$(TAG)/open_nic_shell/open_nic_shell.gen/sources_1/ip
SW_ROOT := $(abspath sw)
USER_PLUGIN_NAME := $(shell basename $(USER_PLUGIN))

###########################################################################
##### Tasks
###########################################################################
all:
	cd open-nic-shell/script && vivado -mode batch -source build.tcl -tclargs \
		-board $(BOARD) \
		-tag $(TAG) \
		-jobs $(JOBS) \
		-synth_ip $(SYNTH_IP) \
		-impl $(IMPL) \
		-post_impl $(POST_IMPL) \
		-user_plugin $(USER_PLUGIN) \
		-build_timestamp $(BUILD_TIMESTAMP) \
		-min_pkt_len $(MIN_PKT_LEN) \
		-max_pkt_len $(MAX_PKT_LEN) \
		-num_phys_func $(NUM_PHYS_FUNC) \
		-num_qdma $(NUM_QDMA) \
		-num_cmac_port $(NUM_CMAC_PORT)

program-bit: $(BIT_FILE)
	vivado -mode batch -source scripts/program_bit.tcl -tclargs $(PROGRAM_HW_SERVER) $(PROGRAM_DEVICE_NAME) $(BIT_FILE)

program-mcs: $(MCS_FILE)
	vivado -mode batch -source scripts/program_mcs.tcl -tclargs $(PROGRAM_HW_SERVER) $(PROGRAM_DEVICE_NAME) $(MCS_FILE) $(PROGRAM_FLASH_PART)

p4-drivers:
	@if [ "$(USER_PLUGIN_NAME)" = "rx_only_250" ]; then \
		cp -r $(IP_PATH)/rx_vitis_net_p4_core/src/sw/drivers p4-drivers && \
		cd p4-drivers && make INSTALL_ROOT=$(SW_ROOT)/$(USER_PLUGIN_NAME)/driver; \
	elif [ "$(USER_PLUGIN_NAME)" = "shared_txrx_250" ]; then \
		cp -r $(IP_PATH)/vitis_net_p4_core/src/sw/drivers p4-drivers && \
		cd p4-drivers && make INSTALL_ROOT=$(SW_ROOT)/$(USER_PLUGIN_NAME)/driver; \
	fi

sw: p4-drivers
	@if [ "$(USER_PLUGIN_NAME)" = "rx_only_250" ]; then \
		cd $(SW_ROOT)/$(USER_PLUGIN_NAME) && make; \
	elif [ "$(USER_PLUGIN_NAME)" = "shared_txrx_250" ]; then \
		cd $(SW_ROOT)/$(USER_PLUGIN_NAME) && make; \
	fi

log:
	cat open-nic-shell/script/vivado.log

ide: open-nic-shell/build/$(BOARD)_$(TAG)/open_nic_shell/open_nic_shell.xpr
	vivado open-nic-shell/build/$(BOARD)_$(TAG)/open_nic_shell/open_nic_shell.xpr &

clean-log:
	rm -f vivado*.log vivado*.jou vivado*.str

clean: clean-log
	rm -rf ./p4-drivers
	cd sw/rx_only_250 && make clean-all
	cd sw/shared_txrx_250 && make clean-all
	rm -rf open-nic-shell/build
	rm -f  open-nic-shell/script/vivado.log
