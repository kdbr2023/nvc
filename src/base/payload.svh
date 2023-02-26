`ifndef PAYLOAD_SVH
`define PAYLOAD_SVH

//=============================================================================
class Payload;
    int size;

    //---------------------------------------------------------------
    function new(Packet packet);
        if (packet == null)
            `fatal("TODO");

        m_packet = packet;
    endfunction

    //---------------------------------------------------------------
    function void slice(ref byte_t data[], int first_index, int last_index);
        // TODO: range checking
        int size = last_index - first_index + 1;
        int offset = m_payload_offset();
        update_size();

        data = {>>{m_data with [first_index+offset:last_index+offset]}};
    endfunction

    //===============================================================
    // Internals
    //===============================================================

    local Packet m_packet;
    local byte_t m_data[];
    local int    m_size;

    //---------------------------------------------------------------
    local function void m_update_size();
        if (m_size == size)
            return;

        m_size = size;
        // TODO: expand/reduce data array
    endfunction

    //---------------------------------------------------------------
    local function int m_payload_offset();
        return packet.payload_offset();
    endfunction
endclass

`endif

