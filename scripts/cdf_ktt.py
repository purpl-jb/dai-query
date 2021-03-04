#!/usr/local/bin/python3

# expect arguments: <output-file> <observations> <batch> <incr> <dd> <dd+incr>
# where each <config> is one analysis latency observation per row, <observations> rows

import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np
import csv
import sys
import statistics

blue   = '#1f77b4'
orange = '#ff7f0e'
green  = '#2ca02c'
red    = '#d62728'

observations = int(sys.argv[2])

ys = np.array(range(observations))/float(observations) 

batch = np.sort([float(line) for line in open(sys.argv[3])])/float(1000)
incr = np.sort([float(line) for line in open(sys.argv[4])])/float(1000)
dd = np.sort([float(line) for line in open(sys.argv[5])])/float(1000)
dd_incr = np.sort([float(line) for line in open(sys.argv[6])])/float(1000)

plt.rc('text', usetex=True)
plt.rc('font', family='serif',size=16.0)
#plt.rc('axes.spines', top=False,right=False)
plt.rc('legend', edgecolor='white',fontsize="x-large",handlelength=0,framealpha=0)

plt.rc('axes',labelsize='x-large',linewidth=1.5,labelpad=-15)
plt.rc('xtick.major',width=1.5)
plt.rc('ytick.major',width=1.5)

plt.rc('xtick',labelsize='large')
plt.rc('ytick',labelsize='large')

plt.axis([0,1,0.5,1])

plt.xlabel(r"Analysis Latency (sec)")

plt.xticks([0,0.25,0.5,0.75,1,],labels=['0','','','','1'])
plt.yticks([0.5,0.6,0.7,0.8,0.9,1.0])

plt.plot(batch,ys,color=blue)
plt.plot(incr,ys,color=orange)
plt.plot(dd,ys,color=green)
plt.plot(dd_incr,ys,color=red)

plt.savefig(sys.argv[1],dpi=400, bbox_inches='tight')
    
