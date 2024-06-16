#include <stdio.h>
#include <math.h>
#include <iostream>
#include <fstream>
#include "objdef.h"
#include "testutils.h"
#include "clusterproducer.h"
#include "ap_int.h"

int main(){
	Hit inHit[NHITS];
	Cluster outCluster[NCHAN];


	Hit holderHit[NCHAN];

	int H = 0;
	std::ifstream inFile("inputTestVec.dat", std::ifstream::in);
	std::ifstream inFileCl("outputTestVec.dat", std::ifstream::in);
	int counterDiff=0;
	while(H<4000){
		bool doIPrint=false;
		for(int j = 0; j<NHITS; j++){
			clearHit(inHit[j]);
		}
		for(int j = 0; j<NCLUS; j++){
			clearClus(outCluster[j]);
		}
		std::string s;
		int counter=0;
		int stop=0;
		//std::cout<<"First I'll Print the Hit Info"<<std::endl;
		while((inFile)and(stop==0)){
			std::getline(inFile,s);
			//std::cout<<s<<std::endl;
			if(s=="a"){
				//std::cout<<"I SKIPPED SHIT BECAUSE A"<<std::endl;
				stop=0;
				goto cnt;
			}
			//std::cout<<s<<std::endl;
			if(counter>=NHITS){
				//std::cout<<"I SKIPPED SHIT BECAUSE NHITS"<<std::endl;
				stop=1;
				continue;
				//goto cnt;
			}
			std::string token=s.substr(0,s.find(","));s=s.substr(s.find(",")+1);
			inHit[counter].bID=(ap_int<12>)(std::stoi(token));//std::cout<<token+"\n"<<std::endl;
			token=s.substr(0,s.find(","));s=s.substr(s.find(",")+1);
			inHit[counter].mID=(ap_int<12>)(std::stoi(token));//std::cout<<token+"\n"<<std::endl;
			token=s.substr(0,s.find(","));s=s.substr(s.find(",")+1);
			inHit[counter].Amp=(ap_int<12>)(std::stoi(token));//std::cout<<token+"\n"<<std::endl;
			inHit[counter].Time=(ap_int<12>)((int)(std::stof(s)));//std::cout<<s+"\n"<<std::endl;
			counter++;
		}
		cnt:;
		clusterproducer_hw(inHit,outCluster);
		int NUMFIRM=0;
		for(int i = 0; i< NCLUS; ++i){
			if(outCluster[i].Seed.Amp>0){
				//std::cout<<(int)(100.*((float)(outCluster[i].Seed.Amp*outCluster[i].Seed.bID+outCluster[i].Sec.Amp*outCluster[i].Sec.bID))/((float)(outCluster[i].Seed.Amp+outCluster[i].Sec.Amp)))<<std::endl;
				NUMFIRM++;
			}
			//output << std::to_string(outCluster[i].Seed.bID);
		}
		//std::cout<<"\n"<<std::endl;
		int NUMSIM=0;
		while(inFileCl){
			std::getline(inFileCl,s);
			if(s=="a"){
				//stopCl=0;
				goto cntCl;
			}
			holderHit[NUMSIM].bID=std::stoi(s);
			//doIPrint=(doIPrint)or(not(helper==0));
			int upto = NUMSIM;
			int curr = 0;
			int HOLD = 0;
			for(int i=0; i<NUMFIRM; i++){
				if(outCluster[i].Seed.Amp>0){
					if(curr==upto){
						//std::cout << holderHit[NUMSIM].bID << std::endl;
						HOLD = (int)(100.*((float)(outCluster[i].Seed.Amp*outCluster[i].Seed.bID+outCluster[i].Sec.Amp*outCluster[i].Sec.bID))/((float)(outCluster[i].Seed.Amp+outCluster[i].Sec.Amp)));
						//std::cout << HOLD << std::endl;
						//doIPrint=(doIPrint)or(not(holderHit[NUMSIM].bID==HOLD));
						//curr++;
					}else{
						curr++;
					}
				}
			}

			NUMSIM++;
		}
		cntCl:;
		doIPrint=(doIPrint)or(not(NUMSIM==NUMFIRM));
		doIPrint=true;
		if(doIPrint){
			std::cout<<"First I'll Print the Hit Info"<<std::endl;
			for(int i=0;i<NHITS;i++){
				if(inHit[i].Amp>0.0){
					std::cout<<inHit[i].bID<<","<<inHit[i].mID<<","<<inHit[i].Amp<<","<<inHit[i].Time<<std::endl;
				}
			}
			std::cout<<"Now I print out Cluster Info"<<std::endl;
			std::cout<<"First Firmware Cluster Centroids: "<<std::endl;
			for(int i = 0; i< NCLUS; ++i){
				if(outCluster[i].Seed.Amp>0){
					std::cout<<(int)(100.*((float)(outCluster[i].Seed.Amp*outCluster[i].Seed.bID+outCluster[i].Sec.Amp*outCluster[i].Sec.bID))/((float)(outCluster[i].Seed.Amp+outCluster[i].Sec.Amp)))<<std::endl;
				}
			}
			std::cout<<"Now Simulated Cluster Centroids: "<<std::endl;
			for(int i=0;i<NHITS;i++){
				if(holderHit[i].bID>0){
					std::cout<<holderHit[i].bID<<std::endl;
				}
			}
			std::cout<<"\n"<<std::endl;
			counterDiff++;
		}
		for(int j = 0; j<NHITS; j++){
			clearHit(inHit[j]);
		}
		for(int j = 0; j<NCLUS; j++){
			clearClus(outCluster[j]);
		}
		for(int j = 0; j<NHITS; j++){
			clearHit(holderHit[j]);
		}

		H++;
	}
	std::cout<<"The number of mismatched events are: "<<counterDiff<<std::endl;
	std::cout<<"out of "<<H<<std::endl;
	inFile.close();
	inFileCl.close();
	return 0;
}
