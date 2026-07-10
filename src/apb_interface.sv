`include "defines.svh"
interface apb_interface (input bit PCLK, input bit PRESETn);
	// Brigde Signals
	logic transfer;
	logic write_read;
	logic [`ADDR_WIDTH-1:0] addr_in;
	logic [`DATA_WIDTH-1:0] wdata_in;
	logic [(`DATA_WIDTH/8)-1:0] strb_in;
	logic error;
	logic [`DATA_WIDTH-1:0] rdata_out;
	logic transfer_done;

	// Slave Signals
	logic PSEL;
	logic PENABLE;
	logic PWRITE;
	logic [(`DATA_WIDTH/8)-1:0] PSTRB;
	logic [`DATA_WIDTH-1:0] PWDATA;
	logic [`ADDR_WIDTH-1:0] PADDR;
	logic [`DATA_WIDTH-1:0] PRDATA;
	logic PREADY;
	logic PSLVERR;

	// Clocking Blocks
	
	clocking bridge_drv_cb @(posedge PCLK);
		default input #1step output #1ns;
		output transfer,write_read,addr_in,wdata_in,strb_in;
		input error,rdata_out,transfer_done;
	endclocking 

	clocking slave_drv_cb @(posedge PCLK);
		default input #1step output #1ns;
		output PRDATA,PREADY,PSLVERR;
		input PSTRB,PSEL,PENABLE,PWRITE,PWDATA,PADDR;
	endclocking
	
	clocking mon_cb @(posedge PCLK);
		default input #1step;
		input transfer,write_read,addr_in,wdata_in, strb_in, rdata_out, transfer_done, error;
		input PADDR,PSEL,PENABLE,PWRITE,PWDATA,PSTRB,PRDATA,PREADY,PSLVERR;
	endclocking

	modport BRIDGE_DRV (clocking bridge_drv_cb, input PRESETn);
	modport SLAVE_DRV (clocking slave_drv_cb, input PRESETn);
	modport MON (clocking mon_cb,input PRESETn);

endinterface



