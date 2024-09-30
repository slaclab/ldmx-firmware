import pyrogue as pr
import rogue

import numpy as np
from dataclasses import dataclass, field
from typing import List

@dataclass
class DaqEvent:
    version: int
    subsystemId: int 
    contributorId: int
    bunchCount: int
    pulseId: int
    data: np.ndarray

    @classmethod
    def from_numpy(cls, arr):
        header = cls(
            version = int(arr[0]),
            subsystemId = int(arr[1]),
            contributorId = int(arr[2]),
            bunchCount = int(arr[7]),
            pulseId = int(arr[8:16].view(np.uint64)),
            data = arr[16:])
        return header

    
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
    def from_numpy(cls, data):
        msg = cls(
            adc = [int(data[i]) for i in range(0, 6)],
            tdc = [int(data[i]) for i in range(8, 14)],
            capId = int(data[14] & 0x3),
            ce = int(data[14]>>2 & 0x1),
            bc0 = int(data[14]>>3 & 0x1))
        return msg
    
        
class TsDaqEventReceiver(rogue.interfaces.stream.Slave):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        
    def _acceptFrame(self, frame):
        rawNumpy = frame.getNumpy(0, frame.getPayload())

        event = DaqEvent.from_numpy(rawNumpy)

        data = event.data
        data.resize(data.size//16, 16)
        
        msgs = [TsData6ChMsg.from_numpy(arr) for arr in data]

        print(msgs)

