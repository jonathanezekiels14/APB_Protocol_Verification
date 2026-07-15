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

class apb_write_test extends apb_test;
    apb_trans_write trans;

    function new(virtual apb_interface.BRIDGE_DRV drvb_vif, 
                 virtual apb_interface.SLAVE_DRV drvs_vif, 
                 virtual apb_interface.MON mon_vif);
        super.new(drvb_vif, drvs_vif, mon_vif);
    endfunction

    virtual task run();
        $display("\n[TEST] Running apb_write_test");
        env = new(drvb_vif, drvs_vif, mon_vif);
        
        trans = new();
        env.gen.gen_bridge_trans = trans; 
        
        env.run();
    endtask
endclass

class apb_read_test extends apb_test;
    apb_trans_read trans;

    function new(virtual apb_interface.BRIDGE_DRV drvb_vif, 
                 virtual apb_interface.SLAVE_DRV drvs_vif, 
                 virtual apb_interface.MON mon_vif);
        super.new(drvb_vif, drvs_vif, mon_vif);
    endfunction

    virtual task run();
        $display("\n[TEST] Running apb_read_test");
        env = new(drvb_vif, drvs_vif, mon_vif);
        
        trans = new();
        env.gen.gen_bridge_trans = trans; 
        
        env.run();
    endtask
endclass

class apb_idle_test extends apb_test;
    apb_trans_idle trans;

    function new(virtual apb_interface.BRIDGE_DRV drvb_vif, 
                 virtual apb_interface.SLAVE_DRV drvs_vif, 
                 virtual apb_interface.MON mon_vif);
        super.new(drvb_vif, drvs_vif, mon_vif);
    endfunction

    virtual task run();
        $display("\n[TEST] Running apb_idle_test");
        env = new(drvb_vif, drvs_vif, mon_vif);
        
        trans = new();
        env.gen.gen_bridge_trans = trans; 
        
        env.run();
    endtask
endclass

class apb_regression_test;

    // 1. Declare the test handles
    virtual apb_interface.BRIDGE_DRV drvb_vif;
    virtual apb_interface.SLAVE_DRV drvs_vif;
    virtual apb_interface.MON mon_vif;

    apb_test  t_base;
    apb_write_test t_write;
    apb_read_test  t_read;
    apb_idle_test  t_idle;

    // 2. Constructor to pass virtual interfaces
    function new(virtual apb_interface.BRIDGE_DRV drvb_vif, 
                 virtual apb_interface.SLAVE_DRV drvs_vif, 
                 virtual apb_interface.MON mon_vif);
        this.drvb_vif = drvb_vif;
        this.drvs_vif = drvs_vif;
        this.mon_vif  = mon_vif;
    endfunction

    // 3. Sequential Execution Task
    virtual task run();
        $display("==================================================");
        $display("      STARTING SEQUENTIAL REGRESSION SUITE        ");
        $display("==================================================");

        // Execute Base Test
        $display("\n[REGRESSION] Launching Test 0: Base Sequence...");
        t_base = new(drvb_vif, drvs_vif, mon_vif);
        t_base.run();

        // Execute Test 1
        $display("\n[REGRESSION] Launching Test 1: Write Sequence...");
        t_write = new(drvb_vif, drvs_vif, mon_vif);
        t_write.run();

        // Execute Test 2
        $display("\n[REGRESSION] Launching Test 2: Read Sequence...");
        t_read = new(drvb_vif, drvs_vif, mon_vif);
        t_read.run();

   /*     // Execute Test 3
        $display("\n[REGRESSION] Launching Test 3: Idle Sequence...");
        t_idle = new(drvb_vif, drvs_vif, mon_vif);
        t_idle.run();
*/
        $display("\n==================================================");
        $display("          REGRESSION SUITE COMPLETE                 ");
        $display("==================================================");
    endtask

endclass
