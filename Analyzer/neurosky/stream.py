# http://developer.neurosky.com/docs/doku.php?id=thinkgear_communications_protocol

class NeuroSkyStream(object):
    SYNC = '\xAA'
    EXCODE = '\x55'

    @staticmethod
    def LogError(msg):
        print 'E> ' + msg

    def __init__(self, callback):
        self.Level0Code = {
            0x02: {"name": "PoorSignal", "action": None},
            0x03: {"name": "HeartRate", "action": None},
            0x04: {"name": "Attention", "action": None},
            0x05: {"name": "Meditation", "action": None},
            0x06: {"name": "SingleByteRaw", "action": None},
            0x07: {"name": "RawMarkerSectionStart", "action": None},
            0x80: {"name": "RawWave512Hz", "action": callback},
            0x81: {"name": "EEGPower", "action": None},
            0x82: {"name": "ASICEEGPower", "action": None},
            0x83: {"name": "RRInterval", "action": None},
        }

    def readFromFile(self, fileIn):
        class LoopState:
            exit, sync, plength, payload, checksum = range(5)
        state = LoopState.sync
        while state != LoopState.exit:
            if state == LoopState.sync:
                c = fileIn.read(1)
                while len(c) > 0 and c != self.SYNC:
                    c = fileIn.read(1)
                c = fileIn.read(1)
                if len(c) == 0:
                    state = LoopState.exit
                elif c == self.SYNC:
                    state = LoopState.plength
            elif state == LoopState.plength:
                c = fileIn.read(1)
                if len(c) == 0:
                    state = LoopState.exit
                else:
                    payloadLength = ord(c[0])
                    if payloadLength > 0 or payloadLength < ord(self.SYNC):
                        state = LoopState.payload
                    elif payloadLength > ord(self.SYNC):
                        LogError("Too large plength")
                        state = LoopState.sync
            elif state == LoopState.payload:
                payload = fileIn.read(payloadLength)
                if len(payload) == 0:
                    state = LoopState.exit
                else:
                    state = LoopState.checksum
            elif state == LoopState.checksum:
                c = fileIn.read(1)
                if len(c) == 0:
                    state = LoopState.exit
                else:
                    checksum = sum([ord(i) for i in payload])
                    checksum &= 0xFF
                    checksum = ~checksum & 0xFF
                    if checksum == ord(c[0]):
                        self.parsePayload(payload)
                    else:
                        LogError("Bad checksum")
                        fileIn.seek(-payloadLength, 1)
                    state = LoopState.sync

    def parsePayload(self, payload):
        pos = 0
        while pos < len(payload):
            excodeLevel = 0
            while payload[pos] == self.EXCODE:
                pos += 1
                excodeLevel += 1
            code = ord(payload[pos])
            pos += 1
            if code & 0x80:
                dataLength = ord(payload[pos])
                pos += 1
            else:
                dataLength = 1
            if excodeLevel == 0 and code in self.Level0Code.keys() \
                                and self.Level0Code[code]["action"] != None:
               dispatcher = self.Level0Code[code]
               dispatcher["action"](payload[pos:pos + dataLength])
            pos += dataLength
