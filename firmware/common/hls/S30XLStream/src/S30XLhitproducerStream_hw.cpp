#include <stdio.h>
#include <iostream>
#include "objdef.h"
#include "S30XLhitproducerStream_hw.h"

void hitproducerStream_hw(ap_uint<1> dataReady,ap_uint<14> FIFO[NHITS],ap_uint<17> amplitude[NHITS],ap_uint<1> onflag[NHITS]){
	#pragma HLS ARRAY_PARTITION variable=FIFO complete
	#pragma HLS ARRAY_PARTITION variable=amplitude complete
	#pragma HLS ARRAY_PARTITION variable=onflag complete
	//#pragma HLS ARRAY_PARTITION variable=Peds complete

	//FIFO IS NOT A FIFO LOL IT IS AN AXI STREAM NOW

	#pragma HLS INTERFACE ap_vld port=dataReady

	#pragma HLS INTERFACE ap_none port=FIFO[0]
	#pragma HLS INTERFACE ap_none port=FIFO[1]
	#pragma HLS INTERFACE ap_none port=FIFO[2]
	#pragma HLS INTERFACE ap_none port=FIFO[3]
	#pragma HLS INTERFACE ap_none port=FIFO[4]
	#pragma HLS INTERFACE ap_none port=FIFO[5]
	#pragma HLS INTERFACE ap_none port=FIFO[6]
	#pragma HLS INTERFACE ap_none port=FIFO[7]
	#pragma HLS INTERFACE ap_none port=FIFO[8]
	#pragma HLS INTERFACE ap_none port=FIFO[9]
	#pragma HLS INTERFACE ap_none port=FIFO[10]
	#pragma HLS INTERFACE ap_none port=FIFO[11]

	#pragma HLS INTERFACE ap_none port=amplitude[1]
	#pragma HLS INTERFACE ap_none port=amplitude[2]
	#pragma HLS INTERFACE ap_none port=amplitude[3]
	#pragma HLS INTERFACE ap_none port=amplitude[4]
	#pragma HLS INTERFACE ap_none port=amplitude[5]
	#pragma HLS INTERFACE ap_none port=amplitude[6]
	#pragma HLS INTERFACE ap_none port=amplitude[7]
	#pragma HLS INTERFACE ap_none port=amplitude[8]
	#pragma HLS INTERFACE ap_none port=amplitude[9]
	#pragma HLS INTERFACE ap_none port=amplitude[10]
	#pragma HLS INTERFACE ap_none port=amplitude[11]

	#pragma HLS INTERFACE ap_none port=onflag[1]
	#pragma HLS INTERFACE ap_none port=onflag[2]
	#pragma HLS INTERFACE ap_none port=onflag[3]
	#pragma HLS INTERFACE ap_none port=onflag[4]
	#pragma HLS INTERFACE ap_none port=onflag[5]
	#pragma HLS INTERFACE ap_none port=onflag[6]
	#pragma HLS INTERFACE ap_none port=onflag[7]
	#pragma HLS INTERFACE ap_none port=onflag[8]
	#pragma HLS INTERFACE ap_none port=onflag[9]
	#pragma HLS INTERFACE ap_none port=onflag[10]
	#pragma HLS INTERFACE ap_none port=onflag[11]


	#pragma HLS PIPELINE

	/// Indices of first bin of each subrange
	if(dataReady==0){
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
		ap_uint<14> word1=FIFO[i];
		ap_uint<14> charge1;

		ap_uint<14> rr = (word1>>6)/64;
		ap_uint<14> v1 = (word1>>6)%64;
		ap_uint<14> ss = 1*(v1>nbins_[1])+1*(v1>nbins_[2])+1*(v1>nbins_[3]);
		charge1 = edges_[4*rr+ss]+(v1-nbins_[ss])*sense_[4*rr+ss]+sense_[4*rr+ss]/2-1;
		amplitude[i]=((charge1-36)*.00625);
		if(amplitude[i]>=10){
			onflag[i]=1;
		}else{
			onflag[i]=0;
		}
	}

	return;
}
