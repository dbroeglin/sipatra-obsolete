require 'java'

module Sipatra
  VERSION = '1.0.0'

  class Base
    def do_request
      puts "DO REQUEST: #{request.method} #{request.requestURI}"
      puts "#{self.class.handlers.inspect}"
      if handlers = self.class.handlers[request.method]
        handlers.each { |pattern, keys, conditions, block|
          puts "PATTERN: #{pattern}"
          if pattern.match request.requestURI.toString
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
    
    class << self
      attr_reader :handlers
  
      private
      
      def reset!
        @handlers         = {}
      end
        
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

        method_name = "#{verb}  #{uri}"
        define_method method_name, &block
        unbound_method = instance_method(method_name)
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
    
    eigenclass = (class << self; self; end)
     [:ack, :bye, :cancel, :info, :invite, :message, 
      :notify, :options, :prack, :publish, :refer, 
      :register, :subscribe, :update].each do |name|
      eigenclass.send :define_method, name do |*args, &block|
        path, opts = *args
        handler(name.to_s.upcase, path || //, opts || {}, &block)
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

    delegate :invite, :register
  end
end

include Sipatra::Delegator