import pyrogue
import pyrogue.utilities.fileio
import pyrogue.gui
import rogue
import hps
import axipcie
import PyQt4.QtGui
import PyQt4.QtCore
import sys
#import logging

class KcuTrigger(pyrogue.Device):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        DAQ_CLK_ALIGN_CODE = 0xA5
        DAQ_TRIGGER_CODE = 0x5A
        DAQ_APV_RESET101 = 0x1F

        self.add(pyrogue.RemoteVariable(
            name='OpCode',
            offset=0x0,
            bitOffset=0,
            bitSize=8,
            hidden=True,
            value=0x5A))

        self.add(pyrogue.RemoteVariable(
            name='TriggerEn',
            offset=0x4,
            bitOffset=0,
            bitSize=1,
            value = True,
            hidden=False,
            base=pyrogue.Bool))

        self.add(pyrogue.RemoteCommand(
            name='Send',
            offset=0x8,
            bitOffset=0,
            bitSize=1,
            hidden=True,
            function=pyrogue.BaseCommand.touchOne))

        @self.command()
        def SendCode(arg):
            self.OpCode.set(arg)
            self.Send()

        @self.command()
        def Trigger():
            SendCode(DAQ_TRIGGER_CODE)

        @self.command()
        def Reset101():
            SendCode(DAQ_APV_RESET101)

        @self.command()
        def Align():
            SendCode(DAQ_APV_RESET101)


class Kcu1500App(pyrogue.Device):
    def __init__(self, **kwargs):
        super().__init__(description='', **kwargs)

        self.add(hps.KcuTrigger(offset=0x0))
        self.add(hps.RceCore(offset=0x10_0000, expand=False))
        self.add(hps.Kcu1500PgpQuad(name='FebCtrlPgpLink', numLinks=1, offset=0x10000, expand=False))
        self.add(hps.Kcu1500PgpQuad(name='FebDataPgpLink', numLinks=4, offset=0x20000, expand=False))

class Kcu1500Root(pyrogue.Root):
    def __init__(self, bootloader=False, pollEn=False, device='/dev/datadev_0', **kwargs):
        super().__init__(name='Kcu1500Root', description='', **kwargs)

        # Feb Stream
        regBase = rogue.hardware.axi.AxiMemMap(device)

        febRegStream    = rogue.hardware.axi.AxiStreamDma(device, 0, True) # SRP stream to FEB
        #febSemStream    = rogue.hardware.data.DataCard('/dev/datadev_0', 1); # SEM stream to FEB
        febSrp = rogue.protocols.srp.SrpV3()
        pyrogue.streamConnectBiDir(febRegStream, febSrp)

        self.add(axipcie.AxiPcieCore(
            useSpi=True,
            memBase=regBase,
            offset=0x0))

        #Kcu1500 App has RCE core
        self.add(hps.Kcu1500App(
            memBase=regBase,
            expand=True,
            offset=0x80_0000))

        # Feb is on DMA/PGP/SRP link
        if bootloader:
            self.add(hps.FebBootloaderFpga(
                name='Feb',
                memBase=febSrp,
                enabled=True,
            ))
        else:
            self.add(hps.FebFpga(
                name='Feb',
                memBase=febSrp,
                enabled=True,
                enableDeps=[self.Kcu1500App.FebCtrlPgpLink.Kcu1500PgpLane[0].Pgp2bAxi.RxRemLinkReady]
            ))

#        self.Kcu1500App.FebCtrlPgpLink.AppPgp2bLane[0].Pgp2bAxi.RxRemLinkReady.addListener(
#            lambda var, value, disp: self.Feb.enable.set(value)
#        )

        #self.add(pyrogue.RunControl(name='HpsRunControl', cmd=self.Kcu1500App.KcuTrigger.Trigger))
        # Data capture stream
        #dataDma = rogue.hardware.data.DataCard(device, 0x10);
        #self.add(pyrogue.utilities.fileio.StreamWriter(name='DataWriter'))
        #pyrogue.streamConnect(dataDma, self.DataWriter.getChannel(0))
        self.setTimeout(5)

        self.start(pollEn=pollEn)

if __name__ == "__main__":

    #rogue.Logging.setFilter('rogue.hardware.data.DataMap', rogue.Logging.Debug)
    rogue.Logging.setFilter('pyrogue.SrpV3', rogue.Logging.Debug)
    #rogue.Logging.setFilter('pyrogue.DataMap', rogue.Logging.Debug)
    #logging.getLogger('pyrogue.Device').setLevel(logging.DEBUG)

    with Kcu1500Root(bootloader=False, pollEn=False) as root:

        root.ForceWrite.set(True)

        appTop = PyQt4.QtGui.QApplication(sys.argv)
        guiTop = pyrogue.gui.GuiTop(group='CoulterGui')
        print('guiTop.addTree')
        guiTop.addTree(root)
        guiTop.resize(1000,1000)
        # Run gui
        print('appTop.exec_()')
        appTop.exec_()
