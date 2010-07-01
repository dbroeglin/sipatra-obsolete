#def request
#   @request
#end
#
#def response
#   @response
#end
#
#def sipFactory
#  @sipFactory
#end
#
#def session
#  @session
#end
#
#def params
#  @params
#end
#
#
#def sendResponse(status, reason = nil) 
#  if reason.nil?
#    request.createResponse(status).send()
#  else 
#    request.createResponse(status, reason).send()
#  end
#end
#
#def pushRoute(route)
#  request.pushRoute(sipFactory.createAddress(route))
#end

require 'java'

module Sipatra
  VERSION = '1.0.0'
  
#  include_class 'javax.servlet.sip.SipServletRequest'
#  include_class 'javax.servlet.sip.SipServletResponse'
#    
#  class Request < SipServletRequest
#  end 
#
#  class Response < SipServletResponse
#  end 

  class Base

    class << self
      attr_reader :routes
    
      private
      
      def reset!
        @routes         = {}
      end
    
      public
        def invite(path, opts = {}, &block) 
          route('INVITE', path, opts, &block)
        end
      private
        def route(verb, path, options={}, &block)
          puts "Recording #{verb} in #{name}"

          define_method "#{verb} #{path}", &block
          unbound_method = instance_method("#{verb} #{path}")
          block =
            if block.arity != 0
              proc { unbound_method.bind(self).call(*@block_params) }
            else
              proc { unbound_method.bind(self).call }
            end
  
          pattern = verb # TODO: construct a real pattern
          ((@routes ||= {})[verb] ||= []).
            push([pattern, block]).last
          
        end        
    end
    
    reset!    
  end
  
  class Application < Base
    attr_accessor :sipFactory, :context, :session, :request, :response, :params
    
    def self.register(*extensions, &block) #:nodoc:
      added_methods = extensions.map {|m| m.public_instance_methods }.flatten
      Delegator.delegate(*added_methods)
      super(*extensions, &block)
    end
    
    def do_request
      puts "DO REQUEST #{request.inspect} #{request.getMethod()}"
      puts "#{self.class.routes.inspect}"
      handlers = self.class.routes[request.getMethod()]
      handler = handlers.first
      
      instance_eval(&handler[1])
    end
    
    def do_response
      puts "DO RESPONSE"
    end
    
    def proxy(uri = nil)
      uri = uri.nil? ? request.getRequestURI() : sipFactory.createURI(uri)
      request.getProxy().proxyTo(uri)
    end    
    
    #def sendResponse(status, reason = nil) 
    #  if reason.nil?
    #    request.createResponse(status).send()
    #  else 
    #    request.createResponse(status, reason).send()
    #  end
    #end
    #
    #def pushRoute(route)
    #  request.pushRoute(sipFactory.createAddress(route))
    #end
  end
  
  module Delegator #:nodoc:
    def self.delegate(*methods)
      methods.each do |method_name|
        eval <<-RUBY, binding, '(__DELEGATE__)', 1
          def #{method_name}(*args, &b)
            ::Sipatra::Application.send(#{method_name.inspect}, *args, &b)
          end
          private #{method_name.inspect}
        RUBY
      end
    end

    delegate :invite
  end
end

include Sipatra::Delegator