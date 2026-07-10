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

					do
						@(vif.slave_drv_cb);
					while(!(vif.slave_drv_cb.PSEL === 1 && vif.slave_drv_cb.PENABLE === 0));


					gen_2_slave_drv.get(slave_trans);
					drv_2_ref.put(slave_trans);

					@(vif.slave_drv_cb);

					if(slave_trans.wait_states > 0) begin
						vif.slave_drv_cb.PREADY <= slave_trans.PREADY;
						repeat(slave_trans.wait_states) @(vif.slave_drv_cb);

					end

					if(vif.slave_drv_cb.PWRITE == 0)
						vif.slave_drv_cb.PRDATA <= slave_trans.PRDATA;
					vif.slave_drv_cb.PREADY <= ~(slave_trans.PREADY);
					vif.slave_drv_cb.PSLVERR <= slave_trans.PSLVERR;

					@(vif.slave_drv_cb);

					vif.slave_drv_cb.PSLVERR <= 0;
					vif.slave_drv_cb.PRDATA <= `hx;

					$display("[DRIVER - SLAVE] [%t] Transaction : %d Completed Transfer",$time,i+1);
				end

				begin
					wait (vif.PRESETn == 0);
				end

			join_any

			disable fork;

			if(vif.PRESETn == 0) begin
				$display("[DRIVER - SLAVE] [%t] Transaction No: %d Reset Asserted...",$time,i+1);
				vif.slave_drv_cb.PRDATA <= 0;
				vif.slave_drv_cb.PREADY <= 0;
				vif.slave_drv_cb.PSLVERR <= 0;
			end
		end
	endtask
endclass	
