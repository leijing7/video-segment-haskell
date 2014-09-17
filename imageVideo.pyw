import imageVideoGui
from PyQt4 import QtGui, QtCore
import sys, os
import subprocess
import numpy as np
import cv2
import LJUtil
import thread
import copy

class UIDialog(QtGui.QDialog, imageVideoGui.Ui_Dialog):
	finishTriger = QtCore.pyqtSignal(str)

	def __init__(self, parent=None):
		super(UIDialog, self).__init__(parent)
		self.setupUi(self)
		self.init()

	def init(self):
		self.oriVideoPath = ''
		self.imgs =[]
		self.curImgPos = 0

		self.normalVideoPaths = []
		self.stillVideoPaths = []
		self.audioPaths = []

	def videoSelectButtonClicked(self):
		self.oriVideoPath = str(QtGui.QFileDialog.getOpenFileName(self, 'Open File', '.'))
		#self.oriVideoPath = 'g:/lei/video/210810_Cantonese_MC3.avi'
		if not self.oriVideoPath:
			return
		self.init()
		cap = cv2.VideoCapture(self.oriVideoPath)
		for i in range(100):
			f, img = cap.read()
			if not f:
				break
			self.imgs.append(img)
		if len(self.imgs) > 0:
			self.imageLabel.setPixmap(LJUtil.cvImage2QPixmap(self.imgs[self.curImgPos]))

	def moveLeftButtonClicked(self):
		if self.curImgPos > 0:
			self.curImgPos -= 1
			self.imageLabel.setPixmap(LJUtil.cvImage2QPixmap(self.imgs[self.curImgPos]))
		
	def moveRightButtonClicked(self):
		if self.curImgPos < len(self.imgs)-1:
			self.curImgPos += 1
			self.imageLabel.setPixmap(LJUtil.cvImage2QPixmap(self.imgs[self.curImgPos]))
		
	def imageChooseButtonClicked(self):
		cv2.imshow("Preview", self.imgs[self.curImgPos])
		cv2.waitKey(0)

	def generateVideoButtonClicked(self):
		dirWithBase, ext = os.path.splitext(self.oriVideoPath)
		normalVideoDir = dirWithBase
		ffmpegPath = dirWithBase[:dirWithBase.rfind('/')] + '/ffmpeg/ffmpeg'
		audioDir = dirWithBase + '_audioOnly'
		stillVideoDir = dirWithBase + '_stillVideo'
		stillImg = self.imgs[self.curImgPos] 

		self.setFilePaths(normalVideoDir)
		self.finishTriger.connect(self.handle_finishTriger)
		thread.start_new_thread(self.generateVideo, (stillImg, ffmpegPath))

	def generateVideo(self, stillImg, ffmpegPath):
		self.progressBar.setRange(1, len(self.normalVideoPaths))
		counter = 0
		for nv, sv, au in zip(self.normalVideoPaths, self.stillVideoPaths, self.audioPaths):
			self.generateVideoOnly(stillImg, nv, sv)
			self.combineAV(ffmpegPath, au, sv)
			counter += 1
			self.progressBar.setValue(counter)
		print 'Finished.'
		self.finishTriger.emit("Finished!")
		self.progressBar.setValue(0)

	def handle_finishTriger(self, txt):
		QtGui.QMessageBox.warning(self,'Notice', txt)

	def setFilePaths(self, normalVideoDir):
		stillVideoDir = normalVideoDir+'_stillVideo/'
		if not os.path.exists(stillVideoDir):
			os.makedirs(stillVideoDir)
		for (dir, subdirs, files) in os.walk(normalVideoDir): 
			for f in files:
				path = os.path.normpath( normalVideoDir+'/'+f )
				self.normalVideoPaths.append(path)
				self.stillVideoPaths.append( stillVideoDir + f )
				self.audioPaths.append(normalVideoDir+'_audioOnly/'+os.path.splitext(f)[0]+'.wav')

	def generateVideoOnly(self, simg, nv, sv):
		cap = cv2.VideoCapture(nv) #to get the fps and frame count
		frameRate = cap.get(cv2.cv.CV_CAP_PROP_FPS  )
		frameCount = cap.get(cv2.cv.CV_CAP_PROP_FRAME_COUNT )

		writer = cv2.VideoWriter()
		writer.open(sv, cv2.cv.CV_FOURCC('F', 'L', 'V', '1'),frameRate, 
						(simg.shape[1], simg.shape[0]),1)
		for i in range(int(frameCount)):
			writer.write(simg)

	def combineAV(self, ffmpegPath, a, v):
		combineCmd = ffmpegPath + ' -i ' + a + ' -i ' + v + ' -acodec copy -vcodec msmpeg4v2 -y ' + v
		#print combineCmd
		#os.system(combineCmd)
		subprocess.call(combineCmd, shell=True)

app = QtGui.QApplication(sys.argv)
dialog = UIDialog()
dialog.show()
app.exec_()