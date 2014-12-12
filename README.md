## VNC Launch to Oxymoron

First install the gems if you haven't already:

```
bundle install --local
```

On a webservices node:

```
module switch torque torque-4.2.8_vis
bundle exec ./vncsubmit [options] -x <xstartup_dir>
```

To get a list of arguments type:

```
bundle exec ./vncsubmit -h
```
