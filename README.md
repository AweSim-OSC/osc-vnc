## VNC Launch to Oxymoron

On a webservices node:

```
module switch torque torque-4.2.8_vis
qsub -v OUTDIR=/nfs/17/efranz/oxymoron-vnc-launch,XSTARTUP=/nfs/17/efranz/oxymoron-vnc-launch/xstartup vnc.pbs.turbo
```


