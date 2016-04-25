module NewRelicAWS
  module Collectors
    class LAMBDA < Base
      def function_names
        lambda = Aws::Lambda::Client.new(
          :access_key_id => @aws_access_key,
          :secret_access_key => @aws_secret_key,
          :region => @aws_region
        )
        lambda.list_functions.functions.each{|function| NewRelic::PlatformLogger.info(function.function_name)}
        lambda.list_functions.functions.map {|function| function.function_name }
      end
      
      def metric_list
        [
          ["Invocations", "Sum", "Count"],
          ["Errors", "Sum", "Count"],
          ["Throttles", "Sum", "Count"],
          ["Duration", "Average", "Milliseconds"]
        ]
      end

      def collect
        data_points = []
        function_names.each do |function_name|
          metric_list.each do |(metric_name, statistic, unit)|
            period = 300
            time_offset = 600 + @cloudwatch_delay
            data_point = get_data_point(
              :namespace   => "AWS/Lambda",
              :metric_name => metric_name,
              :statistic   => statistic,
              :unit        => unit,
              :dimension   => {
                :name  => "FunctionName",
                :value => function_name
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
