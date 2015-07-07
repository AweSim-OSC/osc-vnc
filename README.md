# OSC::VNC

Ruby library that provides VNC job submission to the OSC systems.

## Usage

Add this gem to your Gemfile:

```ruby
gem 'osc-vnc'
```

Run Bundler to update your gems:

```bash
$ bundle install --local
```

## Examples

### Run App on Oxymoron Batch System

For all cases we will need to create a new VNC session object. To create a VNC
session object you need to supply it the required information:

* the batch system you will submit it to
* the cluster it will run on
* the `xstartup` script that will run when the VNC server is launched

A bare bones object would be:

```ruby
session = OSC::VNC::Session.new(batch: 'oxymoron', cluster: 'oakley', xstartup: '/path/to/script')
```

In most cases we will want to supply more options for finer control of the
session:

```ruby
# Headers are the PBS headers you see at the top of a PBS batch job.
# They are defined similarly here accept the header argument
# is used as a key in the PBS::ATTR hash object
# e.g., for a PBS job name (#PBS -N MyVNCJob)
headers = { PBS::ATTR[:N] => "MyVNCJob" }

# Resources are the attributes in the PBS batch job given with `-l`.
# e.g., for walltime (#PBS -l walltime=24:00:00)
resources = { walltime: "24:00:00" }

# Environment variables can also be passed to the script
envvars = { DATAFILE: "/path/to/datafile" }

# It is also beneficial to define an output directory
outdir = "/output/path"

# Define our xstartup script
xstartup = "/path/to/script"

# We now create our session
session = OSC::VNC::Session.new(batch: 'oxymoron', cluster: 'oakley',
    xstartup: xstartup, outdir: outdir, headers: headers, resources: resources,
    envvars: envvars)
```

To submit the VNC session, use the `#run` instance method on the object:

```ruby
session.run
```

After enough time has passed and the session is runninq in the batch system
(i.e., not queued) there are a variety of formats to output the connection
information. The most user-friendly being the `*.jnlp` format if the user has
Java installed:

```ruby
conn_info = OSC::VNC::ConnView.new(session: session)
conn_info.to_jnlp
```

### VNC Server options

You can specify different options when running a vnc session. When choosing the
batch system to submit the job to `compute` vs `oxymoron`, a default set of
options found in [config/script.yml](config/script.yml) are applied to your job. When
choosing a cluster `Glenn`, `Oakley`, or `Ruby` the cluster specific set of
default options are located in `osc-vnc/config/script-cluster.yml`.

You can alter these options when creating a session by specifying them as a
hash in the `:options` key when initializing the object. An example:

```ruby
...

# Specify your personal VNC session options to override defaults
options = {
    :geom => '1920x1200',
    :'otp?' => false,
    :'vncauth?' => true,
    :'ssh_tunnel?' => true
  }


# We now create our session, note that we now append an `options` parameter
session = OSC::VNC::Session.new(batch: 'oxymoron', cluster: 'oakley',
    xstartup: xstartup, outdir: outdir, headers: headers, resources: resources,
    envvars: envvars, options: options)
```

### xstartup

An `xstartup` script is treated like any other bash script that launches the
application you want. If no environment variables are needed, it could
theoretically be run directly on an OSC desktop session by itself.

One such example would be launching Paraview:

```bash
#!/bin/bash

# This loads up any Xresources the user specifies
# as well as gives the background a nice grey color
if [ -e $HOME/.Xresources  ]; then
  xrdb $HOME/.Xresources
fi
xsetroot -solid grey

# We need a window manager otherwise the windows will
# look horrendous, for this we use FVWM (please refer to
# FillSim for an example of the `fvwmrc` file used)
XDIR=${XSTARTUP_DIR} /usr/bin/fvwm -f ${XSTARTUP_DIR}/fvwm/fvwmrc &

# Load the required modules on Oakley
. /etc/profile.d/lmod.sh
module load paraview/3.14.1

# If we are running this app on a node with an Xorg server running
# i.e., there is a GPU on this node that we can utilize for OpenGL
# graphics (which is true for the Oxymoron cluster)
module load virtualgl/2.3

# Now we start the application
vglrun paraview

# Be sure to clean up the VNC server after the user exits the above
# running process
vncserver -kill ${DISPLAY}
```

You may or may not need VirtualGL depending on the type of application. Be sure
to only use it on a node with an Xorg server running. For any other node you
should omit it and its binary `vglrun`.

You can find a very generic example of an `fvwmrc` file in the
`containerfillsim` GitHub repo under the path:

```bash
containerfillsim/jobs/vnc/paraview/fvwm/fvwmrc
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
