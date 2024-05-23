import pyrogue
import rogue
import hps

class TiDtmRoot(pyrogue.Root):
    def __init__(self):
        super().__init__()

        # Open mem map driver to local fpga registers
        memMap = rogue.hardware.rce.MapMemory()

        #Add the ControlDpm device
        self.add(hps.TiDtm(memBase=memMap))

        # Start
        self.start(pollEn=True, pyroGroup='HpsRogue')
