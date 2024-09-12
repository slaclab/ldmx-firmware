#include <stdio.h>
#include <math.h>
#include <sstream>
#include "TFile.h"
#include "TTree.h"
#include "TTreeReader.h"
#include "TTreeReaderArray.h"
#include <fstream>
#include <iostream>
#include <iomanip>


int processing(){

bool doingTracks = false;

TFile *myFile=TFile::Open("out6.root");
myFile->ls();
TTreeReader myReader(myFile->GetListOfKeys()->At(0)->GetName(),myFile);
TTreeReaderArray<Int_t> HitBarID(myReader,"TriggerPadTagDigiHits_sim.barID_");
TTreeReaderArray<Int_t> ModuleID(myReader,"TriggerPadTagDigiHits_sim.moduleID_");
TTreeReaderArray<Float_t> Amplitude(myReader,"TriggerPadTagDigiHits_sim.amplitude_");
TTreeReaderArray<Float_t> Time(myReader,"TriggerPadTagDigiHits_sim.time_");

TTreeReaderArray<Int_t> P2HitBarID(myReader,"TriggerPadUpDigiHits_sim.barID_");
TTreeReaderArray<Int_t> P2ModuleID(myReader,"TriggerPadUpDigiHits_sim.moduleID_");
TTreeReaderArray<Float_t> P2Amplitude(myReader,"TriggerPadUpDigiHits_sim.amplitude_");
TTreeReaderArray<Float_t> P2Time(myReader,"TriggerPadUpDigiHits_sim.time_");

TTreeReaderArray<Int_t> P3HitBarID(myReader,"TriggerPadDnDigiHits_sim.barID_");
TTreeReaderArray<Int_t> P3ModuleID(myReader,"TriggerPadDnDigiHits_sim.moduleID_");
TTreeReaderArray<Float_t> P3Amplitude(myReader,"TriggerPadDnDigiHits_sim.amplitude_");
TTreeReaderArray<Float_t> P3Time(myReader,"TriggerPadDnDigiHits_sim.time_");

TTreeReaderArray<double> Seed(myReader,"TriggerPad1Clusters_sim.centroid_");

TTreeReaderArray<double> Pad2(myReader,"TriggerPad2Clusters_sim.centroid_");

TTreeReaderArray<double> Pad3(myReader,"TriggerPad3Clusters_sim.centroid_");


TTreeReaderArray<float> Tracks(myReader,"TriggerPadTracks_sim.centroid_");

ofstream output;ofstream output2;ofstream output3;
if(doingTracks){
    output.open("hitVec.dat");
    output2.open("trackVec.dat");
    output3.open("clusVec.dat");
}else{
    output.open("inputTestVec.dat");
    output2.open("outputTestVec.dat");
}
while(myReader.Next()){//and(myReader5.Next())){
    //WHEN doingTracks is not enables, "a" denotes a new event. Here 3 such a's do, with a single a denoting a different layer
    for(int i=0;i<HitBarID.GetSize();++i){
        output<<HitBarID[i];
        output<<",";
        output<<ModuleID[i];
        output<<",";
        output<<Amplitude[i];
        output<<",";
        output<<Time[i];
        output<<"\n";
    }
    output<<"a\n";
    if(doingTracks){
        for(int i=0;i<P2HitBarID.GetSize();++i){
            output<<P2HitBarID[i];
            output<<",";
            output<<P2ModuleID[i];
            output<<",";
            output<<P2Amplitude[i];
            output<<",";
            output<<P2Time[i];
            output<<"\n";
        }
        output<<"a\n";
        for(int i=0;i<P3HitBarID.GetSize();++i){
            output<<P3HitBarID[i];
            output<<",";
            output<<P3ModuleID[i];
            output<<",";
            output<<P3Amplitude[i];
            output<<",";
            output<<P3Time[i];
            output<<"\n";
        }
        output<<"a\n";

        for(int j=0;j<Seed.GetSize();++j){
            output3<<(int)(100*Seed[j]);
            output3<<"\n";
        }
        output3<<"a\n";

        for(int j=0;j<Pad2.GetSize();++j){
            output3<<(int)(100*Pad3[j]);
            output3<<"\n";
        }
        output3<<"a\n";
        
        for(int j=0;j<Pad3.GetSize();++j){
            output3<<(int)(100*Pad3[j]);
            output3<<"\n";
        }
        output3<<"a\n";

        for(int j=0;j<Tracks.GetSize();++j){
            output2<<(int)(100*Tracks[j]);
            output2<<"\n";
        }
        output2<<"a\n";
    }else{
        for(int j=0;j<Seed.GetSize();++j){
            output2<<(int)(100*Seed[j]);
            output2<<"\n";
        }
        output2<<"a\n";
    }
}
output.close();
output2.close();
return 0;
}
