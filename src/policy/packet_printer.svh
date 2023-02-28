`ifndef PACKET_PRINTER_SVH
`define PACKET_PRINTER_SVH

//=============================================================================
class PacketPrinter extends uvm_table_printer;
    local bit hidden_fields[string];
    /*local*/ //text_style_t colored[string];

    string header_name[int];   // key is depth

    //-------------------------------------------------------------------------
    function new();
        knobs.type_name = 0;
        knobs.size = 0;
        knobs.reference = 0;

        knobs.bin_radix = "0b";
        knobs.oct_radix = "0o";
        knobs.dec_radix = "";
        knobs.hex_radix = "0x";
        knobs.unsigned_radix = "";
    endfunction

    //-------------------------------------------------------------------------
    function bit is_field_disabled(string field_name);
        foreach (hidden_fields[key]) begin
            if (uvm_is_match(key, field_name))
                return 1;
        end

        return 0;
    endfunction

    //-------------------------------------------------------------------------
    function void disable_field(string field_name);
        if (hidden_fields.exists(field_name))
            return;

        hidden_fields[field_name] = 1;
    endfunction

    //-------------------------------------------------------------------------
    function void enable_field(string field_name);
        foreach (hidden_fields[key]) begin
            if (uvm_is_match(field_name, key))
                hidden_fields.delete(key);
        end
    endfunction

    //-------------------------------------------------------------------------
    local static function int find_sep(string path);
        if (path.len < 2)
            return -1;

        for (int i = 0; i < (path.len - 1); i++) begin
            if ((path[i] == ":") && (path[i+1] == ":"))
                return i;
        end

        return -1;
    endfunction

    //-------------------------------------------------------------------------
    local static function void split(string name, output string path[$]);
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
    function void print_field(string name, uvm_bitstream_t value, int size,
        uvm_radix_enum radix = UVM_NORADIX, byte scope_separator = ".",
        string type_name = ""
    );
        uvm_printer_row_info row_info;
        string path[$];
        string leaf_name;

        if (is_field_disabled(name))
            return;

        split(name, path);
        leaf_name = path[path.size-1];

        foreach (path[i]) begin
            bit is_leaf = (i == (path.size - 1));

            row_info.level = m_scope.depth() + i;
            row_info.name = path[i];

            if (is_leaf) begin
                row_info.val = bitstream_to_string(value, size, radix,
                    knobs.get_radix_str(radix));
            end
            else begin
                row_info.val = "";
            end

            if (is_leaf) begin
                if (leaf_name != "_size_")
                    m_rows.push_back(row_info);
            end
            else if (!header_name.exists(row_info.level) ||
                    header_name[row_info.level] != row_info.name) begin
                header_name[row_info.level] = row_info.name;

                if (leaf_name == "_size_")
                    row_info.name = $sformatf("%s (%0d bytes)", row_info.name, value);

                m_rows.push_back(row_info);
            end
        end
    endfunction

    //-------------------------------------------------------------------------
    function void print_field_int(string name, uvm_integral_t value, int size,
        uvm_radix_enum radix = UVM_NORADIX, byte scope_separator = ".",
        string type_name = ""
    );
        print_field(name, value, size, radix, scope_separator, type_name);
    endfunction

    //-------------------------------------------------------------------------
    function void print_object_header(string name, uvm_object value,
        byte scope_separator="."
    );
        uvm_printer_row_info row_info;
        uvm_component comp;

        if (name == "") begin
            if (value != null) begin
                if ((m_scope.depth() == 0) && $cast(comp, value)) begin
                    name = comp.get_full_name();
                end
                else begin
                    name = value.get_name();
                end
            end
        end
        
        if (name == "")
            name = "<unnamed>";

        m_scope.set_arg(name);
        row_info.level = m_scope.depth();

        if (row_info.level == 0 && knobs.show_root == 1)
	        row_info.name = value.get_full_name();
        else
	        row_info.name = adjust_name(m_scope.get(), scope_separator);

        row_info.type_name = (value != null) ?  value.get_type_name() : "object";
        row_info.size = "";
        row_info.val = knobs.reference ? uvm_object_value_str(value) : "";

        m_rows.push_back(row_info);
    endfunction
endclass

`endif
