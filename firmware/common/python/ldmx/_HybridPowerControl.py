import pyrogue as pr

class HybridVoltageControl(pr.Device):
    def __init__(self,
                 trim,
                 near,
                 sense,
                 senseMult,
                 far,
                 current,
                 pgood,
                 pgood_fall,
                 **kwargs):
        super().__init__(**kwargs)

        self.enable.hidden = True

        self.add(pr.LinkVariable(
            name='Trim',
            value=150,
            variable=trim,
        ))

        self.add(pr.LinkVariable(
            name='VoltageNear',
            variable=near,
            mode='RO',
            units='V',
            typeStr = 'float',
            pollInterval=3,
        ))

        if sense is not None:
            self.add(pr.LinkVariable(
                name='VoltageSense',
                variable=sense,
                mode='RO',
                units='V',
                typeStr = 'float',
                pollInterval=3,
                linkedGet=lambda: sense.value() * senseMult,
            ))

        self.add(pr.LinkVariable(
            name='VoltageFar',
            variable=far,
            mode='RO',
            units='V',
            typeStr = 'float',
            pollInterval=3,
        ))

        self.add(pr.LinkVariable(
            name='Current',
            variable=current,
            mode='RO',
            units='A',
            disp='{:1.3f}',
            typeStr = 'float',
            linkedGet=lambda: current.value() / .02,
            pollInterval=3,
        ))

        self.add(pr.LinkVariable(
            name='PGood',
            variable=pgood,
            mode='RO',
            pollInterval=3,
        ))

        self.add(pr.LinkVariable(
            name='PGood_FallCnt',
            variable=pgood_fall,
            mode='RO',
            pollInterval=3))
        
#Control Power for 1 hybrid
class HybridPowerControl(pr.Device):
    def __init__(self, hybridNum, febCore, **kwargs):
        super().__init__(**kwargs)

        self.enable.hidden = True


        self.add(HybridVoltageControl(
            name = 'DVDD',
            trim = febCore.Ad5144[hybridNum].Rdac[2],
            near = febCore.Ltc2991[hybridNum].V1,
            sense = None,
            senseMult = None,
            pgood = febCore.FebConfig.node(f'Hybrid{hybridNum}_Dvdd_PGood'),
            pgood_fall = febCore.FebConfig.node(f'Hybrid{hybridNum}_Dvdd_FallCnt'),
            far = febCore.Hybrid[hybridNum].DVDD,
            current = febCore.Ltc2991[hybridNum].V2))

        self.add(HybridVoltageControl(
            name = 'AVDD',
            trim = febCore.Ad5144[hybridNum].Rdac[1],
            near = febCore.Ltc2991[hybridNum].V3,
            sense = None, #febCore.Ltc2991[hybridNum].V8,
            senseMult = None, # -9.09,
            pgood = febCore.FebConfig.node(f'Hybrid{hybridNum}_Avdd_PGood'),
            pgood_fall = febCore.FebConfig.node(f'Hybrid{hybridNum}_Avdd_FallCnt'),
            far = febCore.Hybrid[hybridNum].AVDD,
            current = febCore.Ltc2991[hybridNum].V4))

        self.add(HybridVoltageControl(
            name = 'V125',
            trim = febCore.Ad5144[hybridNum].Rdac[0],
            near = febCore.Ltc2991[hybridNum].V5,
            sense = None, #febCore.Ltc2991[4].node(f'V{hybridNum*2+2}'),
            senseMult = None, # 4.02,
            pgood = febCore.FebConfig.node(f'Hybrid{hybridNum}_V125_PGood'),
            pgood_fall = febCore.FebConfig.node(f'Hybrid{hybridNum}_V125_FallCnt'),
            far = febCore.Hybrid[hybridNum].V125,
            current = febCore.Ltc2991[hybridNum].V6))

        self.add(pr.LinkVariable(
            name = 'HybridOnStatus',
            dependencies = [self.DVDD.PGood, self.AVDD.PGood, self.V125.PGood],
            mode = ['RO'],
            linkedGet = lambda: 2.5 if (self.DVDD.PGood.value() and self.AVDD.PGood.value() and self.V125.PGood.value()) else 0.0))
        
