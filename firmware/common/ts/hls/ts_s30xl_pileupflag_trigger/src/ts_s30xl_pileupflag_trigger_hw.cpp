#include <stdio.h>
#include <iostream>
#include "objdef.h"
#include "ts_s30xl_pileupflag_trigger_hw.h"



void ts_s30xl_pileupflag_trigger_hw(ap_uint<70> timestamp_in[1], ap_uint<1> bc0_in[1],ap_uint<70> timestamp_out[1], ap_uint<1> bc0_out[1],ap_uint<1> dataReady_in[1],ap_uint<1> dataReady_out[1],ap_uint<14> FIFO[NHITS],ap_uint<1> onflag[NHITS],ap_uint<17> amplitude[NHITS],ap_uint<1> pileup_out[NHITS]){
	#pragma HLS ARRAY_PARTITION variable=FIFO complete
	#pragma HLS ARRAY_PARTITION variable=amplitude complete
	#pragma HLS ARRAY_PARTITION variable=onflag complete
	#pragma HLS ARRAY_PARTITION variable=pileup_out complete


	#pragma HLS interface ap_ctrl_none port=return
	#pragma HLS INTERFACE ap_none port=dataReady_in[0]
	#pragma HLS INTERFACE ap_none port=dataReady_out[0]
	#pragma HLS INTERFACE ap_none port=timestamp_in[0]
	#pragma HLS INTERFACE ap_none port=timestamp_out[0]

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

	#pragma HLS INTERFACE ap_none port=pileup_out[0]
	#pragma HLS INTERFACE ap_none port=pileup_out[1]
	#pragma HLS INTERFACE ap_none port=pileup_out[2]
	#pragma HLS INTERFACE ap_none port=pileup_out[3]
	#pragma HLS INTERFACE ap_none port=pileup_out[4]
	#pragma HLS INTERFACE ap_none port=pileup_out[5]
	#pragma HLS INTERFACE ap_none port=pileup_out[6]
	#pragma HLS INTERFACE ap_none port=pileup_out[7]
	#pragma HLS INTERFACE ap_none port=pileup_out[8]
	#pragma HLS INTERFACE ap_none port=pileup_out[9]
	#pragma HLS INTERFACE ap_none port=pileup_out[10]
	#pragma HLS INTERFACE ap_none port=pileup_out[11]

	#pragma HLS INTERFACE ap_none port=amplitude[0]
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

	#pragma HLS INTERFACE ap_none port=onflag[0]
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

	ap_uint<14> nbins_[5] = {0, 16, 36, 57, 64};

	/// Charge lower limit of all the 16 subranges
	ap_uint<14> edges_[17] = {0,   34,    158,    419,    517,   915,
	                      1910,  3990,  4780,   7960,   15900, 32600,
	                      38900, 64300, 128000, 261000, 350000};
	/// sensitivity of the subranges (Total charge/no. of bins)
	ap_uint<14> sense_[16] = {3,   6,   12,  25, 25, 50, 99, 198,
	                      198, 397, 794, 1587, 1587, 3174, 6349, 12700};
	ap_uint<1> ready=0;
		/// Indices of first bin of each subrange
	if(dataReady_in[0]==1){
		ready=1;
	}
	dataReady_out[0]=ready;

	for(int i = 0; i<NHITS;i++){
		ap_uint<14> word1=FIFO[i];

		ap_uint<14> charge1;

		ap_uint<14> rr = (word1>>6)/64;
		ap_uint<14> v1 = (word1>>6)%64;
		ap_uint<14> ss = 1*(v1>nbins_[1])+1*(v1>nbins_[2])+1*(v1>nbins_[3]);
		charge1 = edges_[4*rr+ss]+(v1-nbins_[ss])*sense_[4*rr+ss]+sense_[4*rr+ss]/2-1;
		ap_uint<1> helper = 0;ap_uint<1> pup = 0;
		if(((charge1-36)*.00625)>=10){
			helper=1;
		}
		if(((charge1-36)*.00625)>=30){
			pup=1;
		}
		if(ready==0){
			helper=0;
			pup=0;
			charge1=36;
		}
		onflag[i]=helper;
		amplitude[i]=((charge1-36)*.00625);
		pileup_out[i]=pup;
	}
	bc0_out[0] = bc0_in[0];
	timestamp_out[0]=timestamp_in[0];
	return;
}
