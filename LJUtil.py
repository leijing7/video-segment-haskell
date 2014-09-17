BLUE = (255,0,0)
GREEN= (0,255,0)
RED = (0,0,255)

def string2int(srcStr):
	if not str.isdigit(str(srcStr)):
		return 0
	else:
		return int(srcStr)

#mini second to second
def ms2s(ms): 
	return '{0:.2f}'.format(float(ms)/1000.0)

#check if a point is in a rect
def isPointInRoi(pt,topLeftPoint,bottomRightPoint):
	#in case the input is string not integer, otherwise the comparison would be wrong
	pt = (int(pt[0]), int(pt[1]))
	topLeftPoint = (int(topLeftPoint[0]), int(topLeftPoint[1]))
	bottomRightPoint = (int(bottomRightPoint[0]), int(bottomRightPoint[1]))

	if (topLeftPoint[0]<=pt[0]) and (pt[0]<=bottomRightPoint[0]) and \
	   (topLeftPoint[1]<=pt[1]) and (pt[1]<=bottomRightPoint[1]):
		return True
	else:
		return False

import cv2
from PyQt4 import QtGui, QtCore

def cvImage2QPixmap(cvimg):
	#BGR2RGB
	cvRGBImg = cv2.cvtColor(cvimg, cv2.COLOR_BGR2RGB)
	#convert numpy mat to pixmap image
	qimg = QtGui.QImage(cvRGBImg.data, cvRGBImg.shape[1], cvRGBImg.shape[0], 
		QtGui.QImage.Format_RGB888)
	return QtGui.QPixmap.fromImage(qimg)
