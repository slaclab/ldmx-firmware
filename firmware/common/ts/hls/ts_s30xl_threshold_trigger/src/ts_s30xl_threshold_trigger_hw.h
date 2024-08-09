#ifndef TS_S30XL_THRESHOLD_TRIGGER_H
#define TS_S30XL_THRESHOLD_TRIGGER_H

#include "objdef.h"
//,ap_uint<8> Peds[NHITS]
void copyHit1(Hit One, Hit Two);
void copyHit2(Hit One, Hit Two);
void ts_s30xl_threshold_triggr_ref(ap_uint<70> timestamp_in[1],
                                   ap_uint<70> timestamp_out[1],
                                   ap_uint<1> dataReady_in[1],
                                   ap_uint<1> dataReady_out[1],
                                   ap_uint<14> FIFO[NHITS],
                                   ap_uint<1> outflag[NHITS],
                                   ap_uint<17> outHits[NHITS]);
void ts_s30xl_threshold_trigger_hw(ap_uint<70> timestamp_in[1],
                                   ap_uint<70> timestamp_out[1],
                                   ap_uint<1> dataReady_in[1],
                                   ap_uint<1> dataReady_out[1],
                                   ap_uint<14> FIFO[NHITS],
                                   ap_uint<1> outflag[NHITS],
                                   ap_uint<17> outHits[NHITS]);

#endif
