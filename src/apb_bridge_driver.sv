class apb_bridge_driver;

	apb_bridge_transaction bridge_trans;

	virtual apb_interface.BRIDGE_DRV vif;

	mailbox #(apb_bridge_transaction) gen_2_bridge_drv;
	mailbox #(apb_bridge_transaction) drv_2_ref;

	function new(mailbox #(apb_bridge_transaction) gen_2_bridge_drv, mailbox #(apb_bridge_transaction) drv_2_ref, virtual apb_interface.BRIDGE_DRV vif);
		this.gen_2_bridge_drv = gen_2_bridge_drv;
		this.drv_2_ref = drv_2_ref;
		this.vif = vif;
	endfunction

	task run();
		for(int i=0;i<`num_of_transactions;i++) begin

			if(vif.PRESETn == 0) begin
				vif.bridge_drv_cb.write_read <= 0;
				vif.bridge_drv_cb.transfer <= 0;
				vif.bridge_drv_cb.addr_in <= 0;
				vif.bridge_drv_cb.wdata_in <= 0;
				vif.bridge_drv_cb.strb_in <= 0;
				wait (vif.PRESETn == 1);
			end

			fork
				begin
					gen_2_bridge_drv.get(bridge_trans);
					drv_2_ref.put(bridge_trans);

					@(vif.bridge_drv_cb);
					vif.bridge_drv_db.write_read <= bridge_trans.write_read;
					vif.bridge_drv_cb.addr_in <= bridge_trans.addr_in;
					vif.bridge_drv_cb.transfer <= bridge_trans.transfer;
					vif.bridge_drv_cb.wdata_in <= bridge_trans.wdata_in;
					vif.bridge_drv_cb.strb_in <= bridge_trans.strb_in;

					do begin
						@(vif.bridge_drv_cb);
					end while (vif.bridge_drv_cb.transfer_done == 0);

					if(bridge_trans.write_read == 0)
						bridge_trans.rdata_out = vif.bridge_drv_cb.rdata_out;  				
					bridge_trans.error = vif.bridge_drv_trans.error;
					vif.bridge_drv_cb.transfer <= ~(bridge_trans.transfer);
					$display("[DRIVER - BRIDGE] [%t] Transaction No: %d Completed Transfer",$time,i+1);
				end

				begin
					wait(vif.PRESETn == 0);
				end

			join_any

			disable fork;
			if(vif.PRESETn == 0) begin
				$display("[DRIVER - BRIDGE] [%t] Transaction No: %d Reset asserted...",$time,i+1);
				vif.bridge_drv_cb.write_read <= 0;
				vif.bridge_drv_cb.transfer <= 0;
				vif.bridge_drv_cb.addr_in <= 0;
				vif.bridge_drv_cb.wdata_in <= 0;
				vif.bridge_drv_cb.strb_in <= 0;
			end
		end
	endtask
endclass



