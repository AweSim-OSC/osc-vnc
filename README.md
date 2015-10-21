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

* a `PBS::Job` object that connects to the specified batch server
* the PBS script that will run when the job is submitted, defined by
  * type of script (`:vnc` or `:server`)
    * `:vnc` launches a VNC server
    * `:server` doesn't launch a VNC server (expects developer specified server in `xstartup`)
  * cluster type (`:glenn`, `:oakley`, `:ruby`), not to be confused with the
    batch server (i.e., `quick-batch` can use `:oakley` or `:ruby`)

A bare bones setup would be:

```ruby
job = PBS::Job.new(conn: PBS::Conn.batch('quick'))
script = OSC::VNC::ScriptView.new(:vnc, 'oakley', xstartup: '/path/to/script', outdir: ENV['PWD'])

session = OSC::VNC::Session.new(job, script)
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
```

To submit the VNC session, use the `#submit` instance method on the object:

```ruby
session.submit(headers: headers, resources: resources, envvars: envvars)
```

After enough time has passed and the session is runninq in the batch system
(i.e., not queued) there are a variety of formats to output the connection
information. The most user-friendly being the `*.jnlp` format if the user has
Java installed:

```ruby
conn_info = OSC::VNC::ConnView.new(session)
conn_info.render(:jnlp)
```

**Note:** Once someone successfully authenticates with the VNC server the
password will change if using `vncauth` form of authentication. So it is
imperative that you run `ConnView#refresh` to update the connection
information.

### VNC Server options

You can specify different options when running a vnc session. You can use the
`default` set of VNC options to submit the job with or choose from pre-defined
subtypes (i.e., `:shared`) found in [config/script.yml](config/script.yml).

You can alter these options when creating a session by specifying them as a
hash in the when initializing the `ScriptView` object. An example:

```ruby
# Specify your personal VNC session options to override defaults
script = OSC::VNC::ScriptView.new(
  :vnc,
  'oakley',
  :geom => '1920x1200',
  :'otp?' => false,
  :'vncauth?' => true,
  :'ssh_tunnel?' => true
)
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
export XSTARTUP_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
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
