class apb_monitor;
	
	apb_transaction mon_trans;
	mailbox #(apb_transaction) mon_2_scb;
	virtual apb_interface.MON vif;

	function new(mailbox #(apb_transaction) mon_2_scb,virtual apb_interface.MON vif);
		this.mon_2_scb = mon_2_scb;
		this.vif = vif;
	endfunction

	task run();
		for(int i=0;i<`num_of_transactions;i++) begin

			if(vif.PRESETn == 0) begin
				wait(vif.PRESETn == 1);
			end

			fork
				begin
					do begin
						@(vif.mon_cb);
					end while (vif.mon_cb.PSEL == 1 && vif.mon_cb.PREADY == 1 && vif.mon_cb.PENABLE == 1);

					mon_trans = new();

					mon_trans.PADDR = vif.mon_cb.PADDR;
					mon_trans.PWRITE = vif.mon_cb.PWRITE;
					mon_trans.PSTRB = vif.mon_cb.PSTRB;
					mon_trans.PSLVERR = vif.mon_cb.PSLVERR;

					if(vif.mon_cb.PWRITE == 1)
						mon_trans.PWDATA = vif.mon_cb.PWDATA);
					else 
						mon_trans.PRDATA = vif.mon_cb.PRDATA;
					mon_2_scb.put(mon_trans);

					$display("[MONITOR] [%t] Captured Transfer Transaction No: %d | ADDR: %h | PWRITE: %b",$time,i+1,mon_trans.PADDR,mon_trans.PWRITE);

				end

				begin
					wait(vif.PRESETn == 0);
				end

			join_any

			disable fork;
			if(vif.PRESETn == 0)
				$display("[MONITOR] [%t] Reset Asserted.. ",$time);
		end
	endtask
endclass
