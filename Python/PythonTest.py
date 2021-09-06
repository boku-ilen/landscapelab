from godot import exposed, export
from godot import *
import os
import sys

from matplotlib.backends.backend_agg import FigureCanvasAgg as FigureCanvas
from matplotlib.figure import Figure
import matplotlib.pyplot

import numpy as np
import ctypes


@exposed
class PythonTest(Node):
	def canvas_to_godot_image(self, canvas):
		image = Image()
		
		width = canvas.get_width_height()[1]
		height = canvas.get_width_height()[0]
		
		size = width * height * 3
		
		pool_array = PoolByteArray()
		pool_array.resize(size)

		
		with pool_array.raw_access() as ptr:
			numpy_array = np.ctypeslib.as_array(ctypes.cast(ptr.get_address(), ctypes.POINTER(ctypes.c_uint8)), (size,))
			numpy_array[:] = np.frombuffer(canvas.tostring_rgb(), dtype=np.uint8).reshape(canvas.get_width_height()[::-1] + (3,)).flatten()
		
		image.create_from_data(height, width, False, Image.FORMAT_RGB8, pool_array)
		return image

	def _ready(self):
		time_before = OS.get_ticks_msec()
		
		fig = Figure(dpi=150)
		canvas = FigureCanvas(fig)
		
		plot = fig.add_subplot(111)
 
		# draw a cardinal sine plot
		x = np.arange(0, 100, 0.1)
		y = np.sin(x)
		plot.plot(x, y, color='red')

		canvas.draw()
		
		image = self.canvas_to_godot_image(canvas)
		
		image_texture = ImageTexture()
		image_texture.create_from_image(image)
		
		self.get_node("TextureRect").texture = image_texture
		
		time_after = OS.get_ticks_msec()
		
		print(time_after - time_before)
