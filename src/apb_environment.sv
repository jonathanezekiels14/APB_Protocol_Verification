class apb_environment;

	virtual apb_interface.BRIDGE_DRV drvb_vif;
	virtual apb_interface.SLAVE_DRV drvs_vif;
	virtual apb_interface.MON mon_vif;

	mailbox #(apb_bridge_trans) gen_2_bridge_drv;
	mailbox #(apb_slave_trans) gen_2_slave_drv;
	mailbox #(apb_bridge_trans) drvb_2_ref;
	mailbox #(apb_slave_trans) drvs_2_ref;
	mailbox #(apb_transaction) ref_2_scb;
	mailbox #(apb_transaction) mon_2_scb;

	apb_generator gen;
	apb_bridge_driver drv_bridge;
	apb_slave_driver drv_slave;
	apb_referencemodel refm;
	apb_monitor mon;
	apb_scoreboard scb;

	function new(virtual apb_interface.BRIDGE_DRV drvb_vif, virtual apb_interface.SLAVE_DRV drvs_vif, virtual apb_interface.MON mon_vif);
		// VIF
		this.drvb_vif = drvb_vif;
		this.drvs_vif = drvs_vif;
		this.mon_vif = mon_vif;
		
		// Mailboxes
		gen_2_bridge_drv = new();
		gen_2_slave_drv = new();
		drvb_2_ref = new();
		drvs_2_ref = new();
		ref_2_scb = new();
		mon_2_scb = new();

		// Components
		gen = new(gen_2_bridge_drv, gen_2_slave_drv);
		drv_bridge = new(gen_2_bridge_drv,drvb_2_ref,drvb_vif);
		drv_slave = new(gen_2_slave_drv,drvs_2_ref,drvs_vif);
		refm = new(drvb_2_ref,drvs_2_ref,ref_2_scb);
		mon = new(mon_2_scb,mon_vif);
		scb = new(ref_2_scb,mon_2_scb,mon_vif);

	endfunction

	task run();
		fork
			gen.run();
			drv_bridge.run();
			drv_slave.run();
			refm.run();
			mon.run();
			scb.run();
		join
		$display("[ENVIRONMENT] [%t] Test Complete ",$time);
	endtask
endclass



