class i2c_agent extends ncsu_component#(.T(i2c_transaction));

   i2c_configuration configuration;
   i2c_driver driver;
   i2c_monitor monitor;
   i2c_coverage i2c_cover;
   ncsu_component #(T) subscribers[$];
   virtual i2c_if #(NUM_I2C_BUSSES, I2C_ADDR_WIDTH, I2C_DATA_WIDTH) bus;

   function new(string name = "", ncsu_component_base parent = null);
      super.new(name, parent);
      if(!(ncsu_config_db#(virtual i2c_if #(NUM_I2C_BUSSES, I2C_ADDR_WIDTH, I2C_DATA_WIDTH))::get(get_full_name(), this.bus))) begin
         $display("i2c_agent::ncsu_config_db::get() call for BFM handle failed for the name: %s", get_full_name());
	 $finish;
      end
   endfunction

   function void set_configuration(i2c_configuration cfg);
      configuration = cfg;
   endfunction

   virtual function void build();
      //setup driver
      //$display(bus);
      driver = new("driver", this);
      driver.set_configuration(configuration);
      driver.build();
      driver.bus = this.bus;
      //setup coverage
      if(configuration.collect_coverage) begin
         i2c_cover = new("i2c_cover", this);
         i2c_cover.set_configuration(configuration);
         i2c_cover.build();
         connect_subscriber(i2c_cover);
      end
      //setup monitor
      monitor = new("monitor", this);
      monitor.set_configuration(configuration);
      monitor.set_agent(this);
      monitor.enable_transaction_viewing = 1;
      monitor.build();
      monitor.bus = this.bus;
   endfunction

   virtual function void nb_put(T trans);
      foreach(subscribers[i]) begin
         subscribers[i].nb_put(trans);
      end
   endfunction

   virtual task bl_put(T trans);
      driver.bl_put(trans);
   endtask

   virtual function void connect_subscriber(ncsu_component #(T) subscriber);
      subscribers.push_back(subscriber);
   endfunction

   virtual task run();
      fork monitor.run(); join_none
   endtask

endclass










