#include <core.p4>
#include <xsa.p4>

// ****************************************************************************** //
// *************************** M E T A D A T A ********************************** //
// ****************************************************************************** //
struct metadata_t {
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

struct headers_t {
    ethernet_h ethernet;
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
        packet.extract(headers.ethernet);
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
