import pyrogue as pr

import rogue.interfaces.memory as rim


class Apv25(pr.Device):

    CSEL_ENUM = {
        0b11111111 : "Dly_0x3_125ns",
        0b11111110 : "Dly_1x3_125ns",
        0b11111101 : "Dly_2x3_125ns",
        0b11111011 : "Dly_3x3_125ns",
        0b11110111 : "Dly_4x3_125ns",
        0b11101111 : "Dly_5x3_125ns",
        0b11011111 : "Dly_6x3_125ns",
        0b10111111 : "Dly_7x3_125ns",
        0b01111111 : "Dly_8x3_125ns",
        0: '-'}


    CALGROUP_ENUM = {
        0b11111110 : '0' ,
        0b11111101 : '1' ,
        0b11111011 : '2' ,
        0b11110111 : '3' ,
        0b11101111 : '4' ,
        0b11011111 : '5' ,
        0b10111111 : '6' ,
        0b01111111 : '7' ,
        0: '-'}

    CALGROUP_REV_ENUM = {int(v):k for k,v in CALGROUP_ENUM.items() if k != 0}


    def __init__ (self, **kwargs):

        super().__init__(description="APV25 Object.", **kwargs)

        self.forceCheckEach = True

        #Define base register offsets
        ERROR   = 0b00000000
        MUXGAIN = 0b00000110
        LATENCY = 0b00000100
        MODE    = 0b00000010
        CSEL    = 0b00111010
        CDRV    = 0b00111000
        VPSP    = 0b00110110
        VFS     = 0b00110100
        VFP     = 0b00110010
        ICAL    = 0b00110000
        ISPARE  = 0b00101110
        IMUXIN  = 0b00101100
        IPSP    = 0b00101010
        ISSF    = 0b00101000
        ISHA    = 0b00100110
        IPSF    = 0b00100100
        IPCASC  = 0b00100010
        IPRE    = 0b00100000

        def addApvVariable(name, offset, **kwargs):
            self.add(pr.RemoteVariable(
                name=name,
                offset=offset*4,
                **kwargs))

        self.add(pr.RemoteVariable(
            name="LatencyErr",
            description='Latency error status',
            offset=ERROR,
            bitSize=1,
            bitOffset=0,
            mode ='RO',
            pollInterval=10,
            base=pr.UInt,
            enum = {
                0:"OK",
                1: "Error"}))

        self.add(pr.RemoteVariable(
            name="FIFOError",
            description='Fifo error status',
            offset=ERROR,
            bitSize=1,
            bitOffset=1,
            mode ='RO',
            pollInterval=10,
            base=pr.UInt,
            enum = {
                0: "OK",
                1: "Overflow"}))

        self.add(pr.RemoteCommand(
            name="SetAnalogBias",
            offset=MODE*4,
            bitSize=1,
            bitOffset=0,
            hidden = True,
            base=pr.UInt,
            function = pr.RemoteCommand.setArg))

        @self.command()
        def readAnalogBias():
            x = self.SetAnalogBias.get()
            print(f'AnalogBias = {x}')

        addApvVariable(
            name="TriggerMode",
            description='Set number of samples in trigger',
            offset=MODE,
            bitSize=1,
            bitOffset=1,
            base=pr.UInt,
            enum = {
                0: "3-Sample",
                1: "1-Sample"})

        addApvVariable(
            name="CalibrationInhibit",
            description='Set calibration inhibit',
            offset=MODE,
            bitSize=1,
            bitOffset=2,
            base=pr.Bool)

        addApvVariable(
            name="ReadOutMode",
            description='Set readout mode',
            offset=MODE,
            bitSize=1,
            bitOffset=3,
            base=pr.UInt,
            enum = {
                0: "Deconvolution",
                1: "Peak"})

        addApvVariable(
            name="ReadOutFrequency",
            description='Set readout frequency to enable muxing',
            offset=MODE,
            bitSize=1,
            bitOffset=4,
            base=pr.UInt,
            enum = {
                0: "20 MHz",
                1: "40 MHz"})

        addApvVariable(
            name="PreAmpPol",
            description='Set pre-amp input polarity',
            offset=MODE,
            bitSize=1,
            bitOffset=5,
            base=pr.UInt,
            enum = {
                0: "Non-Inverting",
                1: "Inverting"})


        addApvVariable(
            name="LatencyRaw",
            description='Determine the distance between read and write pointers.\n "8-bit value. 0 - 255"',
            offset=LATENCY,
            bitSize=8,
            bitOffset=0,
            base=pr.UInt,
            minimum = 0,
            maximum = 191)

        self.add(pr.LinkVariable(
            name='Latency',
            variable=self.LatencyRaw,
            minimum=None,
            maximum=None,
            mode='RO',
            disp='{:d}',
            linkedGet=lambda: self.LatencyRaw.value() * 25,
            units='nS'))

        addApvVariable(
            name="MuxGain",
            description='Determine output mux stage gain',
            offset=MUXGAIN,
            bitSize=8,
            bitOffset=0,
            base=pr.UInt,
            enum = {
                0b00001 : "Mip_0_8mA",
                0b00010 : "Mip_0_9mA",
                0b00100 : "Mip_1_0mA",
                0b01000 : "Mip_1_1mA",
                0b10000 : "Mip_1_2mA"})

        addApvVariable(
            name="Csel",
            description='Number of delays (3.125ns) to insert from edge of calibration generator',
            offset=CSEL,
            bitSize=8,
            bitOffset=0,
            base=pr.UInt,
            enum = Apv25.CSEL_ENUM)

        addApvVariable(
            name="CalGroup",
            description='Select which set of 16 channels to calibrate.\n Valid range is 0 to 7.',
            units='',
            offset=CDRV,
            bitSize=8,
            bitOffset=0,
            base=pr.UInt,
            enum = Apv25.CALGROUP_ENUM)

        addApvVariable(
            name="Vpsp",
            description='APSP voltage level adjust.\n 8-bit value. 0 - 255',
            #             units='V',
            #             mult=-0.0075,
            #             add=1.25,
            offset=VPSP,
            bitSize=8,
            bitOffset=0,
            base=pr.UInt,
            minimum=0,
            maximum=255)

        addApvVariable(
            name="Vfs",
            description='Shaper feedback voltage bias.\n 8-bit value. 0 - 255',
            #             units='V',
            #             mult=0.0075,
            #             add=-1.25,
            offset=VFS,
            bitSize=8,
            bitOffset=0,
            base=pr.UInt,
            minimum=0,
            maximum=255)

        addApvVariable(
            name="Vfp",
            description='Preamp feedback voltage bias.\n 8-bit value. 0 - 255',
            #             units='V',
            #             mult=0.0075,
            #             add=-1.25,
            offset=VFP,
            bitSize=8,
            bitOffset=0,
            base=pr.UInt,
            minimum=0,
            maximum=255)

        addApvVariable(
            name="Ical",
            description='Calibrate edge generator current bias\n 8-bit value. 0 - 255',
            #             units='el',
            #             mult=625,
            offset=ICAL,
            bitSize=8,
            bitOffset=0,
            base=pr.UInt,
            minimum=0,
            maximum=255)

        addApvVariable(
            name="Ispare",
            description='Spare',
            offset=ISPARE,
            bitSize=1,
            bitOffset=0,
            base=pr.Bool)

        addApvVariable(
            name="ImuxIn",
            description='Multiplexer input current bias.\n 8-bit value. 0 - 255',
            units='uA',
            offset=IMUXIN,
            bitSize=8,
            bitOffset=0,
            base=pr.UInt,
            minimum=0,
            maximum=255)

        addApvVariable(
            name="Ipsp",
            description='APSP current bias.\n 8-bit value. 0 - 255',
            units='uA',
            offset=IPSP,
            bitSize=8,
            bitOffset=0,
            base=pr.UInt,
            minimum=0,
            maximum=255)

        addApvVariable(
            name="Issf",
            description='Shaper source follower current bias.\n 8-bit value. 0 - 255',
            units='uA',
            offset=ISSF,
            bitSize=8,
            bitOffset=0,
            base=pr.UInt,
            minimum=0,
            maximum=255)

        addApvVariable(
            name="Isha",
            description='Shaper input FET current bias.\n 8-bit value. 0 - 255',
            units='uA',
            offset=ISHA,
            bitSize=8,
            bitOffset=0,
            base=pr.UInt,
            minimum=0,
            maximum=255)

        addApvVariable(
            name="Ipsf",
            description='Shaper source follower current bias.\n 8-bit value. 0 - 255',
            units='uA',
            offset=IPSF,
            bitSize=8,
            bitOffset=0,
            base=pr.UInt,
            minimum=0,
            maximum=255)

        addApvVariable(
            name="Ipcasc",
            description='Preamp cascode current bias.\n 8-bit value. 0 - 255',
            units='uA',
            offset=IPCASC,
            bitSize=8,
            bitOffset=0,
            base=pr.UInt,
            minimum=0,
            maximum=255)

        addApvVariable(
            name="Ipre",
            description='Preamp input FET current bias.\n 8-bit value. 0 - 255',
            #             units='uA',
            #             mult=4,
            offset=IPRE,
            bitSize=8,
            bitOffset=0,
            base=pr.UInt,
            minimum=0,
            maximum=255)

        self.biasVariables = set((self.Vpsp, self.Vfs, self.Vfp, self.Ical, self.Ispare, self.ImuxIn,
                                  self.Ipsp, self.Issf, self.Isha, self.Ipsf, self.Ipcasc, self.Ipre))

    def writeBlocks(self, **kwargs):
        #print(f'{self.path}.writeBlocks()')
        self.SetAnalogBias(0)
        super().writeBlocks(**kwargs)
        self.SetAnalogBias(1)


    def _doTransaction(self, transaction):
        with transaction.lock():

            # get the address
            locAddr = transaction.address() | self.offset
            type = transaction.type()

            data = bytearray(transaction.size())
            transaction.getData(data, 0)

            # If address is a read or verify, add 4 because APV25 is weird and reads have different addresses
            if type == rim.Read or type == rim.Verify:
                locAddr = locAddr + 4

            # Create transaction
            id = self._reqTransaction(locAddr, data, transaction.size(), 0, type)

            # Wait for it to complete
            self._waitTransaction(id)


            # Check for errors
            if self._getError() != "":
                transaction.error(self._getError())
                return False

            # Assign data back to original txn
            transaction.setData(data, 0)
            transaction.done()
