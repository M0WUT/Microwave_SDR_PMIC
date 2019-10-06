module pmic_top(
    input i_12V_voltageGood,
    input i_12V_currentGood,
    output o_12V_redLED,
    output o_12V_greenLED,
    output o_12V_blueLED,

    input i_3V3_voltageGood,
    input i_3V3_currentGood,
    output o_3V3_redLED,
    output o_3V3_greenLED,
    output o_3V3_blueLED,

    input i_5V_voltageGood,
    input i_5V_currentGood,
    output o_5V_redLED,
    output o_5V_greenLED,
    output o_5V_blueLED,

    input i_1V8_voltageGood,
    input i_1V8_currentGood,
    output o_1V8_redLED,
    output o_1V8_greenLED,
    output o_1V8_blueLED,

    input i_3V3ADC_voltageGood,
    input i_3V3ADC_currentGood,
    output o_3V3ADC_redLED,
    output o_3V3ADC_greenLED,
    output o_3V3ADC_blueLED,

    input i_16V_voltageGood,
    input i_16V_currentGood,
    output o_16V_redLED,
    output o_16V_greenLED,
    output o_16V_blueLED,

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
    .o_railGood(o_12V_greenLED), 
    .o_voltageFault(o_12V_blueLED),
    .o_currentFault(o_12V_redLED)
);

rail_good_generator Stage1(
    .i_rail1(o_12V_greenLED),
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
    .o_railGood(o_3V3_greenLED), 
    .o_voltageFault(o_3V3_blueLED),
    .o_currentFault(o_3V3_redLED)
);

rail_monitor Rail_5V(
    .i_voltageGood(i_5V_voltageGood),
    .i_currentGood(i_5V_currentGood),
    .i_resetn(resetn),
    .o_railGood(o_5V_greenLED), 
    .o_voltageFault(o_5V_blueLED),
    .o_currentFault(o_5V_redLED)
);

rail_good_generator Stage2(
    .i_rail1(o_3V3_greenLED),
    .i_rail2(o_5V_greenLED),
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
    .o_railGood(o_1V8_greenLED), 
    .o_voltageFault(o_1V8_blueLED),
    .o_currentFault(o_1V8_redLED)
);

rail_monitor Rail_3V3ADC(
    .i_voltageGood(i_3V3ADC_voltageGood),
    .i_currentGood(i_3V3ADC_currentGood),
    .i_resetn(resetn),
    .o_railGood(o_3V3ADC_greenLED), 
    .o_voltageFault(o_3V3ADC_blueLED),
    .o_currentFault(o_3V3ADC_redLED)
);

rail_monitor Rail_16V(
    .i_voltageGood(i_16V_voltageGood),
    .i_currentGood(i_16V_currentGood),
    .i_resetn(resetn),
    .o_railGood(o_16V_greenLED), 
    .o_voltageFault(o_16V_blueLED),
    .o_currentFault(o_16V_redLED)
);

rail_good_generator Stage3(
    .i_rail1(o_1V8_greenLED),
    .i_rail2(o_3V3ADC_greenLED),
    .i_rail3(o_16V_greenLED),
    .i_rail4(o_S2Good),
    .i_rail5(i_fpgaPwrGood),
    .o_allGood(o_S3Good)
);

endmodule
