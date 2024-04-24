#ifndef HITPRODUCER_H
#define HITPRODUCER_H

#include "C:\Users\Rory\AppData\Roaming\Xilinx\Vitis\objdef.h"
//,ap_uint<8> Peds[NHITS]
void copyHit1(Hit One, Hit Two);
void copyHit2(Hit One, Hit Two);
void hitproducerStream_ref(ap_uint<14> FIFO[NHITS],ap_uint<17> amplitude[NHITS],ap_uint<1> onflag[NHITS]);
void hitproducerStream_hw(ap_uint<14> FIFO[NHITS],ap_uint<17> amplitude[NHITS],ap_uint<1> onflag[NHITS]);

#endif
