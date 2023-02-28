`ifndef FORMAT_SVH
`define FORMAT_SVH

//------------------------------------------------------------------------------
function automatic string bin_bs_to_string(uvm_bitstream_t value, int size,
    string radix_str = "0b"
);
    bin_bs_to_string = "";

    for (int i = 0; i < size; i++) begin
        if (value[i])
            bin_bs_to_string = {"1", bin_bs_to_string};
        else
            bin_bs_to_string = {"0", bin_bs_to_string};
    end

    bin_bs_to_string = {radix_str, bin_bs_to_string};
endfunction

//------------------------------------------------------------------------------
function automatic string bin_int_to_string(uvm_integral_t value, int size,
    string radix_str = "0b"
);
    bin_int_to_string = "";

    for (int i = 0; i < size; i++) begin
        if (value[i])
            bin_int_to_string = {"1", bin_int_to_string};
        else
            bin_int_to_string = {"0", bin_int_to_string};
    end

    bin_int_to_string = {radix_str, bin_int_to_string};
endfunction

//------------------------------------------------------------------------------
function automatic string oct_bs_to_string(uvm_bitstream_t value, int size,
    string radix_str = "0o"
);
    int n = (size - 1) / 3 + 1;
    oct_bs_to_string = "";

    for (int i = 0; i < n; i++) begin
        bit [2:0] v = (value >> (i * 3));
        $swrite(oct_bs_to_string, "%0o%s", v, oct_bs_to_string);
    end

    oct_bs_to_string = {radix_str, oct_bs_to_string};
endfunction

//------------------------------------------------------------------------------
function automatic string oct_int_to_string(uvm_integral_t value, int size,
    string radix_str = "0o"
);
    int n = (size - 1) / 3 + 1;
    oct_int_to_string = "";

    for (int i = 0; i < n; i++) begin
        bit [2:0] v = (value >> (i * 3));
        $swrite(oct_int_to_string, "%0o%s", v, oct_int_to_string);
    end

    oct_int_to_string = {radix_str, oct_int_to_string};
endfunction

//------------------------------------------------------------------------------
function automatic string hex_bs_to_string(uvm_bitstream_t value, int size,
    string radix_str = "0x"
);
    int n = (size - 1) / 4 + 1;
    hex_bs_to_string = "";

    for (int i = 0; i < n; i++) begin
        bit [3:0] v = (value >> (i * 4));
        $swrite(hex_bs_to_string, "%0x%s", v, hex_bs_to_string);
    end

    hex_bs_to_string = {radix_str, hex_bs_to_string};
endfunction

//------------------------------------------------------------------------------
function automatic string hex_int_to_string(uvm_integral_t value, int size,
    string radix_str = "0x"
);
    int n = (size - 1) / 4 + 1;
    hex_int_to_string = "";

    for (int i = 0; i < n; i++) begin
        bit [3:0] v = (value >> (i * 4));
        $swrite(hex_int_to_string, "%0x%s", v, hex_int_to_string);
    end

    hex_int_to_string = {radix_str, hex_int_to_string};
endfunction

//------------------------------------------------------------------------------
function automatic string bitstream_to_string(uvm_bitstream_t value, int size,
    uvm_radix_enum radix = UVM_NORADIX, string radix_str = ""
);
    if (radix == UVM_DEC && value[size-1] === 1)
        return $sformatf("%0d", value);

    if ($isunknown(value)) begin
	    uvm_bitstream_t _t;
	    _t = 0;

	    for (int idx = 0; idx < size; idx++)
	        _t[idx] = value[idx];
	    value = _t;
  	end
    else begin
  	    value &= (1 << size) - 1;
    end

    case(radix)
        UVM_BIN:      return bin_bs_to_string(value, size, radix_str);
        UVM_OCT:      return oct_bs_to_string(value, size, radix_str);
        UVM_UNSIGNED: return $sformatf("%0s%0d", radix_str, value);
        UVM_STRING:   return $sformatf("%0s%0s", radix_str, value);
        UVM_TIME:     return $sformatf("%0s%0t", radix_str, value);
        UVM_DEC:      return $sformatf("%0s%0d", radix_str, value);
        default:      return hex_bs_to_string(value, size, radix_str);
    endcase
endfunction

//------------------------------------------------------------------------------
function automatic string integral_to_string(uvm_integral_t value, int size,
    uvm_radix_enum radix = UVM_NORADIX, string radix_str = ""
);
    if (radix == UVM_DEC && value[size-1] === 1)
        return $sformatf("%0d", value);

    if ($isunknown(value)) begin
	    uvm_integral_t _t;
	    _t = 0;

	    for (int idx = 0; idx < size; idx++)
	        _t[idx] = value[idx];
	    value = _t;
  	end
    else begin
  	    value &= (1 << size) - 1;
    end

    case(radix)
        UVM_BIN:      return bin_int_to_string(value, size, radix_str);
        UVM_OCT:      return oct_int_to_string(value, size, radix_str);
        UVM_UNSIGNED: return $sformatf("%0s%0d", radix_str, value);
        UVM_STRING:   return $sformatf("%0s%0s", radix_str, value);
        UVM_TIME:     return $sformatf("%0s%0t", radix_str, value);
        UVM_DEC:      return $sformatf("%0s%0d", radix_str, value);
        default:      return hex_int_to_string(value, size, radix_str);
    endcase
endfunction

`endif
