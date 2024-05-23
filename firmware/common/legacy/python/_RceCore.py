import pyrogue as pr
import hps


class RceCore(pr.Device):
    def __init__ (self,hybridNum=1, **kwargs):
        super().__init__(description="RCE Core Object.", **kwargs)

        self.add(pr.RemoteVariable(
            name="RceAddress",
            offset=0x00,
            bitSize=8,
            bitOffset=0,
            base=pr.UInt))

        #self.add(pr.RemoteVariable(name="PipelineReset", offset=0x04, bitSize=8, bitOffset=0, base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="ThresholdCutEn",
            offset=0x08,
            bitSize=1,
            bitOffset=0,
            base=pr.Bool))

        self.add(pr.RemoteVariable(
            name="SlopeCutEn",
            offset=0x08,
            bitSize=1,
            bitOffset=1,
            base=pr.Bool))

        self.add(pr.RemoteVariable(
            name="CalibrationEn",
            offset=0x08,
            bitSize=1,
            bitOffset=2,
            base=pr.Bool))

        self.add(pr.RemoteVariable(
            name="CalibrationGroup",
            offset=0x08,
            bitSize=3,
            bitOffset=3,
            base=pr.UInt,
            minimum=0,
            maximum = 7))

        self.add(pr.RemoteVariable(
            name="ThresholdCutNum",
            offset=0x08,
            bitSize=3,
            bitOffset=6,
            base=pr.UInt,
            minimum=0,
            maximum = 7))

        self.add(pr.RemoteVariable(
            name="ThresholdMarkOnly",
            offset=0x08,
            bitSize=1,
            bitOffset=9,
            base=pr.Bool))

        self.add(pr.RemoteVariable(
            name="ErrorFilterEn",
            offset=0x08,
            bitSize=1,
            bitOffset=10,
            base=pr.Bool))

        self.add(pr.RemoteCommand(
            name = "DataPipelineReset",
            offset = 0x0C,
            bitSize = 1,
            bitOffset = 0,
            base = pr.UInt,
            function = pr.RemoteCommand.toggle))

        self.addNodes(
            nodeClass=hps.DataPath,
            number=hybridNum,
            stride=0x10000,
            offset = 0x10000,
            name='DataPath')

        self.add(hps.EventBuilder(
            name='EventBuilder',
            offset = 0x100))

        #self.add(pr.Command(name='ResetPipelines', description='Reset all state machines and pipelines in the data processing logic',
        #                     fucntion=reset))
