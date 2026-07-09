// Bridge Transaction
class apb_bridge_transaction;
	rand logic write_read;
	rand logic [`DATA_WIDTH-1:0] wdata_in;
	rand logic [`ADDR_WIDTH-1:0] addr_in;
	rand logic [(`DATA_WIDTH/8)-1:0] strb_in;
	
	bit error;
	bit transfer_done;

	constraint set_word {
		addr_in[1:0] == 2'b00;
	}

	constraint set_write_read{
		write_read dist{ 0 := 5, 1 := 5};
	}

endclass

// Slave Transaction
class apb_slave_transaction;
	rand int wait_states;
	rand bit PSLVERR;
	rand logic [`DATA_WIDTH-1:0] PRDATA;

	constraint set_wait{
		wait_states dist {0 := 80, [1:5] := 20}
	}

	constraint set_error{
		PLSVERR dist{ 0 := 95, 1:= 5};
	}

	constraint set_data{
		PRDATA inside {[0:255]};
	}

endclass

// Middle Ground Transaction
class apb_transaction;
	bit [`ADDR_WIDTH-1:0] PADDR;
	bit PWRITE;
	bit [`DATA_WIDTH-1:0] PWDATA;
	bit [(`DATA_WIDTH/8)-1:0] PSTRB;
	bit [`DATA_WIDTH-1:0] PRDATA;
	bit PSLVERR;

	function void print(string tag = "");
		$display("[%s] ADDR: %0h | WRITE: %0b | WDATA: %0h | STRB: %0b | RDATA: %0h | ERR: %0b",tag, PADDR,PWRITE,PWDATA,PSTRB,PRDATA,PSLVERR);
	endfunction

	function void compare(apb_transaction expected);
		if(this.PADDR != expected.PADDR)
			return 0;
		if(this.PWRITE != expected.PWRITE)
			return 0;
		if(this.PSLVERR != expected.PSLVERR)
			return 0;

		if(this.PWRITE == 1) begin
			if(this.PWDATA != expected.PWDATA)
				return 0;
			if(this.PSTRB != expected.PSTRB)
				return 0;
		end

		return 1;
	endfunction
endclass

