import rogue
from collections import defaultdict
import hps
import pyrogue
import pprint

pp = pprint.PrettyPrinter(indent=4)

nesteddict = lambda: defaultdict(nesteddict)

def toInt(ba):
    return int.from_bytes(ba, 'little')

def getField(value, highBit, lowBit):
    mask = 2**(highBit-lowBit+1)-1
    return (value >> lowBit) & mask

def parseDataFrame(channel, ba):
    d = {}
    headerRaw = toInt(ba[0:16])
    d['Channel'] = hps.HpsSvtDataWriter.EVENT_CHANNELS.index(channel)
    d['DataDpm'] = getField(headerRaw, 39, 32)
    d['EventCount'] = getField(headerRaw, 31, 0)
    d['EventTimestamp'] = getField(headerRaw, 127, 64)
    d['SizeBytes'] = len(ba)
    tailRaw = toInt(ba[-16:])
    d['SampleCount'] = getField(tailRaw, 11, 0)
    d['SkipCount'] = getField(tailRaw, 23, 12)
    d['SyncError'] = getField(tailRaw, 26, 26)
    d['BurnFrame'] = getField(tailRaw, 27, 27)

    dataRaw = ba[16:-16]
    numSamples = len(dataRaw)//16

    d['Samples'] = []
    for i in range(numSamples):
        d['Samples'].append(
            parseSample(toInt(dataRaw[i*16:i*16+16])))

    return d

def parseSample(word):
    d = {}
    d['Head'] = getField(word, 126, 126)
    d['Tail'] = getField(word, 125, 125)
    d['Filter'] = getField(word, 127, 127)
    d['ReadError'] = getField(word, 124, 124)
    d['Rce'] = getField(word, 103, 96)
    d['Feb'] = getField(word, 111, 104)
    d['ApvCh'] = getField(word, 118, 112)
    d['ApvAddr'] = getField(word, 121, 119)
    d['HybridAddr'] = getField(word, 123, 122)
    d['Data0'] = getField(word, 15, 0)
    d['Data1'] = getField(word, 31, 16)
    d['Data2'] = getField(word, 47, 32)
    d['Data3'] = getField(word, 63, 48)
    d['Data4'] = getField(word, 79, 64)
    d['Data5'] = getField(word, 95, 80)
    return d


class SimpleDataParser(rogue.interfaces.stream.Slave):
    def __init__(self):
        rogue.interfaces.stream.Slave.__init__(self)

        self.state = {}#nesteddict()
        self.baselineEvents = []
        self.injectionEvents = []
        self.baselineDict = nesteddict()

    def _acceptFrame(self, frame):
        #print(f'Channel: {frame.getChannel()}')
        if frame.getError():
            print('Frame Error!')
            return

        ba = bytearray(frame.getPayload())
        frame.read(ba, 0)
        if frame.getChannel() in hps.HpsSvtDataWriter.EVENT_CHANNELS:
            state = self.state['HpsSvtDaqRoot']['RunControl']['CalibrationState']
            if state == 'Inject':
                return

            event = parseDataFrame(frame.getChannel(), ba)
            eventCount = event['EventCount']

            print(f"Got frame with {len(event['Samples'])} samples")

            for sample in event['Samples']:
                print(sample)
                head = sample['Head']
                tail = sample['Tail']
                feb = sample['Feb']
                ch = sample['ApvCh']
                apv = sample['ApvAddr']
                hy = sample['HybridAddr']
                data = [sample['Data0'], sample['Data1'], sample['Data2'], sample['Data3'], sample['Data4'], sample['Data5']]

                if state == 'Baseline':
                    if not head and not tail:
                        for i, d in enumerate(data):
                            self.baselineDict[feb][hy][apv][ch][i][eventCount] = d


            if event['EventCount']%100 == 0:
                print(event['EventCount'])

        elif frame.getChannel() == hps.HpsSvtDataWriter.CONFIG_CHANNEL:
            #return
            yamlString = bytearray(ba).rstrip(bytearray(1)).decode('utf-8')

            try:
                yamlDict = pyrogue.yamlToDict(yamlString)
                pyrogue.dictUpdate(self.state, yamlDict)
                #pp.pprint(self.state)
            except Exception as e:
                print("Error in yaml")
                print(yamlString)
                raise e
                exit(1)
            #print(f'Got YAML Frame')
