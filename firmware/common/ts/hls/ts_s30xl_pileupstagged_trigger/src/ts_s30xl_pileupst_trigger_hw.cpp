#include <stdio.h>
#include <iostream>
#include "C:\Users\Rory\AppData\Roaming\Xilinx\Vitis\objdef.h"
#include "C:\Users\Rory\AppData\Roaming\Xilinx\Vitis\ts_s30xl_pileupst_trigger_hw.h"

void ts_s30xl_pileupst_trigger_hw(ap_uint<70> timestamp_in[1], ap_uint<1> bc0_in[1],ap_uint<70> timestamp_out[1], ap_uint<1> bc0_out[1],ap_uint<1> dataReady_in[1],ap_uint<1> dataReady_out[1],ap_uint<14> FIFO1[NHITS],ap_uint<14> FIFO2[NHITS],ap_uint<1> onflag[NHITS],ap_uint<17> amplitude[NHITS]){
	#pragma HLS ARRAY_PARTITION variable=FIFO1 complete
	#pragma HLS ARRAY_PARTITION variable=FIFO2 complete
	#pragma HLS ARRAY_PARTITION variable=amplitude complete
	#pragma HLS ARRAY_PARTITION variable=onflag complete

	#pragma HLS interface ap_ctrl_none port=return
	#pragma HLS INTERFACE ap_none port=dataReady_in[0]
	#pragma HLS INTERFACE ap_none port=dataReady_out[0]
	#pragma HLS INTERFACE ap_none port=timestamp_in[0]
	#pragma HLS INTERFACE ap_none port=timestamp_out[0]

	//#pragma HLS ARRAY_PARTITION variable=Peds complete
	#pragma HLS INTERFACE ap_none depth=16 port=FIFO1[0]
	#pragma HLS INTERFACE ap_none depth=16 port=FIFO1[1]
	#pragma HLS INTERFACE ap_none depth=16 port=FIFO1[2]
	#pragma HLS INTERFACE ap_none depth=16 port=FIFO1[3]
	#pragma HLS INTERFACE ap_none depth=16 port=FIFO1[4]
	#pragma HLS INTERFACE ap_none depth=16 port=FIFO1[5]
	#pragma HLS INTERFACE ap_none depth=16 port=FIFO1[6]
	#pragma HLS INTERFACE ap_none depth=16 port=FIFO1[7]
	#pragma HLS INTERFACE ap_none depth=16 port=FIFO1[8]
	#pragma HLS INTERFACE ap_none depth=16 port=FIFO1[9]
	#pragma HLS INTERFACE ap_none depth=16 port=FIFO1[10]
	#pragma HLS INTERFACE ap_none depth=16 port=FIFO1[11]

	#pragma HLS INTERFACE ap_none depth=16 port=FIFO2[0]
	#pragma HLS INTERFACE ap_none depth=16 port=FIFO2[1]
	#pragma HLS INTERFACE ap_none depth=16 port=FIFO2[2]
	#pragma HLS INTERFACE ap_none depth=16 port=FIFO2[3]
	#pragma HLS INTERFACE ap_none depth=16 port=FIFO2[4]
	#pragma HLS INTERFACE ap_none depth=16 port=FIFO2[5]
	#pragma HLS INTERFACE ap_none depth=16 port=FIFO2[6]
	#pragma HLS INTERFACE ap_none depth=16 port=FIFO2[7]
	#pragma HLS INTERFACE ap_none depth=16 port=FIFO2[8]
	#pragma HLS INTERFACE ap_none depth=16 port=FIFO2[9]
	#pragma HLS INTERFACE ap_none depth=16 port=FIFO2[10]
	#pragma HLS INTERFACE ap_none depth=16 port=FIFO2[11]

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

	/// Indices of first bin of each subrange
	ap_uint<14> nbins_[5] = {0, 16, 36, 57, 64};

	/// Charge lower limit of all the 16 subranges
	ap_uint<14> edges_[17] = {0,   34,    158,    419,    517,   915,
	                      1910,  3990,  4780,   7960,   15900, 32600,
	                      38900, 64300, 128000, 261000, 350000};
	/// sensitivity of the subranges (Total charge/no. of bins)
	ap_uint<14> sense_[16] = {3,   6,   12,  25, 25, 50, 99, 198,
	                      198, 397, 794, 1587, 1587, 3174, 6349, 12700};
	//Fall Time In Terms of TDC SAMPLES
	ap_uint<12> fallTime=2;


	ap_uint<1> ready=0;
	/// Indices of first bin of each subrange
	if(dataReady_in[0]==1){
		ready=1;
	}
	dataReady_out[0]=ready;

	for(int i = 0; i<NHITS;i++){
		ap_uint<14> word1=FIFO1[i];ap_uint<14> word2=FIFO2[i];
		ap_uint<14> charge1;ap_uint<14> charge2;

		ap_uint<14> rr = (word1>>6)/64;
		ap_uint<14> v1 = (word1>>6)%64;
		ap_uint<14> ss = 1*(v1>nbins_[1])+1*(v1>nbins_[2])+1*(v1>nbins_[3]);
		charge1 = edges_[4*rr+ss]+(v1-nbins_[ss])*sense_[4*rr+ss]+sense_[4*rr+ss]/2-1;

		rr = (word2>>6)/64;
		v1 = (word2>>6)%64;
		ss = 1*(v1>nbins_[1])+1*(v1>nbins_[2])+1*(v1>nbins_[3]);
		charge2 = edges_[4*rr+ss]+(v1-nbins_[ss])*sense_[4*rr+ss]+sense_[4*rr+ss]/2-1;
		ap_uint<1> helper = 0;
		ap_uint<6> tdc1 = (word1&63);
		ap_uint<6> tdc2 = (word2&63);
		//Time samples between pulses
		ap_uint<14> decayLengths=(tdc1+(50-tdc2))/fallTime;
		ap_uint<14> bigC=charge1;
		if(decayLengths>1){bigC=bigC/3;}
		if(decayLengths>2){bigC=bigC/3;}
		if(decayLengths>3){bigC=bigC/3;}
		if(decayLengths>4){bigC=bigC/3;}
		if((charge2-bigC-36)*.00625>=10){
			helper=1;
		}
		if(ready==0){
			charge2=bigC+36;
			helper=0;
		}
		onflag[i]=helper;
		amplitude[i]=((charge2-bigC-36)*.00625);
	}
	timestamp_out[0]=timestamp_in[0];
	bc0_out[0] = bc0_in[0];
	return;
}

