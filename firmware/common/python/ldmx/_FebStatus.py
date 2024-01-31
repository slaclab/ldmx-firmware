import pyrogue as pr
import epics
#import functools as ft

class FebPowerStatus(pr.Device):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        for i in range(10):
            getDigi = lambda: bool(epics.caget(f'SVT:lv:fe:{i}:digi:stat'))
            getAnap = lambda: bool(epics.caget(f'SVT:lv:fe:{i}:anap:stat'))
            getAnan = lambda: bool(epics.caget(f'SVT:lv:fe:{i}:anan:stat'))

            digiVar = pr.LocalVariable(name = f'FebDigiPwr[{i}]', localGet = getDigi, value = False)
            anapVar = pr.LocalVariable(name = f'FebAnapPwr[{i}]', localGet = getAnap, value = False)
            ananVar = pr.LocalVariable(name = f'FebAnanPwr[{i}]', localGet = getAnan, value = False)

            self.add(digiVar)
            self.add(anapVar)
            self.add(ananVar)

            def digiCb(pvname, value, char_value, i=i, **kwargs):
                print(f'Saw FEB {i} digi power change to {value}')
                print(f'FEB {i} stat: {getDigi()}')
                #digiVar.set(value)

            def anapCb(pvname, value, char_value, i=i, **kwargs):
                print(f'Saw FEB {i} anap power change to {value}')
                print(f'FEB {i} stat: {getAnap()}')
                #anapVar.set(value)

            def ananCb(pvname, value, char_value, i=i, **kwargs):
                print(f'Saw FEB {i} anan power change to {value}')
                print(f'FEB {i} stat: {getAnan()}')
                #ananVar.set(value)

            epics.camonitor(f'SVT:lv:fe:{i}:digi:switch', callback=digiCb)
            epics.camonitor(f'SVT:lv:fe:{i}:anap:switch', callback=anapCb)
            epics.camonitor(f'SVT:lv:fe:{i}:anan:switch', callback=ananCb)
