
import uvm_pkg::*;
`include "uvm_macros.svh"

import nvc_pkg::*;

module test;
    initial begin
        automatic PacketContent data = new;
        automatic Packet pkt;
        automatic PacketPrinter printer = new;

        data.data = '{'h1A, 'h2B, 'h3C, 'h4D, 'h5E, 'h6F, 'h70, 'h71, 'h72, 'h73, 'h74, 'h75, 'h08, 'h00, 'h56, 'h78};
        pkt = Packet::parse(data);

        //printer.disable_field("ethernet::*");
        pkt.print(printer);

        $display(">>> %s", hex_bs_to_string('hABC, 20));
    end
endmodule
