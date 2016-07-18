import sys
import os
import struct
from neurosky import stream as ns
import numpy as np
import cv2

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

    class Accumulator(object):
        def __init__(self):
            self.bstrBuffer = ''

        def getCallback(self):
            closure = self
            def callback(bstr):
                if len(bstr) == 2:
                    closure.bstrBuffer += bstr
            return callback

        def data(self):
            x = np.zeros(len(self.bstrBuffer) / 2)
            it = np.nditer(x, ['c_index'], ['writeonly'])
            while not it.finished:
                ss = self.bstrBuffer[it.index*2:it.index*2+2]
                it[0] = struct.unpack('>h', ss)
                it.iternext()
            self.bstrBuffer = ''
            return x

    accumulator = Accumulator()

    root = os.path.expanduser('~/Xcode/BrainWatch/Samples/')
    with open(root + samples[findex], 'rb') as fileIn:
        s = ns.NeuroSkyStream(accumulator.getCallback())
        s.readFromFile(fileIn)

    return accumulator.data()

def printValues(array, log_threshold):
    it = np.nditer(array, flags=['multi_index'])
    while not it.finished:
        if it[0] > .0 and np.log(it[0]) > log_threshold:
            print "[%s] = %.4e" % (it.multi_index, it[0])
        it.iternext()

def saveFrequencyDomain(array, imgHeight, imgName):
    width = len(array)
    im_complex = np.zeros((1, width, 2), dtype=np.float64)
    im_complex[:, :, 0] = array
    im_complex = cv2.dft(im_complex, dst=im_complex, flags=cv2.DFT_ROWS)
    im_re, im_im = cv2.split(im_complex)
    im_mag = cv2.magnitude(im_re, im_im)
    # printValues(im_mag, -10)
    im_mag = im_mag[0][0:len(im_mag[0])/2]
    im_gray = np.zeros(np.shape(im_mag))
    im_gray = cv2.normalize(im_mag, im_gray, 0, 255, cv2.NORM_MINMAX)
    im = np.tile(im_gray, (imgHeight, 1))
    cv2.imwrite(imgName, im)

if __name__ == '__main__':
    idx = int(sys.argv[1]) if len(sys.argv) > 1 else 2
    x = loadSample(idx)
    saveFrequencyDomain(x[0:1024], 100, 'dft.png')
