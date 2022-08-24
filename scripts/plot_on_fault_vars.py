#! user/bin/python

import xarray as xr
import matplotlib.pyplot as plt
import numpy as np
import os
from matplotlib import animation, rc

#
SMALL_SIZE = 6

# Read in file name from terminal.
# fname = input("Enter the file name : ")


def plot_fault(fname):
  a = xr.open_dataset(fname)
  #print (a)

  shear_strike = a.shear_strike
  shear_dip = a.shear_dip
  norm = a.effective_normal
  slip_rate = a.slip_rate

  fig1 = plt.figure()
  plt.rc('font', size=SMALL_SIZE)

  ax11 = fig1.add_subplot(2,2,1)
  shear_strike.plot()
  ax11.set_xlabel('')
  #ax11.set_ylabel('')

  ax12 = fig1.add_subplot(2,2,2)
  shear_dip.plot()
  ax12.set_xlabel('')
  ax12.set_ylabel('')

  ax21 = fig1.add_subplot(2,2,3)
  norm.plot()
  #ax21.set_ylabel('')

  ax22 = fig1.add_subplot(2,2,4)
  slip_rate.plot()
  ax22.set_ylabel('')

  plt.savefig(fname + ".png", dpi = 600)
    
  return (fig1,)

def seek_numbers_filename(x):
    return (x[6:10])

#dirFiles = os.listdir(os.getcwd())
dirFiles = list()
for fname in os.listdir(os.getcwd()):
    name, file_extension = os.path.splitext(fname)
    if 'fault.' in name and '.nc' in file_extension:
        dirFiles += fname
        plot_fault(str(fname))

print(*dirFiles)
sorted_file_list = sorted(dirFiles, key=seek_numbers_filename)
print(sorted_file_list)

fig = plt.figure()
anim = animation.FuncAnimation(fig, plot_fault, frames = 1, interval = 1, blit=False)


