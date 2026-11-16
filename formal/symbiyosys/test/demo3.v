module top (
  input clk
);
  reg [7:0] counter = 0;

  always @(posedge clk) begin
    counter <= counter + 1;
  end

  always @* begin
    // unsigned counter can never wrap below zero
    assert (counter >= 0);
  end
endmodule
