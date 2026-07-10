`include "apb_interface.sv"
module top;
	import apb_package::*;

	bit PCLK;
	bit PRESETn;

	initial begin
		forever #10 PCLK = ~PCLK;
	end

	initial begin
		@(posedge PCLK);
		PRESETn = 0;
		@(posedge PCLK);
		PRESETn = 1;

		#1000;
		PRESETn = 0;
		@(posedge PCLK);
		PRESETn = 1;
	end

	apb_interface intrf(PCLK,PRESETn);

	apb_master DUV(.PCLK(PCLK),
		.PRESETn(PRESETn),
		.PADDR(intrf.PADDR),
		.PSEL(intrf.PSEL),
		.PENABLE(intrf.PENABLE),
		.PWRITE(intrf.PWRITE),
		.PWDATA(intrf.PWDATA),
		.PSTRB(intrf.PSTRB),
		.PRDATA(intrf.PRDATA),
		.PREADY(intrf.PREADY),
		.PSLVERR(intrf.PSLVERR),
		.transfer(intrf.transfer),
		.write_read(intrf.write_read),
		.addr_in(intrf.addr_in),
		.wdata_in(intrf.wdata_in),
		.strb_in(intrf.strb_in),
		.rdata_out(intrf.rdata_out),
		.transfer_done(intrf.transfer_done),
		.error(intrf.error)
	);

	bind apb_master apb_assertions sva_inst(
		.PCLK(PCLK),
		.PRESETn(PRESETn),
		.PSEL(PSEL),
		.PENABLE(PENABLE),
		.PREADY(PREADY),
		.transfer(transfer)
	);

	apb_test tb;

	initial begin
		tb = new(intrf.BRIDGE_DRV,intrf.SLAVE_DRV,intrf.MON);
		tb.run();
		$finish;
	end
endmodule

