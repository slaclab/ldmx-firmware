#include <stdio.h>
#include <math.h>
#include <iostream>
#include <fstream>
#include "objdef.h"
#include "testutils.h"
#include "trackproducer.h"
#include "clusterproducer.h"

int main(){
	//FIRST I AM GOING TO GENERATE THE LOOKUP TABLE
	//Alignment vector in terms of centroid position w.r.t. the position of the centroid in the first bar
	ap_int<12> A[3]={0,0,0};
	//We note the NCLUS is usually half the number of bars in a pad, so two times it is the number of bars, and four times is the number
	//minus 1 is the num of centroids where you are subtracting one bcause of the edge numerics.
	ap_int<12> LOOKUP[NCENT][COMBO][2];


	for(int i = 0; i<NCENT;i++){
		for(int j = 0; j<COMBO; j++){
			LOOKUP[i][j][0]=(i-A[1]+A[0]);LOOKUP[i][j][1]=(i-A[2]+A[0]);
			if(j/3==0){
				LOOKUP[i][j][0]-=1;
			}else if(j/3==2){
				LOOKUP[i][j][0]+=1;
			}
			if(j%3==0){
				LOOKUP[i][j][1]-=1;
			}else if(j%3==2){
				LOOKUP[i][j][1]+=1;
			}
			if(not((LOOKUP[i][j][0]>=0)and(LOOKUP[i][j][1]>=0)and(LOOKUP[i][j][0]<NCENT)and(LOOKUP[i][j][1]<NCENT))){
				LOOKUP[i][j][0]=-1;LOOKUP[i][j][1]=-1;
			}
		}
	}

	Hit HPad1[NHITS];
	Hit HPad2[NHITS];
	Hit HPad3[NHITS];

	Cluster Pad1[NTRK];
	Cluster Pad2[NCLUS];
	Cluster Pad3[NCLUS];
	Track outTrk[NTRK];
	int H = 0;

	std::ifstream inFileHit("hitVec.dat", std::ifstream::in);
	std::ifstream inFileCl("clusVec.dat", std::ifstream::in);
	std::ifstream inFileTrck("trackVec.dat", std::ifstream::in);

	int MISMATCH = 0;
	int CLUMISMATCH = 0;

	while(H<1400){
		for(int j = 0; j<NHITS; j++){
			clearHit(HPad1[j]);
			clearHit(HPad2[j]);
			clearHit(HPad3[j]);
		}
		for(int j = 0; j<NCLUS; j++){
			if(j<NTRK){
				clearClus(Pad1[j]);
			}
			clearClus(Pad2[j]);
			clearClus(Pad3[j]);
		}
		for(int j = 0; j<NTRK; j++){
			clearTrack(outTrk[j]);
		}


		//The upcoming lines read in Hits. Count3 keeps track of which pad we are on. When it reaches 3, it means we must escape the
		//file readout for hits because we have read all the hits in from each of the pads. When it hits a, we increament count3 and reset
		//count2, which is the hit number we are currently reading out WITHIN a Pad

		std::string s;
		std::string token;
		int count2 = 0;
		int count3 = 0;
		int stop = 0;
		while((inFileHit)and(stop==0)){
			std::getline(inFileHit,s);
			if(s=="a"){
				//std::cout<<"I SKIPPED SHIT BECAUSE A"<<std::endl;
				stop=0;
				count3++;
				count2=0;
				if(count3>=3){
					goto cnt;
				}
				continue;
			}
			if(count2>=3*NHITS){
				stop=1;
				continue;
			}

			token=s.substr(0,s.find(","));s=s.substr(s.find(",")+1);
			switch(count3){
				case 0:
					HPad1[count2].bID=(ap_int<12>)(std::stoi(token));//std::cout<<token+"\n"<<std::endl;
					token=s.substr(0,s.find(","));s=s.substr(s.find(",")+1);
					HPad1[count2].mID=(ap_int<12>)(std::stoi(token));//std::cout<<token+"\n"<<std::endl;
					token=s.substr(0,s.find(","));s=s.substr(s.find(",")+1);
					HPad1[count2].Amp=(ap_int<12>)(std::stoi(token));//std::cout<<token+"\n"<<std::endl;
					HPad1[count2].Time=(ap_int<12>)((int)(std::stof(s)));//std::cout<<s+"\n"<<std::endl;
					break;
				case 1:
					HPad2[count2].bID=(ap_int<12>)(std::stoi(token));//std::cout<<token+"\n"<<std::endl;
					token=s.substr(0,s.find(","));s=s.substr(s.find(",")+1);
					HPad2[count2].mID=(ap_int<12>)(std::stoi(token));//std::cout<<token+"\n"<<std::endl;
					token=s.substr(0,s.find(","));s=s.substr(s.find(",")+1);
					HPad2[count2].Amp=(ap_int<12>)(std::stoi(token));//std::cout<<token+"\n"<<std::endl;
					HPad2[count2].Time=(ap_int<12>)((int)(std::stof(s)));//std::cout<<s+"\n"<<std::endl;
					break;
				case 2:
					HPad3[count2].bID=(ap_int<12>)(std::stoi(token));//std::cout<<token+"\n"<<std::endl;
					token=s.substr(0,s.find(","));s=s.substr(s.find(",")+1);
					HPad3[count2].mID=(ap_int<12>)(std::stoi(token));//std::cout<<token+"\n"<<std::endl;
					token=s.substr(0,s.find(","));s=s.substr(s.find(",")+1);
					HPad3[count2].Amp=(ap_int<12>)(std::stoi(token));//std::cout<<token+"\n"<<std::endl;
					HPad3[count2].Time=(ap_int<12>)((int)(std::stof(s)));//std::cout<<s+"\n"<<std::endl;
					break;
				default:
					break;
			}
			count2++;
		}
		cnt:;
		//Numbers to keep track of clusters.
		int helper3=0;
		int helper4=0;
		//We are now creating the clusters from our read in hits
		//RESIZING THEM AS WELL
		int counterN=0;
		Cluster* Point1=clusterproducer_sw(HPad1);
		for(int i = 0; i<NCLUS; i++){
			if((Point1[i].Seed.Amp<8000)and(Point1[i].Seed.Amp>0)and(counterN<NTRK)){
				cpyHit(Pad1[counterN].Seed,Point1[i].Seed);cpyHit(Pad1[counterN].Sec,Point1[i].Sec);
				calcCent(Pad1[counterN]);
				//std::cout<<"Hello\n"<<Pad1[counterN].Seed.bID<<std::endl;
				//std::cout<<Pad1[counterN].Sec.bID<<std::endl;
				//std::cout<<Pad1[counterN].Cent<<"\n"<<std::endl;
				counterN++;
			}
		}
		Cluster* Point2=clusterproducer_sw(HPad2);
		for(int i = 0; i<NCLUS; i++){
			cpyHit(Pad2[i].Seed,Point2[i].Seed);cpyHit(Pad2[i].Sec,Point2[i].Sec);
			calcCent(Pad2[i]);
			//std::cout<<Pad2[i].Cent<<std::endl;
		}
		Cluster* Point3=clusterproducer_sw(HPad3);
		for(int i = 0; i<NCLUS; i++){
			cpyHit(Pad3[i].Seed,Point3[i].Seed);cpyHit(Pad3[i].Sec,Point3[i].Sec);
			calcCent(Pad3[i]);
			//std::cout<<Pad3[i].Cent<<std::endl;
		}
		std::cout<<"+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"<<std::endl;
		//Use this loop just to clean up the clusters. Was used to print stuff out before we moved all the printing to only occur if
		//we have a mismatch.

		for(int i = 0; i<3;i++){
			for(int j = 0; j<NCLUS; j++){
				switch(i){
					case 0 :
						if(j>=NTRK){
							continue;
						}
						if((Pad1[j].Cent>=0)and(Pad1[j].Seed.Amp<10000)){
							//std::cout<<Pad1[j].Seed.bID<<std::endl;
							//std::cout<<Pad1[j].Seed.Amp<<std::endl;
							//std::cout<<Pad1[j].Sec.bID<<std::endl;
							//std::cout<<Pad1[j].Sec.Amp<<std::endl;
							//std::cout<<Pad1[j].Cent<<"\n"<<std::endl;
							//continue;
							helper3++;
						}else{
							clearClus(Pad1[j]);
						}
						break;
					case 1 :
						if((Pad2[j].Cent>=0)and(Pad2[j].Seed.Amp<10000)){
							//std::cout<<Pad2[j].Seed.bID<<std::endl;
							//std::cout<<Pad2[j].Seed.Amp<<std::endl;
							//std::cout<<Pad2[j].Sec.bID<<std::endl;
							//std::cout<<Pad2[j].Sec.Amp<<std::endl;
							//std::cout<<Pad2[j].Cent<<"\n"<<std::endl;
							helper3++;
						}else{
							clearClus(Pad2[j]);
						}
						break;
					case 2 :
						if((Pad3[j].Cent>=0)and(Pad3[j].Seed.Amp<10000)){
							helper3++;
							//std::cout<<Pad3[j].Seed.bID<<std::endl;
							//std::cout<<Pad3[j].Seed.Amp<<std::endl;
							//std::cout<<Pad3[j].Sec.bID<<std::endl;
							//std::cout<<Pad3[j].Sec.Amp<<std::endl;
							//std::cout<<Pad3[j].Cent<<"\n"<<std::endl;
						}else{
							clearClus(Pad3[j]);
						}
						break;
					default :
						continue;
						//break;
				}
			}
		}
		//With all of this done, we can finally calculate the tracks from our clusters.
		for(int j = 0; j<NTRK; j++){
			clearTrack(outTrk[j]);
		}
		trackproducer_hw(Pad1,Pad2,Pad3,outTrk,LOOKUP);

		int helper1=0;
		int helper2=0;
		for(int i=0; i<NTRK; i++){
			//calcTCent(outTrk[i]);
			if(calcTCent(outTrk[i])>=0){
				helper1++;
			}
		}
		//std::cout<<"helper1 = "<<helper1<<std::endl;

		//JUST TO STORE THINGS FOR LATER PRINTING
		int numberTrk[10];
		int COUNT=0;
		for(int I=0;I<10;I++){
			numberTrk[I]=-1;
		}
		while(inFileTrck){
			std::getline(inFileTrck,s);
			if(s=="a"){
				goto cntTrk;
			}
			helper2++;
			numberTrk[COUNT]=(int)(std::stoi(s));
			COUNT++;
		}
		cntTrk:;
		//std::cout<<"helper2 = "<<helper2<<std::endl;
		//Now we only print things when something fails.
		bool byPass=true;
		bool readout=(not(helper1==helper2))or(byPass);
		if(readout){
			MISMATCH++;
			std::cout<<"First I'll Print the Hit Info"<<std::endl;
			std::cout<<"Pad1:"<<std::endl;
			for(int i=0;i<NHITS;i++){
				if(HPad1[i].Amp>0.0){
					std::cout<<HPad1[i].bID<<","<<HPad1[i].mID<<","<<HPad1[i].Amp<<","<<HPad1[i].Time<<std::endl;
				}
			}
			std::cout<<"Pad2:"<<std::endl;
			for(int i=0;i<NHITS;i++){
				if(HPad2[i].Amp>0.0){
					std::cout<<HPad2[i].bID<<","<<HPad2[i].mID<<","<<HPad2[i].Amp<<","<<HPad2[i].Time<<std::endl;
				}
			}
			std::cout<<"Pad3:"<<std::endl;
			for(int i=0;i<NHITS;i++){
				if(HPad3[i].Amp>0.0){
					std::cout<<HPad3[i].bID<<","<<HPad3[i].mID<<","<<HPad3[i].Amp<<","<<HPad3[i].Time<<std::endl;
				}
			}
			std::cout<<"Now Firmware Cluster Centroids: "<<std::endl;
			for(int i = 0; i<3;i++){
				std::cout<<"Pad"<<i+1<<":"<<std::endl;
				for(int j = 0; j<NCLUS; j++){
					switch(i){
						case 0 :
							if(j>=NTRK){
								continue;
							}
							if(Pad1[j].Cent>0){
								std::cout<<j<<" "<<Pad1[j].Cent<<std::endl;
								//continue;
							}else{
								clearClus(Pad1[j]);
							}
							break;
						case 1 :
							if(Pad2[j].Cent>0){
								std::cout<<j<<" "<<Pad2[j].Cent<<std::endl;
							}else{
								clearClus(Pad2[j]);
							}
							break;
						case 2 :
							if(Pad3[j].Cent>0){
								std::cout<<j<<" "<<Pad3[j].Cent<<std::endl;
							}else{
								clearClus(Pad3[j]);
							}
							break;
						default :
							continue;
							//break;
					}
				}
			}
			std::cout<<"Now Simulated Cluster Centroids: "<<std::endl;
		}
		count3 = 1;
		if(readout){std::cout<<"Pad1:"<<std::endl;}
		while(inFileCl){
			std::getline(inFileCl,s);
			if(s=="a"){
				count3++;
				if(count3>3){
					goto cntCl;
				}
				if(readout){std::cout<<"Pad"<<count3<<":"<<std::endl;}
				continue;
			}
			helper4++;
			if(readout){std::cout<<(int)(std::stoi(s))<<std::endl;}
		}
		cntCl:;
		if(readout){
			std::cout<<"Now Firmware Track Centroids: "<<std::endl;
			for(int i=0; i<NTRK; i++){
				if(calcTCent(outTrk[i])>0){
					std::cout<<calcTCent(outTrk[i])<<std::endl;
				}
			}
			std::cout<<"Now Simulated Track Centroids: "<<std::endl;
			for(int I=0;I<10;I++){
				if(not(numberTrk[I]==-1)){
					std::cout<<numberTrk[I]<<std::endl;
				}
			}
			if(not(helper3==helper4)){
				std::cout<<"This event was a cluster number mismatch; i.e. clusters feed in badly"<<std::endl;
				CLUMISMATCH++;
			}
		}
		H++;
	}
	std::cout<<"REMEMBER SMALL NUMBER GOOD"<<std::endl;
	std::cout<<"Out of "<<H<<" properly feed in events, we have "<<MISMATCH<<" with incorrectly identified tracks"<<std::endl;
	inFileHit.close();
	inFileCl.close();
	inFileTrck.close();
	return 0;
}
