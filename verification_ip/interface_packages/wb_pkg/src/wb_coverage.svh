class wb_coverage extends ncsu_component#(.T(wb_transaction));

   wb_configuration configuration;

   bit [WB_ADDR_WIDTH-1:0] address;
   bit we = 0;
   bit [WB_DATA_WIDTH-1:0] data;

   covergroup wb_transaction_cg;
      option.per_instance = 1;
      option.name = get_full_name();
      address : coverpoint address;
      data : coverpoint data;
      we : coverpoint we;
      address_x_we : cross address, we;
   endgroup

   covergroup register_cg;
      option.per_instance = 1;
      option.name = get_full_name();
      address : coverpoint address {bins valid [4] = {0, 1, 2, 3};}
   endgroup

   function new(string name = "", ncsu_component #(T) parent = null);
      super.new(name, parent);
      wb_transaction_cg = new;
      register_cg = new;
   endfunction

   function void set_configuration(wb_configuration cfg);
      configuration = cfg;
   endfunction

   virtual function void nb_put(T trans);
      address = trans.address;
      data = trans.data;
      we = trans.we;
      wb_transaction_cg.sample();
      register_cg.sample();
   endfunction

endclass
