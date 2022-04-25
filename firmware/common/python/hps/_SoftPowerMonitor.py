import pyrogue as pr
import math



class SoftPowerMonitor(pr.Device):
    def __init__ (self, parent, hybrids=4, **kwargs):
        super().__init__(description="Power Monitor object.", **kwargs)

        def getVal(var):
            return var.dependencies[0].value()

        def getXadc(mult):
            def linkedGet(var):
                return var.dependencies[0].value() * mult
            return linkedGet

        def getThermistor(var):
            voltage = var.dependencies[0].value()
            if voltage == 0.0:
                #math.log call will die if voltage -> resistance = 0
                return -273.15
            current = (1.0 - voltage) / 10000
            resistance = voltage / current
            tempKelvin = 3750 / math.log( resistance / 0.03448533 )
            tempCelcius = tempKelvin - 273.15
            return tempCelcius

        d= parent.Xadc

        self.add(pr.LinkVariable(
            name="FebFpgaTemp",
            units='degC',
            disp='{:1.3f}',
            pollInterval=1,
            linkedGet=getVal,
            typeStr = 'float',
            dependencies=[d.Temperature],
            highWarning=40.0,
            highAlarm=60.0))

        self.add(pr.LinkVariable(
            name="FebD6V",
            units='V',
            disp='{:1.3f}',
            typeStr = 'float',
            pollInterval=1,
            linkedGet=getXadc(7.04),
            dependencies=[d.Aux[7]],
            highWarning=4.1,
            highAlarm=4.5))

        self.add(pr.LinkVariable(
            name="FebVccInt",
            disp='{:1.3f}',
            typeStr = 'float',
            pollInterval=1,
            linkedGet=getVal,
            dependencies=[d.VccInt],
            lowWarning = .9,
            lowAlarm = .85,
            highWarning=1.1,
            highAlarm=1.15))

        self.add(pr.LinkVariable(
            name="FebD10V_MGT",
            units='V',
            disp='{:1.3f}',
            typeStr = 'float',
            pollInterval=1,
            linkedGet=getXadc(2.0),
            dependencies=[d.Aux[10]],
            highWarning=1.1,
            highAlarm=1.15))

        self.add(pr.LinkVariable(
            name="FebD12V_MGT",
            units='V',
            disp='{:1.3f}',
            typeStr = 'float',
            pollInterval=1,
            linkedGet=getXadc(2.0),
            dependencies=[d.Aux[9]],
            highWarning=1.2*1.1,
            highAlarm=1.2*1.15))

        self.add(pr.LinkVariable(
            name="FebVccAux",
            disp='{:1.3f}',
            typeStr = 'float',
            pollInterval=1,
            linkedGet=getVal,
            dependencies=[d.VccAux],
            highWarning=1.8*1.1,
            highAlarm=1.8*1.15
        ))

        self.add(pr.LinkVariable(
            name="FebD25V",
            units='V',
            disp='{:1.3f}',
            typeStr = 'float',
            pollInterval=1,
            linkedGet=getXadc(3.0),
            dependencies=[d.Aux[8]],
            highWarning=2.5*1.1,
            highAlarm=2.5*1.15))

        self.add(pr.LinkVariable(
            name="FebD33V",
            units='V',
            disp='{:1.3f}',
            typeStr = 'float',
            pollInterval=1,
            linkedGet=getXadc(4.01),
            dependencies=[d.Aux[2]],
            highWarning=3.3*1.1,
            highAlarm=3.3*1.15))


        self.add(pr.LinkVariable(
            name="FebA6V",
            disp='{:1.3f}',
            units='V',
            typeStr = 'float',
            pollInterval=1,
            linkedGet=getXadc(7.04),
            dependencies=[d.Aux[0]],
            highWarning=5.5*1.1,
            highAlarm=5.5*1.15
        ))

        self.add(pr.LinkVariable(
            name="FebA5V",
            units='V',
            disp='{:1.3f}',
            typeStr = 'float',
            pollInterval=1,
            linkedGet=getXadc(6.1),
            dependencies=[d.Aux[1]],
            highWarning=5.0*1.1,
            highAlarm=5.0*1.15,
            lowWarning=5.0*.9,
            lowAlarm=5.0*.85))


        self.add(pr.LinkVariable(
            name="FebA22V",
            units='V',
            disp='{:1.3f}',
            typeStr = 'float',
            pollInterval=1,
            linkedGet=getXadc(3.0),
            dependencies=[d.Aux[3]],
        ))

        self.add(pr.LinkVariable(
            name="FebA29VA",
            units='V',
            disp='{:1.3f}',
            typeStr = 'float',
            pollInterval=1,
            linkedGet=getXadc(4.01),
            dependencies=[d.Aux[4]]))

        self.add(pr.LinkVariable(
            name="FebA29VD",
            units='V',
            disp='{:1.3f}',
            typeStr = 'float',
            pollInterval=1,
            linkedGet=getXadc(4.01),
            dependencies=[d.Aux[5]]))

        self.add(pr.LinkVariable(
            name="FebA16V",
            units='V',
            disp='{:1.3f}',
            typeStr = 'float',
            pollInterval=1,
            linkedGet=getXadc(3.0),
            dependencies=[d.Aux[6]]))


        self.add(pr.LinkVariable(
            name="FebA18V",
            units='V',
            disp='{:1.3f}',
            typeStr = 'float',
            pollInterval=1,
            linkedGet=getXadc(3.0),
            dependencies=[d.Aux[11]],
            highWarning=1.8*1.1,
            highAlarm=1.8*1.15,
            lowWarning=1.8*.9,
            lowAlarm=1.8*.85))

        self.add(pr.LinkVariable(
            name="FebAN6V",
            units='V',
            disp='{:1.3f}',
            typeStr = 'float',
            pollInterval=1,
            linkedGet=getXadc(-7.0),
            dependencies=[d.Aux[12]],
            lowWarning=-5.5*1.1,
            lowAlarm=-5.5*1.15))

        self.add(pr.LinkVariable(
            name="FebAN5V",
            units='V',
            disp='{:1.3f}',
            typeStr = 'float',
            pollInterval=1,
            linkedGet=getXadc(-6.1),
            dependencies=[d.Aux[13]],
            lowWarning=-5.0*1.1,
            lowAlarm=-5.0*1.15,
            highWarning=-5.0*.9,
            highAlarm=-5.0*.85))

        self.add(pr.LinkVariable(
            name="FebTemp0",
            units='degC',
            disp='{:1.3f}',
            typeStr = 'float',
            pollInterval=1,
            linkedGet=getThermistor,
            dependencies=[d.Aux[14]]))

        self.add(pr.LinkVariable(
            name="FebTemp1",
            units='degC',
            disp='{:1.3f}',
            typeStr = 'float',
            pollInterval=1,
            linkedGet=getThermistor,
            dependencies=[d.Aux[15]]))

#         for v in parent.FebConfig.find(name='.*_PGood'):
#             self.add(pr.LinkVariable(
#                 name=v.name,
#                 pollInterval=1,
#                 linkedGet=getVal,
#                 dependencies=[v]))
