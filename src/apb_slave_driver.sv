class apb_slave_driver;

	apb_slave_transaction slave_trans;
	mailbox #(apb_slave_transaction) gen_2_slave_drv;
	mailbox #(apb_slave_transaction) drv_2_ref;
	virtual apb_interface.slave_drv_cb vif;

	function new (mailbox #(apb_slave_transaction) gen_2_slave_drv, mailbox #(apb_slave_transaction) drv_2_ref, virtual apb_interface.slave_drv_cb vif);
		this.gen_2_slave_drv = gen_2_slave_drv;
		this.drv_2_ref = drv_2_ref;
		this.vif = vif;
	endfunction

	task run();
		for(int i=0;i<`num_of_transactions;i++) begin
			if(vif.PRESETn == 0) begin
				vif.slave_drv_cb.PRDATA <= 0;
				vif.slave_drv_cb.PREADY <= 0;
				vif.slave_drv_cb.PSLVERR <= 0;
				wait (vif.PRESETn == 1);
			end

			fork
				begin
					gen_2_slave_drv.get(slave_trans);
					drv_2_refput(slave_trans);

					@(vif.slave_drv_cb);
					

				

