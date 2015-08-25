require 'yaml'

module OSC
  module VNC
    # Allows developers to choose and easily modify the batch server they
    # submit their VNC session to. This is inherited from <tt>PBS::Batch</tt>
    # to provide a superset of attributes required by <tt>OSC::VNC</tt>.
    class Batch < PBS::Batch
      # Initialize the batch server.
      #
      # @param [Hash] args the arguments to construct the connection
      # @option args [String] :name the batch to connect to (see pbs-ruby/config/batch.yml)
      # @option args [String] :batch_type the type of batch server ('compute', 'shared') (see config/batch.yml)
      # @option args [String] :cluster the cluster to run on (only needed if different than batch server) (see config/cluster.yml)
      # @option args [String] :fonts the fonts to use for the vnc server
      # @option args [String] :load_turbovnc bash command used to load turbovnc
      # @option args [Boolean] :multicluster is this batch a multi-cluster batch
      def initialize(args = {})
        super(args)

        batch_cfg = YAML.load_file("#{CONFIG_PATH}/batch.yml")
        @batch_config.merge! batch_cfg.fetch(name, {})

        cluster_cfg = YAML.load_file("#{CONFIG_PATH}/cluster.yml")
        @batch_config.merge! cluster_cfg.fetch(cluster, {})
      end

      # The cluster the session will run on. If not specified use the batch
      # name as the cluster.
      #
      # @return [String] name of the cluster session will run on
      def cluster
        @batch_config[:cluster] || name
      end

      # The fonts to use for the vnc server.
      #
      # @return [String] comma delimited list of fonts
      def fonts
        @batch_config[:fonts]
      end

      # The bash command to load the turbovnc module.
      #
      # @return [String] bash command for loading turbovnc module
      def load_turbovnc
        @batch_config[:load_turbovnc]
      end

      # Whether this batch server runs jobs on shared nodes.
      #
      # @return [Boolean] whether we will run on a shared node
      def shared?
        @batch_config[:batch_type] == 'shared'
      end

      # Whether this batch server has multiple clusters to choose from.
      #
      # @return [Boolean] whether we can choose the cluster
      def multicluster?
        @batch_config[:multicluster] == true
      end
    end
  end
end
