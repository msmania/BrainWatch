import sys
import os
import struct
from neurosky import stream as ns

def getFileWriter(outFile):
    outFileClosure = outFile
    def writeFile(bstr):
        if len(bstr) == 2 \
           and outFileClosure != None \
           and (not outFileClosure.closed):
            n = struct.unpack('>h', bstr)[0]
            outFileClosure.write(str(n) + '\n')
    return writeFile

def loadSample(findex):
    samples = [
        '2016-07-17-16-16-30-RawPackageRecording.txt',
        '2016-07-17-12-29-04-RawPackageRecording.txt',
        '2016-07-16-15-08-44-RawPackageRecording.txt',
        '2016-07-15-18-17-19-RawPackageRecording.txt',
        '2016-07-15-07-12-33-RawPackageRecording.txt',
        '2016-07-14-07-46-46-RawPackageRecording.txt',
        '2016-07-13-21-47-37-RawPackageRecording.txt',
        '2016-07-13-07-41-22-RawPackageRecording.txt',
        '2016-07-12-23-15-04-RawPackageRecording.txt',
        '2016-07-11-21-42-02-RawPackageRecording.txt',
    ]
    root = os.path.expanduser('~/Xcode/BrainWatch/Samples/')
    with open(root + samples[findex], 'rb') as fileIn:
        with open('out', 'w') as fileOut:
            s = ns.NeuroSkyStream(getFileWriter(fileOut))
            s.readFromFile(fileIn)

if __name__ == '__main__':
    idx = int(sys.argv[1]) if len(sys.argv) > 1 else 2
    loadSample(idx)
