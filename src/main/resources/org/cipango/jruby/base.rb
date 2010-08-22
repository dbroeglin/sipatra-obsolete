require 'java'
require 'org/cipango/jruby/helpers'

module Sipatra
  VERSION = '1.0.0'

  java_import javax.servlet.sip.SipServletResponse

  class Base
    include HelperMethods
    attr_accessor :sip_factory, :context, :session, :request, :response, :params

    def do_request
      puts "DO REQUEST: #{request.method} #{request.requestURI}"
      if handlers = self.class.handlers[request.method]
        handlers.each { |pattern, keys, conditions, block|
          #puts "PATTERN: #{pattern.source} / #{request.requestURI.to_s}"
          if pattern.match request.requestURI.to_s
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
  
      # permits configuration of the application
      def configure(*envs, &block)
        yield self if envs.empty? || envs.include?(environment.to_sym)
      end
  
      private
      
      def reset!
        @handlers         = {}
      end
        
      # compiles a URI pattern
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

      # adds a handler
      def handler(verb, uri, options={}, &block)
        method_name = "#{verb}  \"#{uri.kind_of?(Regexp) ? uri.source : uri}\""
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

      [:ack, :bye, :cancel, :info, :invite, :message, 
       :notify, :options, :prack, :publish, :refer, 
       :register, :subscribe, :update].each do |name|
        define_method name do |*args, &block|
          path, opts = *args
          handler(name.to_s.upcase, path || //, opts || {}, &block)
        end
      end

    end
    
    reset!
  end
  
  class Application < Base    
    def self.register(*extensions, &block) #:nodoc:
      added_methods = extensions.map {|m| m.public_instance_methods }.flatten
      Delegator.delegate(*added_methods)
      super(*extensions, &block)
    end
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