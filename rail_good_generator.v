module rail_good_generator(
    input i_rail1, 
    input i_rail2,
    input i_rail3,
    input i_rail4,
    input i_rail5,
    output o_allGood
);

assign o_allGood = (i_rail1 && i_rail2 && i_rail3 && i_rail4 && i_rail5);

endmodule