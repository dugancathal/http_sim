require 'http_sim/recorded_request'
require 'http_sim/matchers/base_matcher'

module HttpSim
  module Matchers
    class RequestBodyMatcher < BaseMatcher
      attr_reader :http_method, :route, :headers, :response_code, :matcher, :response_body, :default

      def initialize(http_method:, route:, response_code: 200, response_body: '', headers: {}, default: false, body_matches:)
        @default = default
        @matcher = Regexp.compile(body_matches)
        @headers = headers
        @response_body = response_body
        @response_code = response_code
        @route = route
        @http_method = http_method
      end

      def matches?(request)
        request.body.rewind
        body = request.body.read
        request.body.rewind
        request.path == route && request.request_method == http_method && matcher.match(body)
      end
    end
  end
end