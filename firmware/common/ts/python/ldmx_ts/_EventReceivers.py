import pyrogue as pr
import rogue

from dataclasses import dataclass, field
from typing import List

def parseEventFrame(frame):
    channel = frame.getChannel()
    fl = frame.getPayload()
    raw = bytearray(fl)
    frame.read(raw, 0)

    bunchCount = raw[0]
    pulseId = int.from_bytes(raw[1:9], 'little', signed=False)
    contributorId = raw[9]
    subsystemId = raw[10]

    print('Got frame')
    print(f'{subsystemId=}, {contributorId=}')
    print(f'{pulseId=}, {bunchCount=}')

    return raw[16:]
        
@dataclass
class TsData6ChMsg:
    pulseId: int
    bunchCount: int
    contributorId: int
    subsystemId: int
    capId: int
    ce: int
    bc0: int
    adc: List[int] = field(default_factory=list)
    tdc: List[int] = field(default_factory=list)

    @classmethod
    def from_ba(cls, data: bytearray):
        msg = cls(
            adc = [int(data[i]) for i in range(0, 6)],
            tdc = [int(data[i]) for i in range(8, 14)],
            capId = int(data[14] & 0x3),
            ce = int(data[14]>>2 & 0x1),
            bc0 = int(data[14]>>3 & 0x1))
        return msg
    
        
class TsRawEventReceiver(rogue.interfaces.stream.Slave):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)


        
    def _acceptFrame(self, frame):
        channel = frame.getChannel()
        fl = frame.getPayload()
        raw = bytearray(fl)
        frame.read(raw, 0)
        
        bunchCount = raw[0]
        pulseId = int.from_bytes(raw[1:9], 'little', signed=False)
        contributorId = raw[9]
        subsystemId = raw[10]

        msgs = []
        for i in range(0, len(data), 16):
            msg = 
            msgs.append(TsData6ChMsg.from_ba(data[i:i+16]))

        print(msgs)

