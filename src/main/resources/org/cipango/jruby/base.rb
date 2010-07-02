
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
      attr_reader :handlers
    
      private
      
      def reset!
        @handlers         = {}
      end
    
      public
        def invite(path, opts = {}, &block) 
          handler('INVITE', path, opts, &block)
        end
        
      private
      
        def compile_uri_pattern(uri)
          keys = [] # TODO: Not yet used, shall contain key names
          if uri.respond_to? :to_str
            [/^#{uri}$/, keys]
          elsif uri.respond_to? :match
            [uri, keys]
          else
            raise TypeError, uri
          end
        end
      
        def handler(verb, uri, options={}, &block)
          puts "Recording handler for #{verb} in #{name}"

          define_method "#{verb} #{uri}", &block
          unbound_method = instance_method("#{verb} #{uri}")
          block =
            if block.arity != 0
              proc { unbound_method.bind(self).call(*@block_params) }
            else
              proc { unbound_method.bind(self).call }
            end
  
          pattern, keys = compile_uri_pattern(uri)
          ((@handlers ||= {})[verb] ||= []).
            push([pattern, keys, nil, block]).last # TODO: conditions
          
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
      puts "DO REQUEST: #{request.getMethod()} #{request.getRequestURI()}"
      puts "#{self.class.handlers.inspect}"
      if handlers = self.class.handlers[request.getMethod()]
        handlers.each { |pattern, keys, conditions, block|
          puts "PATTERN: #{pattern}"
          if pattern.match request.getRequestURI.toString
            # TODO: use keys and conditions
            instance_eval(&block)          
            break
          end
        }
      end
      
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