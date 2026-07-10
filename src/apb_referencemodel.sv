class apb_referencemodel;

	apb_transaction ref_trans;
	apb_bridge_transaction bridge_trans;
	apb_slave_transaction slave_trans;

	mailbox #(apb_bridge_transaction) drvb_2_ref;
	mailbox #(apb_slave_transaction) drvs_2_ref;
	mailbox #(apb_transaction) ref_2_scb;

	function new(mailbox #(apb_bridge_transaction) drvb_2_ref,mailbox #(apb_slave_transaction) drvs_2_ref, mailbox #(apb_transaction) ref_2_scb);
		this.drvb_2_ref = drvb_2_ref;
		this.drvs_2_ref = drvs_2_ref;
		this.ref_2_scb = ref_2_scb;
	endfunction

	task run();
		for(int i=0;i<`num_of_transactions;i++) begin
			drvb_2_ref.get(bridge_trans);
			drvs_2_ref.get(slave_trans);
			ref_trans = new();

			ref_trans.PADDR = bridge_trans.addr_in;
			ref_trans.PWRITE = bridge_trans.write_read;
		
			if(bridge_trans.write_read == 1) begin
				ref_trans.PWDATA = bridge_trans.wdata_in;
				ref_trans.PRDATA = 0;
				ref_trans.PSTRB = bridge_trans.strb_in;
			end
			else begin
				ref_trans.PRDATA = slave_trans.PRDATA;
				ref_trans.PWDATA = 0;
				ref_trans.PSTRB = 0;
			end

			ref_trans.PSLVERR = slave_trans.PSLVERR;

			ref_2_scb.put(ref_trans);

			$display("[REFERENCE MODEL] [%t] Transaction No: %d Predicted | ADDR: %h | WRITE: %h | PSLVERR: %b",$time,i+1,ref_trans.PADDR,ref_trans.PWRITE,ref_trans.PSLVERR);
		end
	endtask
endclass


