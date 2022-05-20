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
    def __init__(self, numHybrids, febHw, febCore, **kwargs):
        super().__init__(**kwargs)

        self.enable.hidden = True


        self.add(HybridVoltageControl(
            name = 'DVDD',
            trim = febHw.Ad5144[numHybrids].Rdac[2],
            near = febHw.Ltc2991[numHybrids].V1,
            sense = None,
            senseMult = None,
            pgood = febCore.FebConfig.node(f'Hybrid{numHybrids}_Dvdd_PGood'),
            pgood_fall = febCore.FebConfig.node(f'Hybrid{numHybrids}_Dvdd_FallCnt'),
            far = febCore.Hybrid[numHybrids].DVDD,
            current = febHw.Ltc2991[numHybrids].V2))

        self.add(HybridVoltageControl(
            name = 'AVDD',
            trim = febHw.Ad5144[numHybrids].Rdac[1],
            near = febHw.Ltc2991[numHybrids].V3,
            sense = None, #febHw.Ltc2991[numHybrids].V8,
            senseMult = None, # -9.09,
            pgood = febCore.FebConfig.node(f'Hybrid{numHybrids}_Avdd_PGood'),
            pgood_fall = febCore.FebConfig.node(f'Hybrid{numHybrids}_Avdd_FallCnt'),
            far = febCore.Hybrid[numHybrids].AVDD,
            current = febHw.Ltc2991[numHybrids].V4))

        self.add(HybridVoltageControl(
            name = 'V125',
            trim = febHw.Ad5144[numHybrids].Rdac[0],
            near = febHw.Ltc2991[numHybrids].V5,
            sense = None, #febHw.Ltc2991[4].node(f'V{numHybrids*2+2}'),
            senseMult = None, # 4.02,
            pgood = febCore.FebConfig.node(f'Hybrid{numHybrids}_V125_PGood'),
            pgood_fall = febCore.FebConfig.node(f'Hybrid{numHybrids}_V125_FallCnt'),
            far = febCore.Hybrid[numHybrids].V125,
            current = febHw.Ltc2991[numHybrids].V6))

        self.add(pr.LinkVariable(
            name = 'HybridOnStatus',
            dependencies = [self.DVDD.PGood, self.AVDD.PGood, self.V125.PGood],
            mode = ['RO'],
            linkedGet = lambda: 2.5 if (self.DVDD.PGood.value() and self.AVDD.PGood.value() and self.V125.PGood.value()) else 0.0))
        
