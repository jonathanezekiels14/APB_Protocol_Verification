class apb_generator;
	apb_bridge_transaction gen_bridge_trans;
	apb_slave_transaction gen_slave_trans;
	mailbox #(apb_bridge_transaction) gen_2_bridge_drv;
	mailbox #(apb_slave_transaction) gen_2_slave_drv;
	function new(mailbox #(apb_bridge_transaction) gen_2_bridge_drv, mailbox #(apb_slave_transaction) gen_2_slave_drv);	
		this.gen_2_bridge_drv = gen_2_bridge_drv;
		this.gen_2_slave_drv = gen_2_slave_drv;
		gen_bridge_trans= new();
		apb_slave_trans = new();
	endfunction

	task run();
		for(int i=0;i<`num_of_transactions;i++) begin
			assert(apb_bridge_trans.randomize() == 1);
			assert(apb_slave_trans.randomize() == 1);
			gen_2_bridge_drv.put(apb_bridge_trans.copy());
			gen_2_slave_drv.put(apb_slave_trans.copy());
			$display("[GENERATOR][%0t] Randomized  ADDR = %0H | READ_WRITE = %0H | PSLVERR = %0B",$time,apb_bridge_trans.addr_in,apb_bridge_trans.write_read,apb_slave_trans.PSLVERR);
		end
	endtask
endclass

