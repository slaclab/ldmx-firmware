import numpy as np

#This is an array of alignments. It was written in in units of bars, as [m1lay1,m1lay2,m2lay1,m2lay2,m3lay1,m3lay2].
alignment=[0.0,0.0,0.0,0.0,0.0,0.0]
#NUMBER OF BARS IN A LAYER
NUMBAR=25

#We have 6 layers from our three modules to recursively propogate a fake track to to create our list of tracks
#We want to genrate 6 tupples of barIDs. We will run through each layer, updating the average barID as we add new
#bar IDs from a layer.
#In the first step we choose a barID and set the tupple mean to its position. Then we check among the next layer whether the
#shifted bar id of some bar has a positional a center which is at most one bar id away. If it does, we pair those two bars and update
#the tupple mean. This could create at most two children tupples from a single starting tupple, meaning we have at most (NUMBAR)*(2^5)
#tracks in our look-up table for FirmWare.

#This method creates possibly two tracks for each starting track, unless you currently skirt an edge where it produces zero.
def update(v,i):
    newv=[]
    for vv in v:
        choice1=[vvv for vvv in vv[0]]
        choice1.append(np.floor(vv[1]+alignment[i+1]-alignment[i])+.5)
        movAv1=[choice1,(float(len(vv[0]))*vv[1]+np.floor(vv[1])+.5)/(float(len(vv[0]))+1.0)]
        if((movAv1[0][len(movAv1[0])-1]>0.0)and(movAv1[0][len(movAv1[0])-1]<NUMBAR)):
            newv.extend([movAv1])
           
        choice2=[vvv for vvv in vv[0]]
        choice2.append(np.ceil(vv[1]+alignment[i+1]-alignment[i])+.5)
        movAv2=[choice2,(float(len(vv[0]))*vv[1]+np.ceil(vv[1])+.5)/(float(len(vv[0]))+1.0)]
        if((movAv2[0][len(movAv2[0])-1]>0.0)and(movAv2[0][len(movAv2[0])-1]<NUMBAR)):
            newv.extend([movAv2])
    return newv

#Translates the bar positions to barID's
def translate(v):
    newv=[]
    for i in range(6):
        mod=i//2
        layer=i%2
        newv.append(2.0*np.floor(v[0][i])+1.0*(i%2==1))
    return newv

lookUpTable=[]
#Populating the first layer hits
for i in range(25):
    lookUpTable.append([[float(i)+.5],float(i)+.5])
#Populating the rest of the layers
for i in range(5):
    lookUpTable=update(lookUpTable,i)
   
#Translating the barID positions to actual barID's
lookUpTable=[translate(v) for v in lookUpTable]
lookUpTable=[[min(v[0],v[1]),min(v[2],v[3]),min(v[4],v[5])] for v in lookUpTable]

def ISIN(helper,v):
    SUM=0
    for vv in helper:
        SUM+=min([1.0*(vv[i]==v[i]) for i in range(3)])
    return (SUM>0)
#Now I remove duplicate entries
helper=[]
for v in lookUpTable:
    if(not(ISIN(helper,v))):
        helper.append(v)
lookUpTable=helper

f=open("lookUp.txt","w")
for i in range(len(lookUpTable)):
    word=""
    for j in range(3):
        if(j<len(lookUpTable[i])-1):
            word+=str(int(lookUpTable[i][j]))+","
        else:
            word+=str(int(lookUpTable[i][j]))
    f.write(word)
    f.write("\n")
f.close()
#print(len(lookUpTable)*(2**-5))

#YOU MAY NEED TO MANUALLY REMOVE AN EMPTY SPACE LINE AT THE END