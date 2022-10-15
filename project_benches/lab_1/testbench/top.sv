`timescale 1ns / 10ps

module top();

parameter int WB_ADDR_WIDTH = 2;
parameter int WB_DATA_WIDTH = 8;
parameter int NUM_I2C_BUSSES = 1;

bit  clk;
bit  rst = 1'b1;
wire cyc;
wire stb;
wire we;
tri1 ack;
wire [WB_ADDR_WIDTH-1:0] adr;
wire [WB_DATA_WIDTH-1:0] dat_wr_o;
wire [WB_DATA_WIDTH-1:0] dat_rd_i;
wire irq;
tri  [NUM_I2C_BUSSES-1:0] scl;
tri  [NUM_I2C_BUSSES-1:0] sda;

// ****************************************************************************
// Clock generator
initial forever #10ns clk <= ~clk;

// ****************************************************************************
// Reset generator
initial #113ns rst = 1'b0;

// ****************************************************************************
// Monitor Wishbone bus and display transfers in the transcript
bit [WB_ADDR_WIDTH-1:0] addr_val;
bit [WB_DATA_WIDTH-1:0] data_val;
bit we_val;
initial begin
   @(clk);
   forever begin
      wb_bus.master_monitor(addr_val, data_val, we_val);
      $display("transferred: addr - %x, data - %x, we - %x", addr_val, data_val, we_val);
   end
end

// ****************************************************************************
// Define the flow of the simulation
initial begin
   //logic contruct to hold read value
   logic [WB_DATA_WIDTH-1:0] data_read = 0;
   
   //example 1
   //enable IICMB core and enable interrupts
   #500 wb_bus.master_write(0, 8'b11xxxxxx);
   
   //example 3
   //DPR write, select desired I2C bus
   wb_bus.master_write(1, 8'h05);
   //CMDR write, set bus command
   wb_bus.master_write(2, 8'bxxxxx110);
   //wait for interrupt or for DON of CMDR to be 1
   wait(irq || data_read[7]) begin
      wb_bus.master_read(2, data_read);
   end
   //CMDR write, start command
   wb_bus.master_write(2, 8'bxxxxx100);
   //wait for interrupt or for DON of CMDR to be 1
   wait(irq || data_read[7]) begin
      wb_bus.master_read(2, data_read);
   end
   //DPR write, address 0x22 shifted to the left + rightmost bit = 0 which means writing
   wb_bus.master_write(1, 8'h44);
   //CMDR write, write command
   wb_bus.master_write(2, 8'bxxxxx001);
   //wait for interrupt or for DON or NAK of CMDR to be 1, if NAK slave doesn't respond
   wait(irq || data_read[7] || data_read[6]) begin
      wb_bus.master_read(2, data_read);
   end
   //if not nak then can proceed writing
   if(data_read[7] || irq) begin
      //DPR write, data to be written
      wb_bus.master_write(1, 8'h78);
      //CMDR write, write command
      wb_bus.master_write(2, 8'bxxxxx001);
      //wait for interrupt or for DON of CMDR to be 1
      wait(irq || data_read[7]) begin
         wb_bus.master_read(2, data_read);
      end
      //CMDR write, stop command
      wb_bus.master_write(2, 8'bxxxxx101);
      //wait for interrupt or for DON of CMDR to be 1
      wait(irq || data_read[7]) begin
         wb_bus.master_read(2, data_read);
      end
   end
end
// ****************************************************************************
// Instantiate the Wishbone master Bus Functional Model
wb_if       #(
      .ADDR_WIDTH(WB_ADDR_WIDTH),
      .DATA_WIDTH(WB_DATA_WIDTH)
      )
wb_bus (
  // System sigals
  .clk_i(clk),
  .rst_i(rst),
  // Master signals
  .cyc_o(cyc),
  .stb_o(stb),
  .ack_i(ack),
  .adr_o(adr),
  .we_o(we),
  // Slave signals
  .cyc_i(),
  .stb_i(),
  .ack_o(),
  .adr_i(),
  .we_i(),
  // Shred signals
  .dat_o(dat_wr_o),
  .dat_i(dat_rd_i)
  );

// ****************************************************************************
// Instantiate the DUT - I2C Multi-Bus Controller
\work.iicmb_m_wb(str) #(.g_bus_num(NUM_I2C_BUSSES)) DUT
  (
    // ------------------------------------
    // -- Wishbone signals:
    .clk_i(clk),         // in    std_logic;                            -- Clock
    .rst_i(rst),         // in    std_logic;                            -- Synchronous reset (active high)
    // -------------
    .cyc_i(cyc),         // in    std_logic;                            -- Valid bus cycle indication
    .stb_i(stb),         // in    std_logic;                            -- Slave selection
    .ack_o(ack),         //   out std_logic;                            -- Acknowledge output
    .adr_i(adr),         // in    std_logic_vector(1 downto 0);         -- Low bits of Wishbone address
    .we_i(we),           // in    std_logic;                            -- Write enable
    .dat_i(dat_wr_o),    // in    std_logic_vector(7 downto 0);         -- Data input
    .dat_o(dat_rd_i),    //   out std_logic_vector(7 downto 0);         -- Data output
    // ------------------------------------
    // ------------------------------------
    // -- Interrupt request:
    .irq(irq),           //   out std_logic;                            -- Interrupt request
    // ------------------------------------
    // ------------------------------------
    // -- I2C interfaces:
    .scl_i(scl),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Clock inputs
    .sda_i(sda),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Data inputs
    .scl_o(scl),         //   out std_logic_vector(0 to g_bus_num - 1); -- I2C Clock outputs
    .sda_o(sda)          //   out std_logic_vector(0 to g_bus_num - 1)  -- I2C Data outputs
    // ------------------------------------
  );


endmodule
