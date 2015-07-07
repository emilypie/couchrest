#
# CouchRest Exception Handling
#
# Restricted set of HTTP error response we'd expect from a CouchDB server. If we don't have a specific error handler,
# a generic Exception will be returned with the #http_code attribute set.
#
# Implementation based on [rest-client exception handling](https://github.com/rest-client/rest-client/blob/master/lib/restclient/exceptions.rb).
#
# In general, exceptions in the `CouchRest` scope are only generated by the couchrest library,
# exceptions generated by other libraries will not be re-mapped.
#
module CouchRest

 STATUSES = {
              200 => 'OK',
              201 => 'Created',
              202 => 'Accepted',

              304 => 'Not Modified',

              400 => 'Bad Request',
              401 => 'Unauthorized',
              403 => 'Forbidden',
              404 => 'Not Found',
              405 => 'Method Not Allowed',
              406 => 'Not Acceptable',
              409 => 'Conflict',
              412 => 'Precondition Failed',
              415 => 'Unsupported Media Type',
              416 => 'Requested Range Not Satisfiable',
              417 => 'Expectation Failed',

              500 => 'Internal Server Error',
  } 

  # This is the base CouchRest exception class. Rescue it if you want to
  # catch any exception that your request might raise.
  # You can get the status code by e.http_code, or see anything about the
  # response via e.response.
  # For example, the entire result body (which is
  # probably an HTML error page) is e.response.
  class Exception < RuntimeError
    attr_accessor :response
    attr_writer :message

    def initialize response = nil
      @response = response
      @message = nil
    end

    def http_code
      # return integer for compatibility
      @response.code.to_i if @response
    end

    def http_headers
      @response.headers if @response
    end

    def http_body
      @response.body if @response
    end

    def inspect
      "#{message}: #{http_body}"
    end

    def to_s
      inspect
    end

    def message
      @message || self.class.default_message
    end

    def self.default_message
      self.name
    end
  end

  # The request failed with an error code not managed by the code
  class RequestFailed < Exception
    def message
      "HTTP status code #{http_code}"
    end

    def to_s
      message
    end
  end

  module Exceptions
    EXCEPTIONS_MAP = {}
  end

  STATUSES.each_pair do |code, message|
    klass = Class.new(RequestFailed) do
      send(:define_method, :message) {"#{http_code ? "#{http_code} " : ''}#{message}"}
    end
    klass_constant = const_set message.delete(' \-\''), klass
    Exceptions::EXCEPTIONS_MAP[code] = klass_constant
  end

  # Error handler for broken connections, mainly used by streamer
  class ServerBrokeConnection < ::Exception
  end

end
