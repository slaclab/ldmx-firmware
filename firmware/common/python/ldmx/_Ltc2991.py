import pyrogue as pr

#Still need to implement convAdc

class Ltc2991(pr.Device):
    def __init__ (self,configDict={}, description="LTC2991 Voltage Monitor", **kwargs):
        super().__init__(description=description, **kwargs)
#        configDict_=configDict


        self.add(pr.RemoteVariable(
            name="Ready",
            description='Registers contain new data.',
            offset=0x00,
            bitSize=8,
            bitOffset=8,
            mode = 'RO',
            disp = '0b{:08b}',
            base=pr.UInt))



        for i in range(4):
            self.add(pr.RemoteVariable(
                name="V{x}V{y}Enable".format(x=i*2+1,y=i*2+2),
                offset=0x00,
                bitSize=1,
                bitOffset=4+i,
                description='Enable analog inputs',
                base=pr.Bool))


        diffOffsets = {0:8, 1:12, 2:0, 3:4}
        for i in range(4):
            self.add(pr.RemoteVariable(
                name=f'V{i*2+1}V{i*2+2}Diff',
                offset=0x18,
                bitSize=1,
                bitOffset=diffOffsets[i],
                description='Set differential or signle ended',
                base=pr.UInt,
                enum={0:'Single-Ended',
                      1:'Differential'}))


#           self.add(pr.RemoteVariable(
#                 name="V{x}V{y}Temp".format(x=i*2+1,y=i*2+2),
#                 offset=0x18,
#                 bitSize=1,
#                 bitOffset=9+(4*i),
#                 description='Set inputs to read a Voltage or Temperature',
#                 base=pr.UInt,
#                 enum={0:'Voltage',
#                      1:'Temperature'},
#                 ))

#             self.add(pr.RemoteVariable(
#                 name="V{x}V{y}Temp".format(x=i*2+5,y=i*2+6),
#                 offset=0x18,
#                 bitSize=1,
#                 bitOffset=1+(4*i),
#                 description='Set inputs to read a Voltage or Temperature',
#                 base=pr.UInt,
#                 hidden="V{x}V{y}Temp".format(x=i*2+5,y=i*2+6) in configDict_,
#                 enum={0:'Voltage',
#                     1:'Temperature'},
#                 value=configDict_.get("V{x}V{y}Temp".format(x=i*2+5,y=i*2+6),0)))

#          self.add(pr.RemoteVariable(
#                 name="V{x}V{y}Kelvin".format(x=i*2+1,y=i*2+2),
#                 offset=0x18,
#                 bitSize=1,
#                 bitOffset=10+(4*i),
#                 description='Set temperature readout to Celsius or Kelvin',
#                 base=pr.UInt,
#                 hidden="V{x}V{y}Kelvin".format(x=i*2+1,y=i*2+2) in configDict_,
#                 enum={0:'Celcius',
#                     1:'Kelvin'},
#                 value=configDict_.get("V{x}V{y}Kelvin".format(x=i*2+1,y=i*2+2),0)))

#             self.add(pr.RemoteVariable(
#                 name="V{x}V{y}Kelvin".format(x=i*2+5,y=i*2+6),
#                 offset=0x18,
#                 bitSize=1,
#                 bitOffset=2+(4*i),
#                 description='Set temperature readout to Celsius or Kelvin',
#                 base=pr.UInt,
#                 hidden="V{x}V{y}Kelvin".format(x=i*2+5,y=i*2+6) in configDict_,
#                 enum={0:'Celcius',
#                     1:'Kelvin'},
#                 value=configDict_.get("V{x}V{y}Kelvin".format(x=i*2+5,y=i*2+6),0)))

#             self.add(pr.RemoteVariable(
#                 name="V{x}V{y}FilterEn".format(x=i*2+1,y=i*2+2),
#                 offset=0x18,
#                 bitSize=1,
#                 bitOffset=11+(4*i),
#                 description='Enable input filter',
#                 base=pr.Bool))

#             self.add(pr.RemoteVariable(
#                 name="V{x}V{y}FilterEn".format(x=i*2+3,y=i*2+4),
#                 offset=0x18,
#                 bitSize=1,
#                 bitOffset=3+(4*i),
#                 description='Enable input filter',
#                 base=pr.Bool))


        self.add(pr.RemoteVariable(
            name="TInternalVccEnable",
            offset=0x00,
            bitSize=1,
            bitOffset=3,
            description = 'Enable Temperature and VCC inputs',
            base=pr.Bool))

        self.add(pr.RemoteVariable(
            name="TInternalKelvin",
            offset=0x20,
            bitSize=1,
            bitOffset=10,
            description='Set temperature readout to Celsius or Kelvin',
            base=pr.UInt,
            enum={0:'Celcius',
                  1:'Kelvin'}))

        self.add(pr.RemoteVariable(
            name="TInternalFilterEn",
            offset=0x20,
            bitSize=1,
            bitOffset=11,
            description='Enable input filter',
            base=pr.Bool))

        self.add(pr.RemoteVariable(
            name="AcquisitionMode",
            offset=0x20,
            bitSize=1,
            bitOffset=12,
            description='Repeated Acquisition',
            base=pr.UInt,
            enum={
                0:'Single Shot',
                1:'Repeated'}))

