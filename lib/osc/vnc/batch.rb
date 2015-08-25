require 'yaml'

module OSC
  module VNC
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

      def cluster
        @batch_config[:cluster] || name
      end

      def fonts
        @batch_config[:fonts]
      end

      def load_turbovnc
        @batch_config[:load_turbovnc]
      end

      def shared?
        @batch_config[:batch_type] == 'shared'
      end

      def multicluster?
        @batch_config[:multicluster] == true
      end
    end
  end
end
