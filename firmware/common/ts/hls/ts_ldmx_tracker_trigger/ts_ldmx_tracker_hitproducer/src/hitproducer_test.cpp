#include <stdio.h>
#include <math.h>
#include <iostream>
#include <fstream>
#include "objdef.h"
#include "testutils.h"
#include "hitproducer.h"

int main(){
	Hit outHit[NHITS];

	int H = 0;
	std::ifstream inFileDigi("FIFOVec.dat", std::ifstream::in);
	std::ifstream inFileHit("hitVec.dat", std::ifstream::in);
	std::ifstream inFilePeds("Peds.dat", std::ifstream::in);
	int counterDiff=0;
	ap_uint<14> FIFO[NCHAN][5];
	ap_uint<8> Peds[NCHAN];

	while(H<10){
		std::string s;
		std::string chID;
		std::string token;
		int counter = 0;
		while(inFilePeds){
			std::getline(inFilePeds,s);
			Peds[counter]=std::stoi(s);
			counter++;
		}
		for(int i = 0; i < NCHAN; i++){
			FIFO[i][0]=(Peds[i]<<6)+63;
			FIFO[i][1]=(Peds[i]<<6)+63;
			FIFO[i][2]=(Peds[i]<<6)+63;
			FIFO[i][3]=(Peds[i]<<6)+63;
			FIFO[i][4]=(Peds[i]<<6)+63;
		}
		int stop = 0;
		std::cout<<"First I will print the FIFO Inputs: "<<std::endl;
		while((inFileDigi)and(stop==0)){
			std::getline(inFileDigi,s);
			if(s=="a"){
				stop=0;
				goto cnt;
			}
			std::cout<<s<<std::endl;
			chID=s.substr(0,s.find(","));s=s.substr(s.find(",")+1);
			token=s.substr(0,s.find(","));s=s.substr(s.find(",")+1);
			FIFO[(std::stoi(chID))][0]=(ap_uint<14>)(std::stoi(token));
			std::cout<<"FIFO AMPLITUDE IS :"<<(FIFO[(std::stoi(chID))][0]>>6)<<", FIFO TIME IS :"<<(FIFO[(std::stoi(chID))][0] & 63)<<std::endl;
			token=s.substr(0,s.find(","));s=s.substr(s.find(",")+1);
			FIFO[(std::stoi(chID))][1]=(ap_uint<14>)(std::stoi(token));
			std::cout<<"FIFO AMPLITUDE IS :"<<(FIFO[(std::stoi(chID))][1]>>6)<<", FIFO TIME IS :"<<(FIFO[(std::stoi(chID))][1] & 63)<<std::endl;
			token=s.substr(0,s.find(","));s=s.substr(s.find(",")+1);
			FIFO[(std::stoi(chID))][2]=(ap_uint<14>)(std::stoi(token));
			std::cout<<"FIFO AMPLITUDE IS :"<<(FIFO[(std::stoi(chID))][2]>>6)<<", FIFO TIME IS :"<<(FIFO[(std::stoi(chID))][2] & 63)<<std::endl;
			token=s.substr(0,s.find(","));s=s.substr(s.find(",")+1);
			FIFO[(std::stoi(chID))][3]=(ap_uint<14>)(std::stoi(token));
			std::cout<<"FIFO AMPLITUDE IS :"<<(FIFO[(std::stoi(chID))][3]>>6)<<", FIFO TIME IS :"<<(FIFO[(std::stoi(chID))][3] & 63)<<std::endl;
			token=s.substr(0,s.find(","));s=s.substr(s.find(",")+1);
			FIFO[(std::stoi(chID))][4]=(ap_uint<14>)(std::stoi(token));
			std::cout<<"FIFO AMPLITUDE IS : "<<(FIFO[(std::stoi(chID))][4]>>6)<<", FIFO TIME IS :"<<(FIFO[(std::stoi(chID))][4] & 63)<<std::endl;
		}
		cnt:;
		hitproducer_hw(FIFO,outHit,Peds);
		std::cout<<"Now I'll Print the Firmware Hits: "<<std::endl;
		for(int i=0;i<NHITS;i++){
			if(outHit[i].bID>=0){
				std::cout<<outHit[i].bID<<","<<outHit[i].mID<<","<<outHit[i].Amp<<","<<outHit[i].Time<<std::endl;
			}
		}
		std::cout<<"Finally I'll Print the Simulation Hits: "<<std::endl;
		stop = 0;
		int curMod = -1;
		while((inFileHit)and(stop==0)){
			std::getline(inFileHit,s);
			if((s=="a")and(curMod==1)){
				stop=0;
				goto cnt2;
			}else if(s=="a"){
				continue;
			}
			std::string token1;
			token=s.substr(s.find(",")+1);
			curMod = std::stoi(token.substr(0,token.find(",")));
			token=token.substr(token.find(",")+1);
			token1=token.substr(0,token.find(","));
			token=token.substr(token.find(",")+1);
			if((not(std::stof(token)==0))and(curMod==1)){
				std::cout<<2*std::stof(token1)<<std::endl;
				std::cout<<s<<std::endl;
			}
		}
		cnt2:;
		H++;
	}
	std::cout<<"The number of mismatched events are: "<<counterDiff<<std::endl;
	std::cout<<"out of "<<H<<std::endl;
	inFileDigi.close();
	inFileHit.close();
	return 0;
}
