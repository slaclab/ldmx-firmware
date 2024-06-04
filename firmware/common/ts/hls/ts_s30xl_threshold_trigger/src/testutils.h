#ifndef TESTUTILS_H
#define TESTUTILS_H
#include "objdef.h"

bool compareHit(Hit Hit1, Hit Hit2){
	return ((Hit1.mID==Hit2.mID)and(Hit1.bID==Hit2.bID)and(Hit1.Amp==Hit2.Amp)and(Hit1.Time==Hit2.Time));//and(Hit1.TrigTime==Hit2.TrigTime));
}

bool compareClus(Cluster clus1[NHITS], Cluster clus2[NHITS]){
	for(int i = 0; i<NHITS; ++i){
		if(not((compareHit(clus1[i].Seed,clus2[i].Seed))and(compareHit(clus1[i].Sec,clus2[i].Sec)))){return false;}
	}
	return true;
}

int Q2ADC(ap_uint<14> Charge) {

  /// Indices of first bin of each subrange
  ap_uint<14> nbins_[5] = {0, 16, 36, 57, 64};

  /// Charge lower limit of all the 16 subranges
  ap_uint<14> edges_[17] = {0,   34,    158,    419,    517,   915,
	                      1910,  3990,  4780,   7960,   15900, 32600,
	                      38900, 64300, 128000, 261000, 350000};
  /// sensitivity of the subranges (Total charge/no. of bins)
  ap_uint<14> sense_[16] = {3,   6,   12,  25, 25, 50, 99, 198,
	                      198, 397, 794, 1587, 1587, 3174, 6349, 12700};
  //gain_
  //1.6*1.9*.1614
  ap_uint<14> qq = .70 * Charge;                 // including QIE gain
  //if (isnoise_) qq += trg_->Gaus(mu_, sg_);  // Adding gaussian random noise.

  if (qq <= edges_[0]) return 0;
  if (qq >= edges_[16]) return 255;

  int ID = 8;
  int a = 0;
  int b = 16;

  // Binary search to find the subrange
  while (b - a != 1) {
    if (qq > edges_[(a + b) / 2]) {
      a = (a + b) / 2;
    } else
      b = (a + b) / 2;
  }
  return 64 * (int)(a / 4) + nbins_[a % 4] +
         ((qq - edges_[a]) / sense_[a]);
}

#endif
