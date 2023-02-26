`ifndef PACKET_SVH
`define PACKET_SVH

import uvm_pkg::*;
`include "uvm_macros.svh"

typedef class Packet;
typedef class EtherPacket;

typedef bit [7:0] u8_t;
typedef u8_t byte_t;

// TODO: uvm_queue
typedef Packet packet_queue_t[$];

//=============================================================================
class PacketData;
    byte_t data[];

    function int size();
        return data.size();
    endfunction

    function void delete();
        data.delete();
    endfunction
endclass

//=============================================================================
class TablePacketPrinter extends uvm_printer;
    /*local*/ bit disabled[string];
    /*local*/ //text_style_t colored[string];

    int depth = 0;

    //-------------------------------------------------------------------------
    function new();
        knobs.type_name = 0;
        knobs.size = 0;
    endfunction

    //-------------------------------------------------------------------------
    function bit is_disabled(string path);
        foreach (disabled[key]) begin
            if (uvm_is_match(key, path)) begin
                return 1;
            end
        end

        return 0;
    endfunction

    //-------------------------------------------------------------------------
    function void add_filter(string filter);
        if (disabled.exists(filter))
            return;

        disabled[filter] = 1;
    endfunction

    //-------------------------------------------------------------------------
    function void delete_filter(string filter);
        foreach (disabled[key]) begin
            if (uvm_is_match(filter, key)) begin
                disabled.delete(key);
            end
        end
    endfunction

    //-------------------------------------------------------------------------
    static function int find_sep(string path);
        if (path.len < 2)
            return -1;

        for (int i = 0; i < (path.len - 1); i++)
            if ((path[i] == ":") && (path[i+1] == ":")) begin
                return i;
            end

        return -1;
    endfunction

    //-------------------------------------------------------------------------
    static function void split(string name, output string path[$]);
        string s = name;
        int sep_pos = find_sep(name);

        while (sep_pos != -1) begin
            path.push_back(s.substr(0, sep_pos - 1));
            s = s.substr(sep_pos + 2, s.len - 1);
            sep_pos = find_sep(s);
        end

        path.push_back(s);
    endfunction

    //-------------------------------------------------------------------------
    function void print_field(
        string name,
        uvm_bitstream_t value,
        int size,
        uvm_radix_enum radix = UVM_NORADIX,
        byte scope_separator = ".",
        string type_name = ""
    );
        if (is_disabled(name))
            return;

        //super.print_field(name, value, size, radix, scope_separator, type_name);
    endfunction
endclass

//=============================================================================
class Parser;
    local PacketData m_data;
    local int m_count;
    local bit m_error;

    function new(PacketData data);
        m_data = data;
        m_count = 0;
        m_error = 0;
    endfunction

    function void parse(output uvm_bitstream_t field, input int size);
        if (m_data.size < m_count + size) begin
            m_error = 1;
            return;
        end

        for (int i = m_count; i < (m_count + size); i++)
            field = {field, m_data.data[i]};

        m_count += size;
    endfunction

    function void finish();
        if (m_error != 0)
            return;

        if (m_data.size == m_count) begin
            m_data.delete();
        end
        else begin
            int size = m_data.size();
            m_data.data = {>>{m_data.data with [m_count:size-1]}};
        end
    endfunction

    function bit status();
        return (m_error == 0);
    endfunction
endclass

//=============================================================================
virtual class Packet extends uvm_object;
    protected static packet_queue_t m_known_packets[uvm_object_wrapper];
    local static int m_max_parsing_level = 20;
    local static bit m_debug_mode = 0;

    //-------------------------------------------------------------------------
    function new(string name = "");
        super.new(name);
    endfunction

    //-------------------------------------------------------------------------
    static function void set_max_parsing_level(int level);
        m_max_parsing_level = level;
    endfunction

    //-------------------------------------------------------------------------
    static function void set_debug_mode(bit debug_mode);
        m_debug_mode = debug_mode;
    endfunction

    //-------------------------------------------------------------------------
    static function Packet parse(PacketData data);
        Packet parent = EtherPacket::new;
        Packet derived;
        int level = 0;
        Parser parser = new(data);

        forever begin
            parent.do_parse(parser);

            if (!parser.status)
                return null;

            derived = get_derived(parent);

            if (derived == null)
                break;

            parent = derived;
            level++;

            if (level > m_max_parsing_level) begin
                uvm_report_fatal("NVC/PACKET/PARSING",
                    $sformatf("Parsing level exceeds maximum value (%0d)", m_max_parsing_level));
            end
        end

        parser.finish();
        // TODO: set payload from parser.m_data.data

        return parent;
    endfunction

    //-------------------------------------------------------------------------
    local static function Packet get_derived(Packet parent);
        bit is_find = 0;
        packet_queue_t q = m_known_packets[parent.get_object_type];

        foreach (q[i]) begin
            Packet packet = q[i];

            if (packet.is_derived_from(parent)) begin
                if (m_debug_mode && is_find) begin
                    uvm_report_fatal("NVC/PACKET/PARSING", "More than one parsing variant");
                end
                else begin
                    Packet derived;

                    $cast(derived, packet.clone);
                    derived.copy(parent);

                    return derived;
                end

                is_find = 1;
            end
        end

        return null;
    endfunction

    //-------------------------------------------------------------------------
    pure virtual function bit is_derived_from(Packet parent);
    pure virtual function void do_parse(Parser parser);
endclass

//=============================================================================
class EtherPacket extends Packet;
    `uvm_object_utils(EtherPacket)

    bit [47:0] dst_mac;
    bit [47:0] src_mac;
    bit [15:0] ether_type;

    //-------------------------------------------------------------------------
    function new(string name = "");
        super.new(name);
    endfunction

    //-------------------------------------------------------------------------
    function bit is_derived_from(Packet parent);
        return 0;
    endfunction

    //-------------------------------------------------------------------------
    function void do_parse(Parser parser);
        parser.parse({dst_mac, src_mac, ether_type}, 14);
    endfunction

    function void do_print(uvm_printer printer);
        printer.print_field("ethernet::dst_mac", dst_mac, $bits(dst_mac), UVM_HEX);
        printer.print_field("ethernet::src_mac", src_mac, $bits(src_mac), UVM_HEX);
        printer.print_field("ethernet::ether_type", ether_type, $bits(ether_type), UVM_HEX);
    endfunction

    function void do_copy(uvm_object rhs);
        EtherPacket _rhs;
        super.do_copy(rhs);

        $cast(_rhs, rhs);
        dst_mac = _rhs.dst_mac;
        src_mac = _rhs.src_mac;
        ether_type = _rhs.ether_type;
    endfunction

    //-------------------------------------------------------------------------
    // internal
    //-------------------------------------------------------------------------

    local static uvm_void _tmp = m_register_derived_packet();

    //-------------------------------------------------------------------------
    local static function uvm_void m_register_derived_packet();
        m_known_packets[EtherPacket::get_type] = '{};
        return null;
    endfunction
