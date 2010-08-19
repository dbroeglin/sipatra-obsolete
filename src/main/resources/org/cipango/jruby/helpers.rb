module Sipatra
  module HelperMethods  
    def proxy(uri = nil)
      uri = uri.nil? ? request.requestURI : sip_factory.createURI(uri)
      request.getProxy().proxyTo(uri)
    end    
    
    def header
      @header_wrapper ||= HeadersWrapper::new(self)
    end

    def headers
      @headers_wrapper ||= HeadersWrapper::new(self, true)
    end

    def address_header
      @address_header_wrapper ||= HeadersWrapper::new(self, false, true)
    end

    def address_headers
      @address_headers_wrapper ||= HeadersWrapper::new(self, true, true)
    end
    
    def header?(name)
      !request.getHeader(name.to_s).nil?
    end
    
    def send_response(status, *args)
      create_args = [convert_status_code(status)]
      create_args << args.shift unless args.empty? || args.first.kind_of?(Hash)
      response = request.createResponse(*create_args)
      unless args.empty?
        raise ArgumentError, "last argument should be a Hash" unless args.first.kind_of? Hash
        args.first.each_pair do |name, value|
          response.addHeader(name.to_s, value.to_s)
        end
      end
      if block_given?
        yield response
      end
      response.send
    end
    
    def create_address(addr, options = {})
      addr = addr.to_s # TODO: Handle URI instances
      address = sip_factory.createAddress(addr)
      address.setExpires(options[:expires]) if options.has_key? :expires
      address.setDisplayName(options[:display_name]) if options.has_key? :display_name
      
      address      
    end
    
    private
    
    def convert_status_code(symbol_or_int)
      case symbol_or_int
      when Integer: return symbol_or_int
      when Symbol
        begin
          SipServletResponse.class_eval("SC_#{symbol_or_int.to_s.upcase}")
        rescue NameError => e
          raise ArgumentError, "Unknown status code symbol: '#{symbol_or_int}' (#{e.message})"
        end
      else
        raise ArgumentError, "Status code value should be a Symbol or Int not '#{symbol_or_int.class}'"
      end
    end
  end
end