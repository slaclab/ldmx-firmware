class AttrDict(dict):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.__dict__ = self

RCE_MEM_MAP_PORT = 9000
FEB_SRP_PORTS = [9100+i*2 for i in range(12)]
FEB_SEM_PORTS = [9200+i*2 for i in range(12)]
FEB_LOOPBACK_PORTS = [9400+i*2 for i in range(12)]
DATA_PORT = 8192

SLAC_DEVCRATE_SMALL_HOST_CONFIG = AttrDict({
    'controlDpmHost' : ['hps-dpm9'],
    'dataDpmHosts' : ['hps-dpm8', 'hps-dpm15', 'hps-dpm14'],
    'dtmHosts' : ['hps-dtm2'],
    'controlDpmMemPort' : RCE_MEM_MAP_PORT,
    'controlDpmFebSrpPorts' : FEB_SRP_PORTS,
    'controlDpmFebSemPorts' : FEB_SEM_PORTS,
    'controlDpmFebLoopbackPorts' : FEB_LOOPBACK_PORTS,
    'febLinkMap' : [(0,4)],# for x in range(4)], #[(0,3)],
    'dataDpmMemPort' : RCE_MEM_MAP_PORT,
    'dataDpmDmaPort' : DATA_PORT,
    'dtmMemPort' : RCE_MEM_MAP_PORT})

SLAC_DEVCRATE_2021_TOPCOB_HOST_CONFIG = AttrDict({
    'controlDpmHost' : ['hps-dpm7'],
    'dataDpmHosts' : ['hps-dpm0',
                      'hps-dpm1',
                      'hps-dpm2',
                      'hps-dpm3',
                      'hps-dpm4',
                      'hps-dpm5',
                      'hps-dpm6'],
    'dtmHosts' : ['hps-dtm1'],
    'controlDpmMemPort' : RCE_MEM_MAP_PORT,
    'controlDpmFebSrpPorts' : FEB_SRP_PORTS,
    'controlDpmFebSemPorts' : FEB_SEM_PORTS,
    'controlDpmFebLoopbackPorts' : FEB_LOOPBACK_PORTS,
    'febLinkMap' : [(0,1)],
    'dataDpmMemPort' : RCE_MEM_MAP_PORT,
    'dataDpmDmaPort' : DATA_PORT,
    'dtmMemPort' : RCE_MEM_MAP_PORT})


SLAC_DEVCRATE_2021_BOTCOB_HOST_CONFIG = AttrDict({
    'controlDpmHost' : ['hps-dpm15'],
    'dataDpmHosts' : ['hps-dpm8',
                      'hps-dpm9',
                      'hps-dpm10',
                      'hps-dpm11',
                      'hps-dpm12',
                      'hps-dpm13',
                      'hps-dpm14'],
    'dtmHosts' : ['hps-dtm2'],
    'controlDpmMemPort' : RCE_MEM_MAP_PORT,
    'controlDpmFebSrpPorts' : FEB_SRP_PORTS,
    'controlDpmFebSemPorts' : FEB_SEM_PORTS,
    'controlDpmFebLoopbackPorts' : FEB_LOOPBACK_PORTS,
    'febLinkMap' : [(0,3)],
    'dataDpmMemPort' : RCE_MEM_MAP_PORT,
    'dataDpmDmaPort' : DATA_PORT,
    'dtmMemPort' : RCE_MEM_MAP_PORT})



SLAC_DEVCRATE_2021_HOST_CONFIG = AttrDict({
    'controlDpmHost' : ['hps-dpm7','hps-dpm15'],
    'dataDpmHosts' : ['hps-dpm0',
                      'hps-dpm1',
                      'hps-dpm2',
                      'hps-dpm3',
                      'hps-dpm4',
                      'hps-dpm5',
                      'hps-dpm6',
                      'hps-dpm8',
                      'hps-dpm9',
                      'hps-dpm10',
                      'hps-dpm11',
                      'hps-dpm12',
                      'hps-dpm13',
                      'hps-dpm14'],
    'dtmHosts' : ['hps-dtm1','hps-dtm2'],
    'controlDpmMemPort' : RCE_MEM_MAP_PORT,
    'controlDpmFebSrpPorts' : FEB_SRP_PORTS,
    'controlDpmFebSemPorts' : FEB_SEM_PORTS,
    'controlDpmFebLoopbackPorts' : FEB_LOOPBACK_PORTS,
    'febLinkMap' : [(0,3),(1,3)],
    'dataDpmMemPort' : RCE_MEM_MAP_PORT,
    'dataDpmDmaPort' : DATA_PORT,
    'dtmMemPort' : RCE_MEM_MAP_PORT})



JLAB_PRODCRATE_HOST_CONFIG = AttrDict({
    'controlDpmHost' : ['dpm7', 'dpm15'],
    'dataDpmHosts' : ['dpm0',
                      'dpm1',
                      'dpm2',
                      'dpm3',
                      'dpm4',
                      'dpm5',
                      'dpm6',
                      'dpm8',
                      'dpm9',
                      'dpm10',
                      'dpm11',
                      'dpm12',
                      'dpm13',
                      'dpm14',],
    'dtmHosts' : ['dtm0', 'dtm1'],
    'controlDpmMemPort' : RCE_MEM_MAP_PORT,
    'controlDpmFebSrpPorts' : FEB_SRP_PORTS,
    'controlDpmFebSemPorts' : FEB_SEM_PORTS,
    'controlDpmFebLoopbackPorts' : FEB_LOOPBACK_PORTS,
    #'febLinkMap' : [(0,3), (0,5), (0,8), (0,7), (1,8), (0,4), (1,5), (1,7), (1,4), (1,6)],
    'febLinkMap' : [(0,3), (0,5), (0,8), (0,7), (1,8), (1,3), (1,5), (1,7), (1,4), (1,6)],
    'dataDpmMemPort' : RCE_MEM_MAP_PORT,
    'dataDpmDmaPort' : DATA_PORT,
    'dtmMemPort' : RCE_MEM_MAP_PORT})


SIM_HOST_CONFIG = AttrDict({
    'controlDpmHost' : ['localhost'],
    'dataDpmHosts' : ['localhost'],
    'dtmHosts' : ['localhost'],
    'controlDpmMemPort' : 20000,
    'controlDpmFebSrpPorts' : [21000],
    'controlDpmFebSemPorts' : FEB_SEM_PORTS,
    'controlDpmFebLoopbackPorts' : [21006],
    'febLinkMap': [(0,0)],
    'dataDpmMemPort' :  30000,
    'dataDpmDmaPort' : 36000,
    'dtmMemPort' : 10000})
