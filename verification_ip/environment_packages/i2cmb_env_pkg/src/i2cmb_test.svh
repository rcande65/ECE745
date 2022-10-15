class i2cmb_test extends ncsu_component;

   i2cmb_env_configuration cfg;
   i2cmb_environment env;
   i2cmb_generator gen;
   string test_name;

   function new(string name = "", ncsu_component_base parent = null);
      super.new(name, parent);
      if(!$value$plusargs("GEN_TEST_TYPE=%s", test_name)) begin
         $display("FATAL: +GEN_TEST_TYPE plusarg not found on command line");
         $fatal;
      end
      $display("GEN_TEST_TYPE = %s", test_name);
      cfg = new("cfg");
      //cfg.sample_coverage();
      env = new("env", this);
      env.set_configuration(cfg);
      env.build();
     // $display(env.wb_ag.bus);
      //$display(env.i2c_ag.bus);
      gen = new("gen", this);
      gen.set_agent(env.get_wb_agent(), env.get_i2c_agent());
      //$display(gen.wb_ag.bus);
      //$display(gen.i2c_ag.bus);
   endfunction

   virtual task run();
      env.run();
      //register tests
      //$display($test$plusargs);
      if(test_name == "invalid") gen.invalid_test();
      else if(test_name == "read_only") gen.read_only_test();
      else if(test_name == "default_vals") gen.default_test();
      //compulsory test
      else if(test_name == "rand_rd") gen.rand_rd_test();
      else if(test_name == "rand_wr") gen.rand_wr_test();
      else if(test_name == "alternate") gen.alternate_test();
      else if(test_name == "transitions") gen.transitions_test();
      else gen.run();
   endtask

endclass
