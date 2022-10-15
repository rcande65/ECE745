interface i2c_if #(
 
       int NUM_I2C_BUSSES = 1,
	int I2C_ADDR_WIDTH = 7,
	int I2C_DATA_WIDTH = 8
	)
(
  // system signals
  input triand [NUM_I2C_BUSSES-1:0] scl,
  input triand [NUM_I2C_BUSSES-1:0] sda,
  output bit [NUM_I2C_BUSSES-1:0] sda_o,
  input wire clock
);

import parameter_pkg::*;

// internal control signals

//operation typedef declaration
//typedef enum bit {WRITE=1'b0, READ=1'b1} i2c_op_t;
//typedef enum int {ERROR, START, DATA, STOP} control_op_t;

//address and data storage
bit [6:0] addr_val = 7'b0100010; //storage for read/write address
bit [I2C_ADDR_WIDTH:0] addr_data;
int bit_count = 0;
int data_count = 0;
bit read_bit;
int it = 0;

// wait for and capture trasfer start
// *******************************************
  task wait_for_i2c_transfer(output i2c_op_t op, 
      output bit [I2C_DATA_WIDTH-1:0] write_data []);

     bit bit_read;
     control_op_t operation;
     bit stop;
     sda_o = 1'b1;
     operation = ERROR;
     stop = 1'b0;
     
     //$display("start of wait for i2c"); 
     //wait for start bit
     while(operation != START) begin
        read(operation, bit_read);
     end
     //$display("start bit received");
     //read in address from sda
     for(int i = I2C_ADDR_WIDTH-1; i >= 0; i--) begin
        read(operation, bit_read);
        addr_data[i] = bit_read;
     end

     //read in r/w from sda
     read(operation, bit_read);
     if(bit_read) op = READ;
     else op = WRITE;
     write_data = new[1];

     //if address received is the slave address, ack, then if a write op read in write data, else return 
     if(addr_data == addr_val) begin
        //acknowledge
        sda_o = 1'b0;
        @(posedge scl);
        @(negedge scl);
        sda_o = 1'b1;
        //check op type to see what to do next
        if(op == WRITE) begin
           //read data
           while(!stop) begin
              //get all data bits
              for(int i = I2C_DATA_WIDTH-1; i >= 0; i--) begin
                 read(operation, bit_read);
                 if(operation == STOP) begin
                    stop = 1'b1;
                    break;
                 end
                 write_data[write_data.size()-1][i] = bit_read;
              end
              //acknowledge if not stop condition
              if(!stop) begin
                 sda_o = 1'b0;
                 @(posedge scl);
                 @(negedge scl);
                 sda_o = 1'b1;
                 write_data = new[write_data.size()+1](write_data);
                 //$display("waiting for stop bit");
              end
           end
           //$display("stop bit received");
        end
     end

  endtask
// *******************************************

//offset to correct data_val for proper return value
int count_transfers = 0;
int bit_transfers = 0;
int k = 0; //loop iterator
// provide data for read operation
// *******************************************
  task provide_read_data(input bit [I2C_DATA_WIDTH-1:0] read_data [],
       output bit transfer_complete); 
      control_op_t op;
      bit read_bit;
      //write data bits
      for(int i = I2C_DATA_WIDTH-1; i >= 0; i--) begin
         sda_o = read_data[read_data.size()-1][i];
         @(posedge scl);
         @(negedge scl);
      end
      sda_o = 1'b1;
      read(op, read_bit);
      if(!read_bit) begin
         transfer_complete = 1'b0;
      end
      else begin
	 while(op != STOP) begin
            read(op, read_bit);
            if(op == STOP) transfer_complete = 1'b1;
          end
      end
  endtask
// *******************************************

// return data observed
// *******************************************
  task monitor(output bit [I2C_ADDR_WIDTH-1:0] addr, output i2c_op_t op,
       output bit [I2C_DATA_WIDTH-1:0] data []);

     bit data_read;
     control_op_t data_op;
     bit read_stop;
     
     data_op = ERROR;
     read_stop = 0;

     while(data_op != START) begin
        read(data_op, data_read);       
     end
    
     for(int i = I2C_ADDR_WIDTH-1; i >= 0; i--) begin
        read(data_op, data_read);
        addr[i] = data_read;
     end
     
     read(data_op, data_read);
     if(data_read) op = READ;
     else op = WRITE;
     data = new[1];

     while(!read_stop) begin
        read(data_op, data_read);
        for(int i = I2C_DATA_WIDTH-1; i >= 0; i--) begin
           read(data_op, data_read);
           if(data_op == STOP) begin
              read_stop = 1'b1;
              data = new[data.size()-1] (data);
              break;
           end
           else data[data.size()-1][i] = data_read; 
        end
        if(!read_stop) begin
           data = new[data.size()+1] (data);
        end
     end   
  endtask
// *******************************************

// read bit from sda
  task read(output control_op_t read_op, output bit read_bit);
   fork
      begin : start
         wait(scl); 
         @(negedge sda);
         read_op = START;
      end
      begin : data
         @(posedge scl); 
         read_bit = sda;
         @(negedge scl);
         read_op = DATA;
      end
      begin : stop
         @(posedge scl);
         @(posedge sda);
         read_op = STOP;
      end
   join_any
endtask

endinterface




