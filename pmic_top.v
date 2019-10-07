module pmic_top(
    input i_12V_voltageGood,
    input i_12V_currentGood,
    output o_12V_currentFault,
    output o_12V_railGood,
    output o_12V_voltageFault,

    input i_3V3_voltageGood,
    input i_3V3_currentGood,
    output o_3V3_currentFault,
    output o_3V3_railGood,
    output o_3V3_voltageFault,

    input i_5V_voltageGood,
    input i_5V_currentGood,
    output o_5V_currentFault,
    output o_5V_railGood,
    output o_5V_voltageFault,

    input i_1V8_voltageGood,
    input i_1V8_currentGood,
    output o_1V8_currentFault,
    output o_1V8_railGood,
    output o_1V8_voltageFault,

    input i_3V3ADC_voltageGood,
    input i_3V3ADC_currentGood,
    output o_3V3ADC_currentFault,
    output o_3V3ADC_railGood,
    output o_3V3ADC_voltageFault,

    input i_16V_voltageGood,
    input i_16V_currentGood,
    output o_16V_currentFault,
    output o_16V_railGood,
    output o_16V_voltageFault,

    input i_fpgaPwrGood,

    output o_S1Good,
    output o_S2Good,
    output o_S3Good
);

/////////////
// Stage 1 //
/////////////

rail_monitor Rail_12V(
    .i_voltageGood(i_12V_voltageGood),
    .i_currentGood(i_12V_currentGood),
    .i_resetn(resetn),
    .o_railGood(o_12V_railGood), 
    .o_voltageFault(o_12V_voltageFault),
    .o_currentFault(o_12V_currentFault)
);

rail_good_generator Stage1(
    .i_rail1(o_12V_railGood),
    .i_rail2(1'b1),
    .i_rail3(1'b1),
    .i_rail4(1'b1),
    .i_rail5(1'b1),
    .o_allGood(o_S1Good)
);

/////////////
// Stage 2 //
/////////////

rail_monitor Rail_3V3(
    .i_voltageGood(i_3V3_voltageGood),
    .i_currentGood(i_3V3_currentGood),
    .i_resetn(resetn),
    .o_railGood(o_3V3_railGood), 
    .o_voltageFault(o_3V3_voltageFault),
    .o_currentFault(o_3V3_currentFault)
);

rail_monitor Rail_5V(
    .i_voltageGood(i_5V_voltageGood),
    .i_currentGood(i_5V_currentGood),
    .i_resetn(resetn),
    .o_railGood(o_5V_railGood), 
    .o_voltageFault(o_5V_voltageFault),
    .o_currentFault(o_5V_currentFault)
);

rail_good_generator Stage2(
    .i_rail1(o_3V3_railGood),
    .i_rail2(o_5V_railGood),
    .i_rail3(o_S1Good),
    .i_rail4(1'b1),
    .i_rail5(1'b1),
    .o_allGood(o_S2Good)
);

/////////////
// Stage 3 //
/////////////

rail_monitor Rail_1V8(
    .i_voltageGood(i_1V8_voltageGood),
    .i_currentGood(i_1V8_currentGood),
    .i_resetn(resetn),
    .o_railGood(o_1V8_railGood), 
    .o_voltageFault(o_1V8_voltageFault),
    .o_currentFault(o_1V8_currentFault)
);

rail_monitor Rail_3V3ADC(
    .i_voltageGood(i_3V3ADC_voltageGood),
    .i_currentGood(i_3V3ADC_currentGood),
    .i_resetn(resetn),
    .o_railGood(o_3V3ADC_railGood), 
    .o_voltageFault(o_3V3ADC_voltageFault),
    .o_currentFault(o_3V3ADC_currentFault)
);

rail_monitor Rail_16V(
    .i_voltageGood(i_16V_voltageGood),
    .i_currentGood(i_16V_currentGood),
    .i_resetn(resetn),
    .o_railGood(o_16V_railGood), 
    .o_voltageFault(o_16V_voltageFault),
    .o_currentFault(o_16V_currentFault)
);

rail_good_generator Stage3(
    .i_rail1(o_1V8_railGood),
    .i_rail2(o_3V3ADC_railGood),
    .i_rail3(o_16V_railGood),
    .i_rail4(o_S2Good),
    .i_rail5(i_fpgaPwrGood),
    .o_allGood(o_S3Good)
);

endmodule
