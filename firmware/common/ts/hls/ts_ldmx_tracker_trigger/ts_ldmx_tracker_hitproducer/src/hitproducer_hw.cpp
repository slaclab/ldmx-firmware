#include <stdio.h>
#include <iostream>
#include "objdef.h"
#include "hitproducer.h"

void hitproducer_hw(ap_uint<14> FIFO[NHITS][5],Hit outHit[NHITS],ap_uint<8> Peds[NHITS]){
	#pragma HLS ARRAY_PARTITION variable=FIFO complete
	#pragma HLS ARRAY_PARTITION variable=outHit complete
	#pragma HLS ARRAY_PARTITION variable=Peds complete
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[0]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[1]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[2]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[3]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[4]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[5]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[6]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[7]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[8]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[9]

	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[10]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[11]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[12]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[13]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[14]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[15]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[16]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[17]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[18]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[19]

	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[20]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[21]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[22]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[23]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[24]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[25]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[26]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[27]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[28]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[29]

	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[30]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[31]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[32]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[33]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[34]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[35]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[36]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[37]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[38]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[39]

	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[40]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[41]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[42]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[43]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[44]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[45]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[46]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[47]

	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[48]
	#pragma HLS INTERFACE ap_fifo depth=16 port=FIFO[49]



	#pragma HLS PIPELINE

	for(int i = 0; i<NHITS;i++){
		#pragma HLS PIPELINE
		ap_uint<14> word1=FIFO[i][0];ap_uint<14> word2=FIFO[i][1];ap_uint<14> word3=FIFO[i][2];
		ap_uint<14> charge1;ap_uint<14> charge2;ap_uint<14> charge3;

		outHit[i].bID=-1;
		outHit[i].mID=0;
		outHit[i].Time=0;
		outHit[i].Amp=0;
		int j=0;
		for(int j = 0;j<3;j++){
			#pragma HLS PIPELINE
			//if(i==5){std::cout<<(word1 & 63)<<" "<<(word1>>6)<<std::endl;}
			if((0<(word1 & 63))and((word1 & 63)<50)){
				outHit[i].bID=i;
				outHit[i].mID=0;
				outHit[i].Time=(word1 & 63);

				if ((word1>>6)<64) {charge1=(word1>>6);}
				else if ((word1>>6)<2*64) {charge1=2*((word1>>6)-64)+16;}
				else if ((word1>>6)<3*64) {charge1=4*((word1>>6)-2*64)+(2+1)*16;}
				else{charge1=8*((word1>>6)-3*64)+(4+2+1)*16;}

				if((word2>>6)<64){charge2=(word2>>6);}
				else if((word2>>6)<2*64){charge2=2*((word2>>6)-64)+64;}
				else if((word2>>6)<3*64){charge2=4*((word2>>6)-2*64)+(2+1)*64;}
				else{charge2=8*((word2>>6)-3*64)+(4+2+1)*64;}

				if((word3>>6)<64){charge3=(word3>>6);}
				else if((word3>>6)<2*64){charge3=2*((word3>>6)-64)+64;}
				else if((word3>>6)<3*64){charge3=4*((word3>>6)-2*64)+(2+1)*64;}
				else{charge3=8*((word3>>6)-3*64)+(4+2+1)*64;}

				outHit[i].Amp=charge1+charge2+charge3-Peds[i];

				/*if((word1>>6)+(word2>>6)+(word3>>6)-Peds[i]<100){
					outHit[i].Amp=(word1>>6)+(word2>>6)+(word3>>6)-Peds[i];
				}
				else if((word1>>6)+(word2>>6)+(word3>>6)-Peds[i]<200){
					outHit[i].Amp=(word1>>6)+(word2>>6)+(word3>>6)-Peds[i]-100;
				}
				else{
					outHit[i].Amp=(word1>>6)+(word2>>6)+(word3>>6)-Peds[i]-200;
				}*/
				word1=0;word2=0;word3=0;
			}
			if(j<2){
				word1=word2;word2=word3;word3=FIFO[i][3+j];
			}
		}
	}

	return;
}

