#include <stdio.h>
#include <math.h>
#include <iostream>
#include <fstream>
#include "objdef.h"
#include "testutils.h"
#include "ts_s30xl_pileupflag_trigger_hw.h"

int main(){

	int counterErr=0;
	ap_uint<14> nbins_[5] = {0, 16, 36, 57, 64};

	/// Charge lower limit of all the 16 subranges
	ap_uint<14> edges_[17] = {0,   34,    158,    419,    517,   915,
	                      1910,  3990,  4780,   7960,   15900, 32600,
	                      38900, 64300, 128000, 261000, 350000};
	/// sensitivity of the subranges (Total charge/no. of bins)
	ap_uint<14> sense_[16] = {3,   6,   12,  25, 25, 50, 99, 198,
	                      198, 397, 794, 1587, 1587, 3174, 6349, 12700};

	ap_uint<17> outHit[NHITS];
	ap_uint<1> outflag[NHITS];
	ap_uint<1> pileup_out[NHITS];

	int H = 0;
	std::ifstream TestVec("TestVec.dat", std::ifstream::in);
	int counterDiff=0;
	ap_uint<14> FIFO[NCHAN][6];
	int RECOHIT[NCHAN];
	//ap_uint<8> Peds[NCHAN];

	std::string s;
	std::string token;
	std::string chID;
	bool readin = true;
	bool start = true;
	int counter1 = 0;
	ap_uint<70> globalCount = 0;
	bool amIOn = false;
	while(TestVec){
		if(start){
			for(int i = 0; i < NCHAN; i++){
				FIFO[i][0]=(0<<6)+63;
				FIFO[i][1]=(0<<6)+63;
				FIFO[i][2]=(0<<6)+63;
				FIFO[i][3]=(0<<6)+63;
				FIFO[i][4]=(0<<6)+63;
				FIFO[i][5]=(0<<6)+63;
			}
			start=false;
		}
		std::getline(TestVec,s);
		if(s=="end"){
			goto endloop;
		}
		if(readin){
			//THIS IS THE INPUT ADC TDC BAR INFO
			if(s=="b"){
				globalCount+=1;
				readin=false;
				//I HAVE READIN ALL THE CHANNELS, TIME TO PUT IT INTO FIRMWARE
				ap_uint<14> FIFO2[NHITS];
				for(int k=0;k<NCHAN;k++){
					FIFO2[k]=FIFO[k][1];
					//std::cout<<FIFO2[k]<<std::endl;
				}
				ap_uint<1> dataReady_out[1]={0.0};
				ap_uint<1> bc0_out[1]={globalCount};
				ap_uint<70> timestamp_out[1]={0.0};
				ap_uint<70> timestamp_in[1]={globalCount};
				ap_uint<1> bc0_in[1]={globalCount};
				ap_uint<1> dataReady_in[1]={1};
				if(globalCount%2==0){
					std::cout<<"even"<<std::endl;
					dataReady_in[0]=0;
				}else{
					std::cout<<"odd"<<std::endl;
					dataReady_in[0]=1;
				}
				ts_s30xl_pileupflag_trigger_hw(timestamp_in,bc0_in,timestamp_out,bc0_out,dataReady_in,dataReady_out,FIFO2,outflag,outHit,pileup_out);
				std::cout<<timestamp_out[0]<<std::endl;
				if(!(timestamp_out[0]==globalCount)){
					std::cout<<globalCount<<std::endl;
					return -1;
				}
				if(!(dataReady_in[0]==dataReady_out[0])){
					std::cout<<dataReady_in[0]<<std::endl;
					return -1;
				}
				if(dataReady_in[0]==1){
					amIOn = true;
				}
				continue;
			}
			std::cout<<s<<std::endl;
			chID=s.substr(0,s.find(","));s=s.substr(s.find(",")+1);
			int counter=0;
			while(counter<12){
				token=s.substr(0,s.find(","));
				//std::cout<<token<<std::endl;
				if(counter<6){
					//PUTS IN ADC
					FIFO[(std::stoi(chID))][counter]=((ap_uint<14>)(std::stoi(token))<<6);
					counter++;
				}
				else{
					//PUTS IN TIME CODE
					FIFO[(std::stoi(chID))][counter-6]+=((ap_uint<14>)(std::stoi(token)));
					//if(std::stoi(chID)==9){std::cout<<chID<<" "<<FIFO[(std::stoi(chID))][counter-6]<<std::endl;}
					counter++;
				}
				s=s.substr(s.find(",")+1);
		    }
		}else{
			//THIS IS THE OUTPUT RECO HIT AMP INFO
			if(s=="a"){
				int counter2=0;
				readin = true;
				start = true;
				for(int i=0;i<NCHAN;i++){
					if(outHit[i]>0){
						std::cout<<"ONE FIRMWARE HIT AT "<<i<<" LIKE SO: "<<outHit[i]<<std::endl;
					}
					if(outflag[i]>0){
						std::cout<<"WE HAVE A READY FLAG AT "<<i<<std::endl;
						counter2+=1;
					}
				}
				if(!(counter1-counter2==0)){
					std::cout<<"LOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOK"<<std::endl;
					if(amIOn){
						counterErr+=1;
					}
				}
				amIOn=false;
				counter1=0;
				continue;
			}
			std::cout<<"ONE LDMX-SW HIT AT "<<(std::stoi(s.substr(0,s.find(","))))<<" LIKE SO: "<<std::stoi(s.substr(s.find(",")+1))<<std::endl;
			counter1+=1;
		}
	}
	endloop:
	std::cout<<"I READ TO END OF FILE"<<std::endl;
	TestVec.close();
	std::cout<<counterErr<<std::endl;
	return 1*(counterErr>110);
}

