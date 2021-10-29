`ifndef MYCPU_H
    `define MYCPU_H

    `define BR_BUS_WD       35
    `define FS_TO_DS_BUS_WD 72
    `define DS_TO_ES_BUS_WD 174
    `define ES_TO_MS_BUS_WD 172
    `define MS_TO_WS_BUS_WD 73
    
    `define ES_FORWARD_BUS_WD 42
    `define MS_FORWARD_BUS_WD 44
    `define WS_TO_RF_BUS_WD 41
    `define MS_TO_FS_BUS_WD 33
    `define MS_TO_ES_BUS_WD 55

    `define  CR_STATUS {5'd12,3'd0}
    `define  CR_CAUSE  {5'd13,3'd0}
    `define  CR_COMPARE {5'd11,3'd0}
    `define  CR_EPC    {5'd14,3'd0}
    `define  CR_BADVADDR   {5'd8,3'd0}
    `define  CR_COMPARE    {5'd11,3'd0}
    `define  CR_COUNT    {5'd9,3'd0}
    `define  CR_ENTRYHI  {5'd10,3'd0}
    `define  CR_ENTRYLO0  {5'd2,3'd0}
    `define  CR_ENTRYLO1  {5'd3,3'd0}
    `define  CR_INDEX     {5'd0,3'd0}
    
`endif
