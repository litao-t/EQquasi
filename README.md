*EQquasi*
=======
*```EQquasi```* is a parallel finite-element software to simulate quasi-static/quasi-dynamic earthquake cycle deformation induced by fault slips governed by rate- and state- friction. It is part of the fully dynamic earthquake cycle simulator *```EQsimu```* [(*Liu et al.*, 2020, *GJI*)](https://doi.org/10.1093/gji/ggz475) to simulate deformation during the inter-seismic, nucleation, post-seismic, and dynamic rupture phases of earthquake cycles. It relies on parallel solvers [*MUMPS*](http://mumps-solver.org) or *AZTEC* to handle the computing loads. It is written in FORTRAN90 with post-process scripts written in [MATLAB](https://www.mathworks.com/products/matlab.html).

This repository hosts the source code, compiling instruction, post-processing scripts, batch scripts for some High Perforamnce Computing systems, and input files of different benchmark models.

*MUMPS* is distributed under the [CeCILL-C license](http://www.cecill.info/licences/Licence_CeCILL-C_V1-en.html) and for proper ackowledgement, please read the LICENCE for MUMPS. The newest version of MUMPS can be downloaded through this [link](http://mumps-tech.com/mumps-2/).

Operating environment
---------------------
* a Unix-like operating system
* build tools cmake
* Fortran compilers
* a functioning MPI environment
* MUMPS/AZTEC installed and paths correctly set up
* Matlab installed for postprocessing

Note
----
*EQquasi* is still under development and comes without any guaranteed functionality.

If you are interested in using *EQquasi* or have any questions or comments, please contact Dunyu Liu (dliu@ig.utexas.edu). 
