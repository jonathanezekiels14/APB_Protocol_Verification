class apb_coverage;
    apb_transaction cov_trans;
    mailbox #(apb_transaction) mon_2_cov;

    covergroup cg_apb_protocol;
        cp_write: coverpoint cov_trans.PWRITE {
            bins read_ops  = {0};
            bins write_ops = {1};
        }

        cp_address: coverpoint cov_trans.PADDR {
            bins low_range  = {[32'h0000_0000 : 32'h0000_0FFF]};
            bins mid_range  = {[32'h0000_1000 : 32'hFFFF_EFFF]};
            bins high_range = {[32'hFFFF_F000 : 32'hFFFF_FFFF]};
        }

        cp_error: coverpoint cov_trans.PSLVERR {
            bins no_error = {0};
            bins error    = {1};
        }

        cx_write_x_error: cross cp_write, cp_error;
        cx_write_x_addr: cross cp_write, cp_address;
    endgroup

    function new(mailbox #(apb_transaction) mon_2_cov);
        this.mon_2_cov = mon_2_cov;
        cg_apb_protocol = new();
    endfunction

    task run();
        forever begin
            mon_2_cov.get(cov_trans);
            cg_apb_protocol.sample();
        end
    endtask
endclass
