module NewRelicAWS
  module Collectors
    class KINESIS < Base
      def stream_names
        kinesis = Aws::Kinesis::Client.new(
          :access_key_id => @aws_access_key,
          :secret_access_key => @aws_secret_key,
          :region => @aws_region
        )
        kinesis.list_streams.stream_names.each{|stream| NewRelic::PlatformLogger.info(stream)}
        kinesis.list_streams.stream_names.map { |stream| stream }
      end
      
      def metric_list
        [
          ["IncomingBytes", "Sum", "Bytes"],
          ["IncomingRecords", "Sum", "Count"],
          ["OutgoingBytes", "Sum", "Bytes"],
          ["OutgoingRecords", "Sum", "Count"]
        ]
      end

      def collect
        data_points = []
        stream_names.each do |stream_name|
          metric_list.each do |(metric_name, statistic, unit)|
            period = 300
            time_offset = 600 + @cloudwatch_delay
            data_point = get_data_point(
              :namespace   => "AWS/Kinesis",
              :metric_name => metric_name,
              :statistic   => statistic,
              :unit        => unit,
              :dimension   => {
                :name  => "StreamName",
                :value => stream_name
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
