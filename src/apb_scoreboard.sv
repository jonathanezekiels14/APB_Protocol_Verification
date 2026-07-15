class apb_scoreboard;

	apb_transaction ref_trans;
	apb_transaction mon_trans;

	mailbox #(apb_transaction) ref_2_scb;
	mailbox #(apb_transaction) mon_2_scb;

	virtual apb_interface.MON vif;
	int pass_count;
	int fail_count;
	function new(mailbox #(apb_transaction) ref_2_scb, mailbox #(apb_transaction) mon_2_scb, virtual apb_interface.MON vif);
		this.ref_2_scb = ref_2_scb;
		this.mon_2_scb = mon_2_scb;
		this.vif = vif;
	endfunction

	task run();
		for(int i=0;i<`num_of_transactions;i++) begin
			if (vif.PRESETn == 0)
				wait(vif.PRESETn == 1);

			ref_2_scb.get(ref_trans);

			fork 
				begin
					mon_2_scb.get(mon_trans);
				end

				begin
					wait (vif.PRESETn == 0);
				end
			join_any

			disable fork;
			
			if(vif.PRESETn == 0)
				$display("[SCOREBOARD] [%0t] Reset Asserted Transaction No: %d",$time,i+1);
			else begin
				if(mon_trans.compare(ref_trans)) begin
					$display("[SCOREBOARD] [%0t] [PASS] Transaction No: %d MATCHED",$time,i+1);
					pass_count++;
				end

				else begin
					$error("[SCOREBOARD] [%0t] [FAIL] Transaction No: %d FAILED",$time,i+1);
					ref_trans.print("EXPECTED");
					mon_trans.print("ACTUAL");
					fail_count++;
				end
			end
		end

		$display("---------------------SUMMARY---------------------");
		$display("No. of Transactions: %d ",`num_of_transactions);
		$display("Pass Count: %d",pass_count);
		$display("Fail Count: %d",fail_count);
	endtask
endclass
			
