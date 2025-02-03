#include <core.p4>
#include <xsa.p4>

// ****************************************************************************** //
// *************************** S Y S T E M ************************************** //
// ****************************************************************************** //
struct metadata_t {
    bit<16> size;
    bit<4>  src_pf;
    bit<10> src_cmac;
    bit<4>  dst_pf;
    bit<10> dst_cmac;
    bit<1>  from_direction;
    bit<1>  to_direction;
}

const bit<1> DIRECTION_PF = 0;
const bit<1> DIRECTION_CMAC = 1;

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

    action replace_src(bit<48> addr) {
        headers.ethernet.src_addr = addr;
    }

    table mac_addrs {
        key     = { headers.ethernet.src_addr : exact; }
        actions = { replace_src; }
        size    = 8;
    }

    apply {
        if (standard_metadata.parser_error != error.NoError) {
            drop();
            return;
        }

        if (headers.ethernet.isValid()) {
            mac_addrs.apply();
        }

        if (metadata.from_direction == DIRECTION_PF) {
            metadata.dst_pf = 0;
            metadata.dst_cmac = 1;
            metadata.to_direction = DIRECTION_CMAC;
        } else {
            metadata.dst_pf = 1;
            metadata.dst_cmac = 0;
            metadata.to_direction = DIRECTION_PF;
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
