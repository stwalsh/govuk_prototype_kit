module SmartAnswer
  module Question
    class MultipleChoice < Base
      attr_reader :permitted_options

      def initialize(flow, name, &block)
        @permitted_options = []
        super
      end

      def option(option_key)
        @permitted_options << option_key.to_s
      end

      def options
        @permitted_options
      end

      def valid_option?(option)
        options.include?(option.to_s)
      end

      def parse_input(raw_input)
        raise SmartAnswer::InvalidResponse, "Illegal option #{raw_input} for #{name}", caller unless valid_option?(raw_input)
        super
      end
    end
  end
end
