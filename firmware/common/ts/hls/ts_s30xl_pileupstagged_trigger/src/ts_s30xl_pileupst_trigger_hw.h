#ifndef TS_S30XL_PILEUPST_TRIGGER_H
#define TS_S30XL_PILEUPST_TRIGGER_H

#include "C:\Users\Rory\AppData\Roaming\Xilinx\Vitis\objdef.h"
//,ap_uint<8> Peds[NHITS]
void copyHit1(Hit One, Hit Two);
void copyHit2(Hit One, Hit Two);
void ts_s30xl_pileupst_trigger_ref(ap_uint<70> timestamp_in[1],ap_uint<70> timestamp_out[1],ap_uint<1> dataReady_in[1],ap_uint<1> dataReady_out[1],ap_uint<14> FIFO1[NHITS],ap_uint<14> FIFO2[NHITS],ap_uint<1> onflag[NHITS],ap_uint<17> amplitude[NHITS]);
void ts_s30xl_pileupst_trigger_hw(ap_uint<70> timestamp_in[1],ap_uint<70> timestamp_out[1],ap_uint<1> dataReady_in[1],ap_uint<1> dataReady_out[1],ap_uint<14> FIFO1[NHITS],ap_uint<14> FIFO2[NHITS],ap_uint<1> onflag[NHITS],ap_uint<17> amplitude[NHITS]);

#endif
