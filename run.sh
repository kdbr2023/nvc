#!/bin/bash
rm -rf *.log qrun.out
qrun -uvmhome uvm-1.2 +incdir+src src/nvc_pkg.sv src/test.sv
