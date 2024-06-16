import sys
from LDMX.Framework import ldmxcfg
from LDMX.SimCore import generators
from LDMX.SimCore import simulator
thisPassName="sim"
p = ldmxcfg.Process(thisPassName)

from LDMX.Hcal import HcalGeometry
import LDMX.Ecal.EcalGeometry
from LDMX.TrigScint.trigScint import TrigScintDigiProducer
from LDMX.TrigScint.trigScint import TrigScintClusterProducer
from LDMX.TrigScint.trigScint import trigScintTrack


#clustering: seeding threshold
tagSeed = 30.
upSeed= 30.
downSeed = upSeed
#cluster width (upper limit on nHits/cluster)
tagWidth = 2      # can be up to 3 (default)
#cluster threshold: hits below this PE count are neglected
tagClThr = 30.  # default: 1. here use something >> typical electronics noise, which is 1 (sometimes 2) PE
#tracking: max distance between cluster candidate position and seed cluster position
maxDelta = 1.25
#1.25
clusteringVerbosity=3
trackingVerbosity=3



p.run = 10
p.maxEvents = 5
p.outputFiles = ['out6.root']

#gun = generators.gun('particle_gun')
#gun.particle = 'e-'
#gun.nParticles = 4
#gun.direction = [0., 0., 1.]
#gun.position = [ -27.926, 0., -700 ] #mm
#gun.energy = 4.   #gev
mpgGen = generators.multi( "mgpGen" ) # this is the line that actually creates the generator
mpgGen.vertex = [ -27.926, 0., -700 ] # mm
mpgGen.nParticles = 4
mpgGen.pdgID = 11
doPoisson=False
mpgGen.enablePoisson = doPoisson

import math
theta = math.radians(4.5)
mpgGen.momentum = [ 4000.*math.sin(theta) , 0, 4000.*math.cos(theta) ]
simulation = simulator.simulator('test_TS')
simulation.generators=[mpgGen]

simulation.setDetector('ldmx-det-v12')                                                           
simulation.beamSpotSmear = [20.0,80.0,0.0]#mm, at start position

#p.sequence=[simulation]

tsDigisUp=TrigScintDigiProducer("up")
tsDigisTag=TrigScintDigiProducer("tagger")
tsDigisDown=TrigScintDigiProducer("down")
tsDigisUp.pe_per_mip = 100.
tsDigisTag.pe_per_mip = tsDigisUp.pe_per_mip
tsDigisDown.pe_per_mip = tsDigisUp.pe_per_mip

tsDigisTag.input_collection='TriggerPadTagSimHits'
tsDigisUp.input_collection='TriggerPadUpSimHits'
tsDigisDown.input_collection='TriggerPadDnSimHits'

tsDigisTag.output_collection='TriggerPadTagDigiHits'
tsDigisUp.output_collection='TriggerPadUpDigiHits'
tsDigisDown.output_collection='TriggerPadDnDigiHits'


tsDigisUp.number_of_strips = 50
tsDigisDown.number_of_strips = 50
tsDigisTag.number_of_strips = 50

# add these to the sequence of processes the code should run
#p.sequence=[simulation, tsDigisUp, tsDigisTag, tsDigisDown ]

clTag=TrigScintClusterProducer("clTag")
clUp=TrigScintClusterProducer("clUp")
clDown=TrigScintClusterProducer("clDown")

clTag.input_collection='TriggerPadTagDigiHits'
clUp.input_collection='TriggerPadUpDigiHits'
clDown.input_collection='TriggerPadDnDigiHits'

clTag.output_collection='TriggerPad1Clusters'
clUp.output_collection='TriggerPad2Clusters'
clDown.output_collection='TriggerPad3Clusters'

clTag.verbosity = clusteringVerbosity
clUp.verbosity = clusteringVerbosity
clDown.verbosity = clusteringVerbosity

# here the seeds etc could also be set
clTag.max_cluster_width = tagWidth
clUp.max_cluster_width = tagWidth
clDown.max_cluster_width = tagWidth

clTag.clustering_threshold = tagClThr
clUp.clustering_threshold = tagClThr
clDown.clustering_threshold = tagClThr

clTag.seed_threshold = tagSeed
clUp.seed_threshold = upSeed
clDown.seed_threshold = downSeed

clTag.time_tolerance=40.5#.5
clUp.time_tolerance=40.5
clDown.time_tolerance=40.5

clUp.pad_time=-2.0
clDown.pad_time=.0

#trk=trigScintTrack("track")

trigScintTrack.verbosity = trackingVerbosity
trigScintTrack.delta_max = 1.0
trigScintTrack.seeding_collection = "TriggerPad1Clusters"
#trigScintTrack.input_collections = ["TriggerPadUpClusters","TriggerPadDnClusters"]
trigScintTrack.output_collection = "TriggerPadTracks"
trigScintTrack.passName = "sim"

p.sequence=[ simulation, tsDigisUp, tsDigisTag, tsDigisDown , clTag, clUp, clDown, trigScintTrack]