#        self.add(pr.RemoteVariable(
#             name="PwmEnable",
#             offset=0x20,
#             bitSize=1,
#             bitOffset=13,
#             description='Enable PWM',
#             base=pr.Bool))

#         self.add(pr.RemoteVariable(
#             name="PwmInvert",
#             offset=0x20,
#             bitSize=1,
#             bitOffset=14,
#             description='Invert PWM',
#             base=pr.Bool))




#         def convSingle(adc):
#             def convert():
#                 value=adc.value()
#                 return 305.18e-6 * (value & 0x3FFF)+2.5
#             return convert

#         def convDiff(adc):
#             def convert():
#                 adcSigned = adc.value()
#                 return adcSigned * 19.075e-6
#             return convert


        def signed(value, bits):
            if (value & (1 << (bits - 1))) != 0:
                return -1*(~value & ((1<<bits)-1) + 1)
            return value

        def makeConverter(number, adc, diff, offset=0.0):
            def convert():
                if diff is not None and diff.valueDisp() == 'Differential' and number%2==0:
                    value = adc.value() & 0x7fff
                    value = signed(value, 14) * 19.075e-6
                else:
                    value = adc.value() & 0x3fff
                    value = 305.18e-6 * value + offset
                return value
            return convert

        for i in range(1,9):
            adc = pr.RemoteVariable(
                name=f"V{i}Raw",
                hidden=False,
                offset=0x20+(8*i),
                bitSize=16,
                bitOffset=0,
                description='Raw Input',
                mode='RO',
                base=pr.UInt)

            self.add(adc)

            diff = self.find(name=f'.*?V{i}.*?Diff')
            if diff is not None:
                diff = diff[0]

            self.add(pr.LinkVariable(
                name=f'V{i}',
                mode='RO',
                hidden=False,
                disp='{:1.3f}',
                dependencies=[adc, diff],
                linkedGet=makeConverter(number=i, adc=adc, diff=diff)))


        def convTemp(adc,kelvin):
            def convert():
                value = adc.value()
                value = value & 0xFFF
                value = signed(value, 12) * 0.0625
                if kelvin.valueDisp() == 'Kelvin':
                    value += 273.0
                return value
            return convert


        self.add(pr.RemoteVariable(
            name="TInternalRaw",
            hidden=False,
            offset=0x68,
            bitSize=16,
            bitOffset=0,
            description='Internal Temperature',
            mode='RO',
            base=pr.UInt))

        self.add(pr.LinkVariable(
            name="TInternal",
            description='Internal Temperature',
            mode='RO',
            disp='{:1.3f}',
            linkedGet=convTemp(self.TInternalRaw, self.TInternalKelvin),
            dependencies=[self.TInternalRaw, self.TInternalKelvin]))

        self.add(pr.RemoteVariable(
            name="VccRaw",
            hidden=True,
            offset=0x70,
            bitSize=16,
            bitOffset=0,
            description='Raw Input',
            mode='RO',
            base=pr.UInt))

        self.add(pr.LinkVariable(
            name="Vcc",
            description='Converted input in Volts',
            mode='RO',
            units='V',
            disp='{:1.3f}',
            linkedGet=makeConverter(0, self.VccRaw, None, 2.5),
            dependencies=[self.VccRaw]))


#     def cfgChannel(channel = 0, string = ''):
#         if channel != 0:
#             if channel%2==0:
#                 return str(channel)+'V'+str(channel+1)+'V'
#             return str(channel-1)+'V'+str(channel)+'V'

#         if channel in 'V1V2':
#             return 'V1V2'
#         elif channel in 'V3V4':
#             return 'V3V4'
#         elif channel in 'V5V6':
#             return 'V5V6'
#         return 'V7V8'

#     def getChannel(varName = ''):
#         if varName in "V1": return 1
#         if varName in "V2": return 2
#         if varName in "V3": return 3
#         if varName in "V4": return 4
#         if varName in "V5": return 5
#         if varName in "V6": return 6
#         if varName in "V7": return 7
#         if varName in "V8": return 8
#         return 0
