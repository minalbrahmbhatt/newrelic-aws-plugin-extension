module NewRelicAWS
  module Collectors
    class REDSHIFT < Base
      def cluster_identifiers
        redshift = Aws::Redshift::Client.new(
          :access_key_id => @aws_access_key,
          :secret_access_key => @aws_secret_key,
          :region => @aws_region
        )
        redshift.describe_clusters.clusters.map {|cluster| NewRelic::PlatformLogger.debug(cluster.cluster_identifier) }
        redshift.describe_clusters.clusters.map {|cluster| cluster.cluster_identifier }
      end
      
      def metric_list
        [
          ["WriteThroughput", "Average", "Bytes"],
          ["DatabaseConnections", "Average","Count"]
        ]
      end

      def collect
        data_points = []
        cluster_identifiers.each do |cluster_identifier|
          metric_list.each do |(metric_name, statistic, unit)|
            period = 300
            time_offset = 600 + @cloudwatch_delay
            data_point = get_data_point(
              :namespace   => "AWS/Redshift",
              :metric_name => metric_name,
              :statistic   => statistic,
              :unit        => unit,
              :dimension   => {
                :name  => "ClusterIdentifier",
                :value => cluster_identifier
              },
              :period => period,
              :start_time => (Time.now.utc - (time_offset + period)).iso8601,
              :end_time => (Time.now.utc - time_offset).iso8601
            )
            NewRelic::PlatformLogger.debug("metric_name: #{metric_name}, statistic: #{statistic}, unit: #{unit}, response: #{data_point.inspect}")
            unless data_point.nil?
              data_points << data_point
            end
          end
        end
        data_points
      end

    end
  end
end
