import pyrogue as pr

class HpsFebPGoodMon(pr.Device):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        powerList = [
            'FebA22V',
            'FebA18V',
            'FebA16V',
            'FebA29VA',
            'FebA29VD',
            'Hybrid0_V125',
            'Hybrid0_Dvdd',
            'Hybrid0_Avdd',
            'Hybrid1_V125',
            'Hybrid1_Dvdd',
            'Hybrid1_Avdd',
            'Hybrid2_V125',
            'Hybrid2_Dvdd',
            'Hybrid2_Avdd',
            'Hybrid3_V125',
            'Hybrid3_Dvdd',
            'Hybrid3_Avdd']

        for i, name in enumerate(powerList):
            self.add(pr.RemoteVariable(
                name=f"{name}_PGood",
                description='Regulator PGood value',
                offset=0x80+(i*4),
                bitSize=1,
                bitOffset=31,
                mode='RO',
                pollInterval=10,
                hidden=True,
                base=pr.Bool))

        for i, name in enumerate(powerList):
            self.add(pr.RemoteVariable(
                name=f'{name}_FallCnt',
                offset=0x80+(i*4),
                bitSize=31,
                bitOffset=0,
                mode='RO',
                pollInterval=10,
                hidden=True,
                base=pr.UInt))
