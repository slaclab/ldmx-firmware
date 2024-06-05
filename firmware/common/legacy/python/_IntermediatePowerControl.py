import pyrogue as pr

class IntermediateVoltageControl(pr.Device):
    def __init__(self, trim, voltage, **kwargs):
        super().__init__(**kwargs)

        self.enable.hidden = True

        self.add(pr.LinkVariable(
            name='Trim',
            value=175,
            variable=trim,
        ))

        self.add(pr.LinkVariable(
            name='Voltage',
            variable=voltage,
            mode='RO',
            units='V',
            typeStr = 'float',
            pollInterval=3,
        ))

class IntermediatePowerControl(pr.Device):
    def __init__(self, ad5144, pm, **kwargs):
        super().__init__(**kwargs)

        self.add(IntermediateVoltageControl(
            name = 'FebA16V',
            trim = ad5144.Rdac[0],
            voltage = pm.FebA16V))

        self.add(IntermediateVoltageControl(
            name = 'FebA29VA',
            trim = ad5144.Rdac[1],
            voltage = pm.FebA29VA))

        self.add(IntermediateVoltageControl(
            name = 'FebA29VD',
            trim = ad5144.Rdac[2],
            voltage = pm.FebA29VD))

        self.add(IntermediateVoltageControl(
            name = 'FebA22V',
            trim = ad5144.Rdac[3],
            voltage = pm.FebA22V))
