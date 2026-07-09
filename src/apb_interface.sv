interface apb_interface (input bit PCLK, input bit PRESETn);
	// INPUTS
	logic transfer;
	logic write_read;
	logic [`ADDR_WIDTH-1:0] addr_in;
	logic [`DATA_WIDTH-1:0] w_data_in;
	logic [(`DATA_WIDTH/8)-1:0] strb_in;
	logic [`DATA_WIDTH-1:0] PRDATA;
	logic PREADY;
	logic PSVERR;
	
	// OUTPUTS
	logic PSELx;
	logic [(`DATA_WIDTH/8)-1:0] PSTRB;
	logic PENABLE;
	logic PWRITE;
	logic [`DATA_WIDTH-1:0] PWDATA;
	logic [`ADDR_WIDTH-1:0] PADDR;
	logic transfer_done;
	logic error;
	logic [`DATA_WIDTH-1:0] r_data_out;

	clocking 

