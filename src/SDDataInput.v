
module SDDataInput (
    //??????
    input  wire        sys_clk,    //?????????,???50MHz
    input  wire        sys_rst_n,  //?????????,?????????????
    //??????
    input  wire        rx_flag,    //??fifo?????????????
    input  wire [ 7:0] rx_data,    //??fifo????????
    //SD???????
    input  wire        sd_miso,    //?????????????
    output wire        sd_clk,     //SD??????????????
    output wire        sd_cs_n,    //?????????????
    output wire        sd_mosi,    //??????????????
    //??SD????
    inout  wire        wr_en,      //??????????????????
    input  wire [31:0] wr_addr,    //???????????????????
    output  wire [15:0] wr_data,    //???????????
    output wire        wr_busy,    //??????????
    output wire        wr_req      //???????????????????
);

  //********************************************************************//
  //****************** Parameter and Internal Signal *******************//
  //********************************************************************//
  //parameter define
  parameter DATA_NUM = 12'd256;  //???????????
  parameter SECTOR_ADDR = 32'd1000;  //???????????????
  parameter CNT_WAIT_MAX = 16'd60000;  //??fifo?????????????????????????????

  //wire  define
  wire [11:0] wr_fifo_data_num;  //??fifo???????????????
  wire        wr_busy_fall;  //sd?????????????????
  wire        rd_busy_fall;  //sd?????????????????
  wire        init_end;  //?????SD???
  //reg   define
  reg         wr_busy_dly;  //sd?????????????????????????????
  reg         rd_busy_dly;  //sd?????????????????????????????
  reg         send_data_en;  //?????????????????????????
  reg  [15:0] cnt_wait;  //??fifo????????????????
  reg  [11:0] send_data_num;  //?????????????????????
  reg         rd_fifo_rd_en;


  wire        rd_data_en;  //sd??????????????????????
  wire [15:0] rd_data;  //sd????????????????
  wire        rd_busy;  //sd???????????????????
  reg         rd_en;  //sd?????????????
  wire [31:0] rd_addr;  //sd???????????????
  reg         tx_flag;  //??fifo?????????????
  wire [ 7:0] tx_data;  //??fifo????????
  wire [7:0 ]FIFOWriteOutData;
  wire [15:0]SDWriteInData;
  //********************************************************************//
  //***************************** Main Code ****************************//
  //********************************************************************//
  //wr_en:sd??????????????
  assign wr_en = (((wr_fifo_data_num == (DATA_NUM)) && (init_end == 1'b1))) ? 1'b1 : 1'b0;
  assign SDWriteInData[0] = FIFOWriteOutData[0];
  assign SDWriteInData[1] = FIFOWriteOutData[1];
  assign SDWriteInData[2] = FIFOWriteOutData[2];
  assign SDWriteInData[3] = FIFOWriteOutData[3];
  assign SDWriteInData[4] = FIFOWriteOutData[4];
  assign SDWriteInData[5] = FIFOWriteOutData[5];
  assign SDWriteInData[6] = FIFOWriteOutData[6];
  assign SDWriteInData[7] = FIFOWriteOutData[7];
  assign SDWriteInData[8] = 1'b0;
  assign SDWriteInData[9] = 1'b0;
  assign SDWriteInData[10] = 1'b0;
  assign SDWriteInData[11] = 1'b0;
  assign SDWriteInData[12] = 1'b0;
  assign SDWriteInData[13] = 1'b0;
  assign SDWriteInData[14] = 1'b0;
  assign SDWriteInData[15] = 1'b0;
  assign wr_data=SDWriteInData;

  //wr_busy_dly:sd?????????????????????????????
  always @(posedge sys_clk or negedge sys_rst_n)
    if (sys_rst_n == 1'b0) wr_busy_dly <= 1'b0;
    else wr_busy_dly <= wr_busy;

  //wr_busy_fall:sd?????????????????
  assign wr_busy_fall = ((wr_busy == 1'b0) && (wr_busy_dly == 1'b1)) ? 1'b1 : 1'b0;

  //rd_en:sd?????????????
  always @(posedge sys_clk or negedge sys_rst_n)
    if (sys_rst_n == 1'b0) rd_en <= 1'b0;
    else if (wr_busy_fall == 1'b1) rd_en <= 1'b1;
    else rd_en <= 1'b0;

  //rd_addr:sd???????????????
  assign rd_addr = SECTOR_ADDR;

  //rd_busy_dly:sd?????????????????????????????
  always @(posedge sys_clk or negedge sys_rst_n)
    if (sys_rst_n == 1'b0) rd_busy_dly <= 1'b0;
    else rd_busy_dly <= rd_busy;

  //rd_busy_fall:sd?????????????????
  assign rd_busy_fall = ((rd_busy == 1'b0) && (rd_busy_dly == 1'b1)) ? 1'b1 : 1'b0;

  //send_data_en:?????????????????????????
  always @(posedge sys_clk or negedge sys_rst_n)
    if (sys_rst_n == 1'b0) send_data_en <= 1'b0;
    else if ((send_data_num == (DATA_NUM * 2) - 1'b1) && (cnt_wait == CNT_WAIT_MAX - 1'b1))
      send_data_en <= 1'b0;
    else if (rd_busy_fall == 1'b1) send_data_en <= 1'b1;
    else send_data_en <= send_data_en;

  //cnt_wait:??fifo????????????????
  always @(posedge sys_clk or negedge sys_rst_n)
    if (sys_rst_n == 1'b0) cnt_wait <= 16'd0;
    else if (send_data_en == 1'b1)
      if (cnt_wait == CNT_WAIT_MAX) cnt_wait <= 16'd0;
      else cnt_wait <= cnt_wait + 1'b1;
    else cnt_wait <= 16'd0;

  //send_data_num:?????????????????????
  always @(posedge sys_clk or negedge sys_rst_n)
    if (sys_rst_n == 1'b0) send_data_num <= 12'd0;
    else if (send_data_en == 1'b1)
      if (cnt_wait == CNT_WAIT_MAX) send_data_num <= send_data_num + 1'b1;
      else send_data_num <= send_data_num;
    else send_data_num <= 12'd0;

  //rd_fifo_rd_en:??fifo???????????????
  always @(posedge sys_clk or negedge sys_rst_n)
    if (sys_rst_n == 1'b0) rd_fifo_rd_en <= 1'b0;
    else if (cnt_wait == (CNT_WAIT_MAX - 1'b1)) rd_fifo_rd_en <= 1'b1;
    else rd_fifo_rd_en <= 1'b0;

  //tx_flag:??fifo?????????????
  always @(posedge sys_clk or negedge sys_rst_n)
    if (sys_rst_n == 1'b0) tx_flag <= 1'b0;
    else tx_flag <= rd_fifo_rd_en;

  //********************************************************************//
  //************************** Instantiation ***************************//
  //********************************************************************//
  //------------- fifo_wr_data_inst -------------
  wr_fifo fifo_wr_data_inst (
      .rst(~sys_rst_n),  // input rst
      .wr_clk(sys_clk),  // input wr_clk
      .rd_clk(sys_clk),  // input rd_clk
      .din(rx_data),  // input [7 : 0] din
      .wr_en(rx_flag),  // input wr_en
      .rd_en(wr_req),  // input rd_en
      .dout(FIFOWriteOutData),  // output [7 : 0] dout
      .full(),  // output full
      .empty(),  // output empty
      .rd_data_count(wr_fifo_data_num)  // output [10 : 0] rd_data_count
  );
  SDWriterMaster SDControl (
      .sys_clk  (sys_clk),   //?????????,???50MHz
      .sys_rst_n(sys_rst_n), //?????????,???????????????

      .sd_miso(sd_miso),  //?????????????
      .sd_clk (sd_clk),   //SD????????????????
      .sd_cs_n(sd_cs_n),  //???????????????
      .sd_mosi(sd_mosi),  //??????????????

      .wr_en  (wr_en),    //????????????????????
      .wr_addr(wr_addr),  //?????????????????????
      .wr_data(SDWriteInData),  //?????????????
      .wr_busy(wr_busy),  //??????????
      .wr_req (wr_req),   //?????????????????????

      .init_end(init_end)  //SD??????
//		.rd_data(16'b0) 
  );

endmodule