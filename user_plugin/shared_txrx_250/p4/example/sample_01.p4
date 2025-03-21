#include <core.p4>
#include <xsa.p4>

const bit<16> TYPE_ETH_CUSTOM_0 = 0x88b5;
const bit<16> TYPE_ETH_CUSTOM_1 = 0x88b6;

// ****************************************************************************** //
// *************************** M E T A D A T A ********************************** //
// ****************************************************************************** //
struct metadata_t {
    // *********************** Custom Metadata ********************************** //
    // NOTE: Sharing user custom metadata between parser/control blocks
    bit<16> custom; // do not work
    // *********************** System Metadata (Do not delete) ****************** //
    bit<4>  egress_port;
    bit<4>  ingress_port;
    bit<16> packet_length;
}

// ****************************************************************************** //
// *************************** H E A D E R S  *********************************** //
// ****************************************************************************** //
header ethernet_h {
    bit<48> dst_addr;
    bit<48> src_addr;
    bit<16> ether_type;
}

header custom_h {
    bit<16> data;
}

struct headers_t {
    ethernet_h ethernet;
    custom_h   custom;
}

// ****************************************************************************** //
// *************************** P A R S E R  ************************************* //
// ****************************************************************************** //
parser MyParser(
    packet_in packet,
    out headers_t headers,
    inout metadata_t metadata,
    inout standard_metadata_t standard_metadata
) {
    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        metadata.custom = 1;
        packet.extract(headers.ethernet);
        transition select(headers.ethernet.ether_type) {
            TYPE_ETH_CUSTOM_0: parse_ethernet_custom_0;
            TYPE_ETH_CUSTOM_1: parse_ethernet_custom_1;
            default: accept;
        }
    }

    state parse_ethernet_custom_0 {
        metadata.custom = 2;
        transition accept;
    }

    state parse_ethernet_custom_1 {
        metadata.custom = 3;
        transition accept;
    }
}

// ****************************************************************************** //
// **************************  P R O C E S S I N G   **************************** //
// ****************************************************************************** //
control MyProcessing(
    inout headers_t headers,
    inout metadata_t metadata,
    inout standard_metadata_t standard_metadata
) {
    action drop() {
        standard_metadata.drop = 1;
    }

    apply {
        if (standard_metadata.parser_error != error.NoError) {
            drop();
            return;
        }

        headers.custom.data = metadata.packet_length - headers.custom.data;
        metadata.packet_length = metadata.packet_length + 2;
        headers.custom.setValid();

        if (metadata.ingress_port == 0) {
            metadata.egress_port = 8;
        } else {
            metadata.egress_port = 0;
        }
    }
} 

// ****************************************************************************** //
// ***************************  D E P A R S E R  ******************************** //
// ****************************************************************************** //
control MyDeparser(
    packet_out packet,
    in headers_t headers,
    inout metadata_t metadata,
    inout standard_metadata_t standard_metadata
) {
    apply {
        packet.emit(headers.ethernet);
        packet.emit(headers.custom);
    }
}

// ****************************************************************************** //
// *******************************  M A I N  ************************************ //
// ****************************************************************************** //
XilinxPipeline(
    MyParser(),
    MyProcessing(),
    MyDeparser()
) main;
