#include <stdio.h>
#include <math.h>
#include <iostream>
#include <fstream>
#include "C:\Users\Rory\AppData\Roaming\Xilinx\Vitis\objdef.h"
#include "C:\Users\Rory\AppData\Roaming\Xilinx\Vitis\testutils.h"
#include "C:\Users\Rory\AppData\Roaming\Xilinx\Vitis\ts_s30xl_pileupst_trigger_hw.h"

int main(){
	ap_uint<17> outHit[NHITS];
	int COUNTER=0;
	int H = 0;
	std::ifstream TestVec("D:/352024/TestVec.dat", std::ifstream::in);
	int counterDiff=0;
	ap_uint<14> FIFO[NCHAN][6];
	int RECOHIT[NCHAN];
	//ap_uint<8> Peds[NCHAN];

	ap_uint<17> amplitude[NHITS];
	ap_uint<1> onflag[NHITS];

	std::string s;
	std::string token;
	std::string chID;
	bool readin = true;
	bool start = true;
	ap_uint<70> globalCount = 0;

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
		if(readin){
			//THIS IS THE INPUT ADC TDC BAR INFO
			if(s=="b"){
				globalCount+=1;
				readin=false;
				//I HAVE READIN ALL THE CHANNELS, TIME TO PUT IT INTO FIRMWARE
				std::cout<<"I MADE IT TO THE FIRMWARE"<<std::endl;
				//std::cout<<FIFO[9][0]<<" "<<FIFO[9][1]<<" "<<FIFO[9][2]<<std::endl;
				ap_uint<14> FIFO1[NCHAN];
				ap_uint<14> FIFO2[NCHAN];
				for(int HELPER1=0;HELPER1<NCHAN;HELPER1++){
					FIFO1[0]=FIFO[HELPER1][0];
					FIFO2[1]=FIFO[HELPER1][1];
				}
				ap_uint<1> dataReady_out[1]={0.0};
				ap_uint<70> timestamp_out[1]={0.0};
				ap_uint<70> timestamp_in[1]={globalCount};
				ap_uint<1> dataReady_in[1]={1};
				std::cout<<"BEFORE IF"<<std::endl;
				if(globalCount%2==0){
					std::cout<<"even"<<std::endl;
					dataReady_in[0]=0;
				}else{
					std::cout<<"odd"<<std::endl;
					dataReady_in[0]=1;
				}
				ts_s30xl_pileupst_trigger_hw(timestamp_in,timestamp_out,dataReady_in,dataReady_out,FIFO1,FIFO2,onflag,amplitude);
				std::cout<<"AFTER IF"<<std::endl;
				std::cout<<"I MADE IT AFTER THE FIRMWARE"<<std::endl;
				continue;
			}
			std::cout<<s<<std::endl;
			chID=s.substr(0,s.find(","));s=s.substr(s.find(",")+1);
			int counter=0;
			while(counter<12){
				token=s.substr(0,s.find(","));
				//std::cout<<token<<std::endl;
				if(counter<6){
					FIFO[(std::stoi(chID))][counter]=((ap_uint<14>)(std::stoi(token))<<6);
					counter++;
				}
				else{
					FIFO[(std::stoi(chID))][counter-6]+=((ap_uint<14>)(std::stoi(token)));
					//if(std::stoi(chID)==9){std::cout<<chID<<" "<<FIFO[(std::stoi(chID))][counter-6]<<std::endl;}
					counter++;
				}
				s=s.substr(s.find(",")+1);
		    }
		}else{
			//THIS IS THE OUTPUT RECO HIT AMP INFO
			if(s=="a"){
				readin = true;
				start = true;
				for(int i=0;i<NCHAN;i++){
					if(outHit[i]>0){
						std::cout<<"ONE FIRMWARE HIT AT "<<i<<" LIKE SO: "<<outHit[i]<<std::endl;
					}
				}
				std::cout<<COUNTER<<std::endl;
				COUNTER+=1;
				if(COUNTER==96){return 0;}
				continue;
			}
			std::cout<<"ONE LDMX-SW HIT AT "<<(std::stoi(s.substr(0,s.find(","))))<<" LIKE SO: "<<std::stoi(s.substr(s.find(",")+1))<<std::endl;
		}
	}
	std::cout<<"I GOT HERE 1"<<std::endl;
	TestVec.close();
	std::cout<<"I GOT HERE 2"<<std::endl;

	return 0;
}
