#include <stdio.h>
#include <iostream>
#include "C:\Users\Rory\AppData\Roaming\Xilinx\Vitis\objdef.h"
#include "C:\Users\Rory\AppData\Roaming\Xilinx\Vitis\S30XLhitproducerStream_hw.h"



void hitproducerStream_hw(OutPutBus *oBus,InPutBus *iBus){
	#pragma HLS interface ap_ctrl_none port=return
	#pragma HLS INTERFACE ap_none port=iBus
	#pragma HLS INTERFACE ap_none port=oBus
	#pragma HLS aggregate variable=iBus
	#pragma HLS aggregate variable=oBus
	#pragma HLS PIPELINE

	/// Indices of first bin of each subrange
	if(iBus->dataReady_in==0){
		oBus->dataReady_out=0;
		return;
	}

	ap_uint<14> nbins_[5] = {0, 16, 36, 57, 64};

	/// Charge lower limit of all the 16 subranges
	ap_uint<14> edges_[17] = {0,   34,    158,    419,    517,   915,
	                      1910,  3990,  4780,   7960,   15900, 32600,
	                      38900, 64300, 128000, 261000, 350000};
	/// sensitivity of the subranges (Total charge/no. of bins)
	ap_uint<14> sense_[16] = {3,   6,   12,  25, 25, 50, 99, 198,
	                      198, 397, 794, 1587, 1587, 3174, 6349, 12700};
	for(int i = 0; i<NHITS;i++){
		ap_uint<14> word1=iBus->FIFO[i];

		ap_uint<14> charge1;

		ap_uint<14> rr = (word1>>6)/64;
		ap_uint<14> v1 = (word1>>6)%64;
		ap_uint<14> ss = 1*(v1>nbins_[1])+1*(v1>nbins_[2])+1*(v1>nbins_[3]);
		charge1 = edges_[4*rr+ss]+(v1-nbins_[ss])*sense_[4*rr+ss]+sense_[4*rr+ss]/2-1;
		ap_uint<1> helper = 0;
		if(((charge1-36)*.00625)>=10){
			helper=1;
		}
		oBus->dataReady_out=1;
		oBus->timestamp_out=iBus->timestamp_in;
		oBus->onflag[i]=helper;
		oBus->amplitude[i]=((charge1-36)*.00625);
	}

	return;
}
