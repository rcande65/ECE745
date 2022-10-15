class i2c_driver extends ncsu_component#(.T(i2c_transaction));

   function new(string name = "", ncsu_component_base parent = null);
      super.new(name, parent);
   endfunction

   virtual i2c_if #(NUM_I2C_BUSSES, I2C_ADDR_WIDTH, I2C_DATA_WIDTH) bus;
   i2c_configuration configuration;
   i2c_transaction i2c_trans;

   function void set_configuration(i2c_configuration cfg);
      configuration = cfg;
   endfunction

   //i2c flow structures
   bit transfer_complete;
   bit [I2C_DATA_WIDTH-1:0] read_data[1];
   virtual task bl_put(T trans);
      transfer_complete = 1'b0;
      //if(bus) $display("bus exists");
      bus.wait_for_i2c_transfer(trans.op, trans.data);
      //$display("i2c observed op: %d, i2c observed data: %d", trans.op, trans.data);
      if(trans.op) begin 
         while(!transfer_complete) begin
            read_data[0] = trans.data_queue.pop_front();
            //$display(read_data[0]);
            bus.provide_read_data(read_data, transfer_complete);
            //trans.data_queue.pop_front();
         end
      end
   endtask

endclass
