import pyrogue as pr

class Ads1115(pr.Device):

    def __init__(self, **kwargs):
        super().__init__(description="ADS1115 ADC object.", **kwargs)

        self.add(pr.RemoteVariable(
            name="Conversion",
            description='Result of latests ADC conversion',
            offset=0x0,
            bitSize=16,
            bitOffset=0,
            mode='RO',
            base=pr.UInt,
            disp = '{:#x}'))

        # self.add(pr.RemoteVariable(
        #     name="CompQue",
        #     description='Configures the comparator queue.',
        #     offset=0x04,
        #     bitSize=2,
        #     bitOffset=0,
        #     base=pr.UInt,
        #     enum = {
        #         0:"One Conversion",
        #         1: "Two Conversions",
        #         2: "Three Conversions",
        #         3: "Disabled"}))

        # self.add(pr.RemoteVariable(
        #     name="CompLat",
        #     description='Sets the comparator latching.',
        #     offset=0x04,
        #     bitSize=1,
        #     bitOffset=2,
        #     base=pr.UInt,
        #     enum = {
        #         0:"Latching",
        #         1: "Non-Latching"}))

        # self.add(pr.RemoteVariable(
        #     name="CompPol",
        #     description='Sets the comparator polarity.',
        #     offset=0x04,
        #     bitSize=1,
        #     bitOffset=3,
        #     base=pr.UInt,
        #     enum = {
        #         0:"Active Low",
        #         1: "Active High"}))

        # self.add(pr.RemoteVariable(
        #     name="CompMode",
        #     description='Sets the comparator mode.',
        #     offset=0x04,
        #     bitSize=1,
        #     bitOffset=4,
        #     base=pr.UInt,
        #     enum = {
        #         0:"Traditional",
        #         1: "Window"}))

        self.add(pr.RemoteVariable(
            name="DataRate",
            description='Sets the sampling rate',
            offset=0x04,
            bitSize=3,
            bitOffset=5,
            base=pr.UInt,
            enum = {
                0:"8 SPS",
                1: "16 SPS",
                2: "32 SPS",
                3: "64 SPS",
                4: "128 SPS",
                5: "250 SPS",
                6: "475 SPS",
                7: "860 SPS"}))

        self.add(pr.RemoteVariable(
            name="Mode",
            description='Set power mode of device.',
            offset=0x4,
            bitSize=1,
            bitOffset=8,
            base=pr.UInt,
            enum = {
                0:"Continuous",
                1: "Single Shot"}))

        self.add(pr.RemoteVariable(
            name="Pga",
            description='Programmable Gain Amplifier. Determines full scale range of ADC.',
            offset=0x4,
            bitSize=3,
            bitOffset=9,
            base=pr.UInt,
            enum = {
                0: "6.144V",
                1: "4.096V",
                2: "2.048V",
                3: "1.024V",
                4: "0.512V",
                5: "0.256V",
                6: "0.256V",
                7: "0.256V"}))

        self.add(pr.RemoteVariable(
            name="Mux",
            description='Determines which inputs to convert.',
            offset=0x4,
            bitSize=3,
            bitOffset=12,
            base=pr.UInt,
            enum = {
                0:"P:AIN0 N:AIN1",
                1: "P:AIN0 N:AIN3",
                2: "P:AIN1 N:AIN3",
                3: "P:AIN2 N:AIN3",
                4: "P:AIN0 N:GND",
                5: "P:AIN1 N:GND",
                6: "P:AIN2 N:GND",
                7: "P:AIN3 N:GND"}))

        self.add(pr.RemoteVariable(
            name="Os",
            description='0 if device is performing a conversion. 1 if not.',
            offset=0x4,
            bitSize=1,
            bitOffset=15,
            base=pr.UInt,
            mode='RO',
            enum = {
                0:"Performing",
                1: "Not Performing"}))

        # self.add(pr.RemoteVariable(
        #     name="ThreshLow",
        #     description='Lower threshold value',
        #     offset=0x8,
        #     bitSize=16,
        #     bitOffset=0,
        #     base=pr.UInt,
        # ))

        # self.add(pr.RemoteVariable(
        #     name="ThreshHigh",
        #     description='Upper threshold value',
        #     offset=0xC,
        #     bitSize=16,
        #     bitOffset=0,
        #     base=pr.UInt,
        # ))

        def readChannel(chan):
            def reader(read=True):
                print(f'Reading channel {chan} - read={read}')

                if self.enable.value() is not True:
                    return 0

                self.Mode.set(1, write=read)
                self.Mux.set(chan+4, write=read)
                self.Os.set(1, write=read)
                while self.Os.get(read=read) == 0:
                    pass
                return self.Conversion.get(read=read)
            return reader

        def getVoltage(rawVar):
            def convAdc():
                if self.enable.value() is not True or rawVar.value() is None:
                    return 0.0

                pga = self.Pga.value()
                raw = rawVar.value()
                fsRanges = [6.144, 4.096, 2.048, 1.024, 0.512, 0.256, 0.256, 0.256]
                return (raw * (fsRanges[pga] / 32768))
            return convAdc


#         for i in range(4):
#             self.add(pr.LocalVariable(
#                 name=f'AIN_RAW[{i}]',
#                 mode='RO',
#                 localGet=readChannel(i),
#                 value=0,
#                 disp='{:#x}',
#             ))

#             self.add(pr.LinkVariable(
#                 name=f'AIN[{i}]',
#                 mode='RO',
#                 units='V',
#                 linkedGet=getVoltage(self.AIN_RAW[i]),
#                 dependencies=[self.AIN_RAW[i]]
#             ))



        for i in range(4):
            self.add(pr.RemoteVariable(
                name=f'AIN_RAW[{i}]',
                #hidden=True,
                offset=0x30 + (i*4),
                bitSize=16,
                bitOffset=0,
                mode='RO',
                disp='{:#x}',
                base=pr.UInt))


            self.add(pr.LinkVariable(
                name=f'AIN[{i}]',
                mode='RO',
                units='V',
                disp='{:1.3f}',
                linkedGet=getVoltage(self.AIN_RAW[i]),
                dependencies=[self.AIN_RAW[i]]))


#       for i in range(4):
#           self.add(pr.LinkVariable(
#               name=f'AIN[{i}]',
#               units='V',
#               mode='RO',
#               linkedGet=getVoltage(self.AIN_RAW[i]),
#               dependencies=[self.Pga, self.AIN_RAW[i]]))
