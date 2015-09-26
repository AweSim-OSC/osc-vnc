require 'osc/vnc/listenable'

module OSC
  module VNC
    # Provides a way for developers to create and submit VNC sessions to the
    # OSC batch systems. Also, developers are now able to submit any server
    # session to the batch systems whether it is VNC or not following the same
    # principles as a VNC session.
    class Session
      include OSC::VNC::Listenable

      # @return [PBS::Job] The job object used.
      attr_reader :job

      # @return [ScriptView] The batch script used.
      attr_reader :script

      # @param [PBS::Job] The job object used.
      # @param [ScriptView] The batch script used.
      # @param opts [Hash] The options used to construct a session.
      def initialize(job, script, opts = {})
        @job = job
        @script = script
      end

      # Submit the VNC job to the defined batch server.
      #
      # @return [Session] the session object
      def submit(opts = {})
        script.valid? # check if script is valid (can raise errors here)

        # Create tcp listen server if requested
        listen_server = _create_listen_server if script.tcp_server?

        job.submit(
          string: script.render,
          headers: _get_headers(opts[:headers] || {}),
          resources: _get_resources(opts[:resources] || {}),
          envvars: _get_envvars(opts[:envvars] || {}),
          qsub: true
        )

        _write_listen_conn_info(listen_server) if script.tcp_server?

        self
      end

      # The connection information file.
      #
      # @return [String] path to connection information file for this session
      def conn_file
        "#{script.outdir}/#{job.id}.conn"
      end


      private

      # The hash of PBS header attributes for the job.
      def _get_headers(headers)
        h = {
          PBS::ATTR[:N] => "VNC_Job",
          PBS::ATTR[:o] => "#{script.outdir}/$PBS_JOBID.output",
          PBS::ATTR[:j] => "oe",
          PBS::ATTR[:S] => "/bin/bash",
        }.merge headers
        h[PBS::ATTR[:N]] = "#{ENV['APP_TOKEN']}/#{h[PBS::ATTR[:N]]}" if ENV['APP_TOKEN']
        h
      end

      # The hash of PBS resources requested for the job.
      def _get_resources(resources)
        {
          :nodes => "1:ppn=1:#{script.cluster}",
          :walltime => "24:00:00",
        }.merge resources
      end

      # The hash of environment variables passed to the job.
      def _get_envvars(envvars)
        {
        }.merge envvars
      end

      # Create a tcp listen server and set appropriate environment variables.
      # for batch script to phone home
      def _create_listen_server
        listen_server = create_listen
        _, port, host, _ = listen_server.addr(:hostname)
        @envvars.merge! LISTEN_HOST: host, LISTEN_PORT: port
        listen_server
      end

      # Write connection information from a TCP listening server.
      def _write_listen_conn_info(server)
        # Wait until VNC conn info is created by PBS batch script
        # Timeout after 60 seconds if no info is sent
        Timeout::timeout(60) do
          File.open(conn_file, 'w', 0600) { |f| f.puts read_listen(server: server) }
        end
      end
    end
  end
end
