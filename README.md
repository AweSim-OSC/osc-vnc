# OSC::VNC

Ruby library that provides VNC job submission to the OSC systems.

## Usage

Add this gem to your Gemfile:

    gem 'osc-vnc'

Run Bundler to update your gems:

    $ bundle install --local

## Examples

### Run App on Oxymoron Batch System

For all cases we will need to create a new VNC session object. To create a VNC
session object you need to supply it the required information:

* the batch system you will submit it to
* the cluster it will run on
* the `xstartup` script that will run when the VNC server is launched

A bare bones object would be:

    session = OSC::VNC::Session.new batch: 'oxymoron', cluster: 'oakley', xstartup: '/path/to/script'

In most cases we will want to supply more options for finer control of the
session:

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

To submit the VNC session, use the `#run` instance method on the object:

    session.run

After enough time has passed and the session is runninq in the batch system
(i.e., not queued) there are a variety of formats to output the connection
information. The most user-friendly being the `*.jnlp` format if the user has
Java installed:

    conn_info = OSC::VNC::ConnView.new(session: session)
    conn_info.to_jnlp

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
