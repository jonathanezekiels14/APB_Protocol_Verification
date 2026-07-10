class apb_test;

	virtual apb_interface.BRIDGE_DRV drvb_vif;
	virtual apb_interface.SLAVE_DRV drvs_vif;
	virtual apb_interface.MON mon_vif;

	apb_environment env;

	function new(virtual apb_interface.BRIDGE_DRV drvb_vif, virtual apb_interface.SLAVE_DRV drvs_vif, virtual apb_interface.MON mon_vif);
		this.drvs_vif = drvs_vif;
		this.drvb_vif = drvb_vif;
		this.mon_vif = mon_vif;
	endfunction

	virtual task run();
		$display("\n [TEST] Running Base Test");
		env = new(drvb_vif,drvs_vif,mon_vif);
		env.run();
	endtask
endclass

