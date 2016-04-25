module NewRelicAWS
  module Collectors
    class FIREHOSE < Base
      def delivery_stream_names
        firehose = Aws::Firehose::Client.new(
          :access_key_id => @aws_access_key,
          :secret_access_key => @aws_secret_key,
          :region => @aws_region
        )
        firehose.list_delivery_streams.delivery_stream_names.map { |delivery_stream_name| delivery_stream_name }
      end
      
      def metric_list
        [
          ["IncomingRecords", "Sum", "Count"],
          ["DeliveryToS3.Records", "Sum", "Count"],
          ["DeliveryToRedshift.Records", "Sum", "Count"]
        ]
      end

      def collect
        data_points = []
        delivery_stream_names.each do |delivery_stream_name|
          metric_list.each do |(metric_name, statistic, unit)|
            period = 300
            time_offset = 600 + @cloudwatch_delay
            data_point = get_data_point(
              :namespace   => "AWS/Firehose",
              :metric_name => metric_name,
              :statistic   => statistic,
              :unit        => unit,
              :dimension   => {
                :name  => "StreamName",
                :value => delivery_stream_name
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
