require 'http_sim/recorded_request'
require 'http_sim/matchers/base_matcher'

module HttpSim
  module Matchers
    class StaticRequestMatcher < BaseMatcher
      attr_reader :http_method, :route, :headers, :response_code, :matcher, :response_body, :default, :schema

      def initialize(http_method:, route:, response_code: 200, response_body: '', headers: {}, default: false, matcher: ALWAYS_TRUE_MATCHER, schema: nil)
        @default = default
        @matcher = matcher
        @headers = headers
        @response_body = response_body
        @response_code = response_code
        @route = route
        @http_method = http_method
        @schema = schema
      end

      def matches?(request)
        request.path == route && request.request_method == http_method && matcher.call(request)
      end

      def custom_matcher?
        matcher != ALWAYS_TRUE_MATCHER
      end

      def overridden!
        @overridden = true
      end

      def overridden?
        !!@overridden
      end

      def reset!
        @overridden = false
      end

      def requests
        @requests ||= []
      end

      def record_request(request)
        request.body.rewind
        requests.push(RecordedRequest.new(body: request.body.read, request_env: request.env))
      end
    end
  end
end