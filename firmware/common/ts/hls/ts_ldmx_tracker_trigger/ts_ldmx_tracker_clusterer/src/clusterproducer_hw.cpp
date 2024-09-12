#include <stdio.h>
#include <iostream>
#include "objdef.h"
#include "clusterproducer.h"

void clusterproducer_hw(Hit inHit[NHITS],Cluster outClus[NCLUS]){
	#pragma HLS ARRAY_PARTITION variable=inHit complete
	#pragma HLS ARRAY_PARTITION variable=outClus complete
	#pragma HLS PIPELINE

	ap_int<12> SEEDTHR = 30;
	ap_int<12> CLUSTHR = 30;

	ap_int<12> mapL1[NCHAN];
	#pragma HLS ARRAY_PARTITION variable=mapL1 complete

	//CLEAR THE MAP
	for(int i = 0;i<NCHAN;++i){
		#pragma HLS UNROLL
		mapL1[i]=-1;
	}
	//MAP TO CHANNELS
	for(int j =0; j<NHITS; ++j){
		#pragma HLS UNROLL
		if(inHit[j].bID>-1){
			//std::cout<<inHit[j].bID<<"   "<<inHit[j].Amp<<std::endl;
			mapL1[inHit[j].bID]=j;
		}
	}
	//NOW WE JUST LOOK FOR HITS EXCEEDING SEED, IF THEY DO WE PAIR 'EM.
	#pragma HLS pipeline off
	for(int k = 0; k<NCLUS; ++k){
		bool doNextCluster=true;
		if((mapL1[2*k]>-1)){
			if(inHit[mapL1[2*k]].Amp>SEEDTHR){
				clearClus(outClus[k]);
				outClus[k].Seed.mID=inHit[mapL1[2*k]].mID; outClus[k].Seed.bID=inHit[mapL1[2*k]].bID; outClus[k].Seed.Amp=inHit[mapL1[2*k]].Amp; outClus[k].Seed.Time=inHit[mapL1[2*k]].Time;
				if(mapL1[2*k+1]>-1){
					if(inHit[mapL1[2*k+1]].Amp>CLUSTHR){
						outClus[k].Sec.mID=inHit[mapL1[2*k+1]].mID; outClus[k].Sec.bID=inHit[mapL1[2*k+1]].bID; outClus[k].Sec.Amp=inHit[mapL1[2*k+1]].Amp; outClus[k].Sec.Time=inHit[mapL1[2*k+1]].Time;
						doNextCluster=false;
						//You can comment this line to turn it into Serialized
						clearHit(inHit[mapL1[2*k+1]]);
					}
				}
			}
		}
		if((mapL1[2*k+1]>-1)and(doNextCluster)){
			if(inHit[mapL1[2*k+1]].Amp>SEEDTHR){
				clearClus(outClus[k]);
				outClus[k].Seed.mID=inHit[mapL1[2*k+1]].mID; outClus[k].Seed.bID=inHit[mapL1[2*k+1]].bID; outClus[k].Seed.Amp=inHit[mapL1[2*k+1]].Amp; outClus[k].Seed.Time=inHit[mapL1[2*k+1]].Time;
				if(k<NCLUS-1){
					if(mapL1[2*k+2]>-1){
						if(inHit[mapL1[2*k+2]].Amp>CLUSTHR){
							outClus[k].Sec.mID=inHit[mapL1[2*k+2]].mID; outClus[k].Sec.bID=inHit[mapL1[2*k+2]].bID; outClus[k].Sec.Amp=inHit[mapL1[2*k+2]].Amp; outClus[k].Sec.Time=inHit[mapL1[2*k+2]].Time;
							//You can comment this line to turn it into Serialized
							clearHit(inHit[mapL1[2*k+2]]);
						}
					}
				}
			}
		}
	}
	return;
}

