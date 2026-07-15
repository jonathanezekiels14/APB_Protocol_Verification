`include "defines.svh"

module apb_assertions(
	input bit PCLK,
	input bit PRESETn,
	input logic PSEL,
	input logic PENABLE,
	input logic PREADY,
	input logic transfer,
	input logic [`ADDR_WIDTH-1:0] PADDR,
	input logic PWRITE,
	input logic [`DATA_WIDTH-1:0] PWDATA,
	input logic [(`DATA_WIDTH/8)-1:0] PSTRB
);

	property slave_busy;
		@(posedge PCLK) disable iff (!PRESETn)
		(PSEL && PENABLE && !PREADY) |=> (PSEL && PENABLE && $stable(PADDR) && $stable(PWRITE));
	endproperty

	ERR_SLAVE_BUSY: assert property (slave_busy)
	else
		$error("[SVA FAIL] Master altered PADDR or PWRITE during wait State");

	property data_stable;
		@(posedge PCLK) disable iff (!PRESETn)
		(PSEL === 1 && PENABLE === 1 && PWRITE === 1 && PREADY === 0) |=> ($stable(PWDATA) && $stable(PSTRB));
	endproperty

	A_DATA_STABLE: assert property (data_stable)
	else
		$error("[SVA FAIL] Data from Master was not Stable during PWRITE");

	property check_access;
		@(posedge PCLK) disable iff (!PRESETn)
		(PSEL===1 && PENABLE===0) |=> (PSEL===1 && PENABLE===1);
	endproperty

	A_CHECK_ACCESS: assert property (check_access)
	else
		$error("[SVA FAIL] PENABLE was not asserted after PSEL");

	property check_idle;
		@(posedge PCLK) disable iff(!PRESETn)
		$rose(transfer) |=> PSEL;
	endproperty

	A_IDLE: assert property (check_idle)
	else
		$error("[SVA FAIL] PSEL was not Asserted once transfer came");
        
	localparam wait_cycles = 100;
	property check_pready;
		@(posedge PCLK) disable iff (!PRESETn)
		(PSEL && !PENABLE) |=> ##[1:wait_cycles] PREADY;
	endproperty

	A_PREADY_CAME: assert property (check_pready)
	else
		$error("[SVA FAIL] BUS DEADLOCK");

endmodule
