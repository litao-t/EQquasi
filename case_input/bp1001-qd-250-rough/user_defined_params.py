#! /usr/bin/env python3

# cylce id. Simulate quasi-dynamic earthquake cycles from istart to iend.
istart = 1
iend = 1
# mode of the code - quasi-dynamic (1) or fully-dynamic (2). 
mode = 2 

# model_domain (in meters)
xmin, xmax = -60.0e3, 60.0e3
ymin, ymax = -20.0e3, 20.0e3
zmin, zmax = -60.0e3, 0.0e3

# creeping zone bounaries.
# creeping zones are assinged on the lateral sides and bottom of 
# the RSF controlled region and will slide at fixed loading slip rate.
xminc, xmaxc, zminc = -40.0e3, 40.0e3, -40.0e3

dx = 1000.0e0 # cell size, spatial resolution
nuni_y_plus, nuni_y_minus = 5, 5 # along the fault-normal dimension, the number of cells share the dx cell size.
enlarging_ratio = 1.3e0 # along the fault-normal dimension (y), cell size will be enlarged at this ratio compoundly.

# Isotropic material propterty.
# Vp, Vs, Rou
vp, vs, rou = 6.0e3, 3.464e3, 2.67e3
init_norm = -25.0e6 # initial normal stress in Pa. Negative compressive.

# Controlling switches for EQquasi system
rough_fault = 1 # include rough fault yes(1) or not(0).
rheology    = 1 # elastic(1). 
friclaw     = 3 # rsf_aging(3), rsf_slip(4).
ntotft      = 1 # number of total faults.
solver      = 1 # solver option. MUMPS(1, recommended). AZTEC(2).
nt_out      = 100 # Every nt_out time steps, disp of the whole model and on-fault variables will be written out in netCDF format.
bp          = 1001 
# currently supported cases
# 5 (SCEC-BP5)
# 1001 (GM-cycle)

# xi, minimum Dc
xi = 0.015 # xi used to limit variable time step size. See Lapusta et al. (2009).
minDc = 0.13 # meters

# loading 
far_vel_load = 4e-10 # far field loading velocity on xz planes. A minus value is applied on the other side.
creep_slip_rate = 1.0e-9 # creeping slip rate outside of RSF controlled region.
exit_slip_rate = 1.0e-3 # exiting slip rate for EQquasi [m/s].

####################################
##### HPC resource allocation ######
####################################
casename = "bp1001test"
HPC_nnode = 1 # Number of computing nodes. On LS6, one node has 128 CPUs.
HPC_ncpu = 30 # Number of CPUs requested.
HPC_queue = "normal" # q status. Depending on systems, job WALLTIME and Node requested.
HPC_time = "00:10:00" # WALLTIME, in hh:mm:ss format.
HPC_account = "EAR22013" # Project account to be charged SUs against.
HPC_email = "dliu@ig.utexas.edu" # Email to receive job status.

##############################################
##### Single station time series output ######
##############################################

# (x,z) coordinate pairs for on-fault stations (in km).
st_coor_on_fault = [[-36.0, 0.0], [-16.0,0.0], [0.0,0.0], [16.0,0.0], \
   [36.0,0.0], [-24.0,0.0], [-16.0,0.0], [0.0,-10.0], [16.0,-10.0], [0.0,-22.0]]
   
# (x,y,z) coordinates for off-fault stations (in km).
st_coor_off_fault = [[0,8,0], [0,8,-10], [0,16,0], [0,16,-10], [0,32,0], \
   [0,32,-10], [0,48,0], [16,8,0], [-16,8,0]]
n_on_fault = len(st_coor_on_fault)
n_off_fault = len(st_coor_off_fault)

# Additional solver options for AZTEC
az_op = 2 # AZTEC options
az_maxiter = 2000 # maximum iteration for AZTEC
az_tol = 1.0e-7 # tolerance for solution in AZTEC.