endclass

//=============================================================================
class Ip4Packet extends EtherPacket;
    `uvm_object_utils(Ip4Packet)

    bit [7:0] protocol;

    function new(string name = "");
        super.new(name);
    endfunction

    //-------------------------------------------------------------------------
    virtual function bit is_derived_from(Packet parent);
        EtherPacket ether;

        if (!$cast(ether, parent))
            return 0;

        return (ether.ether_type == 16'h0800);
    endfunction

    //-------------------------------------------------------------------------
    function void do_parse(Parser parser);
        parser.parse(protocol, 1);
    endfunction

    //-------------------------------------------------------------------------
    function void do_print(uvm_printer printer);
        super.do_print(printer);
        printer.print_field("ipv4::protocol", protocol, $bits(protocol), UVM_DEC);
    endfunction

    //-------------------------------------------------------------------------
    // implemented by macro
    //-------------------------------------------------------------------------

    local static uvm_void _tmp = m_register_derived_packet();

    //-------------------------------------------------------------------------
    local static function uvm_void m_register_derived_packet();
        Ip4Packet tmp = new;

        m_known_packets[EtherPacket::get_type].push_back(tmp);
        m_known_packets[Ip4Packet::get_type] = '{};

        return null;
    endfunction
endclass

//=============================================================================
class CustomPacket extends Ip4Packet;
    `uvm_object_utils(CustomPacket)

    function new(string name = "");
        super.new(name);
    endfunction

    local static uvm_void _tmp = set_transport();

    local static function uvm_void set_transport();
        CustomPacket tmp = new;
        m_known_packets[Ip4Packet::get_type].push_back(tmp);
        m_known_packets[CustomPacket::get_type] = '{};
        return null;
    endfunction

    //-------------------------------------------------------------------------
    virtual function bit is_derived_from(Packet parent);
        Ip4Packet ip4;
        if (!$cast(ip4, parent)) begin
            // `uvm_error
            return 0;
        end

        return (ip4.protocol == '1);
    endfunction

    function bit parse_data(ref byte_t data[]);
        return 0;
    endfunction
endclass

//*****************************************************************************
class Test;
    static function void test();
        int x = 0;
        x++;
        $display("x = %0d", x);
    endfunction
endclass

module tb;
    initial begin
        automatic PacketData data = new;
        automatic Packet pkt;
        automatic TablePacketPrinter printer = new;

        data.data = '{'h1A, 'h2B, 'h3C, 'h4D, 'h5E, 'h6F, 'h70, 'h71, 'h72, 'h73, 'h74, 'h75, 'h08, 'h00, 'h56, 'h78};
        pkt = Packet::parse(data);

        //printer.disabled["ethernet::*"] = 1;
        //pkt.print(printer);
    end
endmodule

`endif
