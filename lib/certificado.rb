module CFDI
  
  require 'openssl'
  
  class Certificado < OpenSSL::X509::Certificate
    
    attr_reader :NoCertificado
    attr_reader :data

    def initialize (file)
      if file.is_a? String
        file = File.read(file)
      end
            
      super file
      
      @NoCertificado = '';
      self.serial.to_s(16).scan(/.{2}/).each {|v| @NoCertificado << v[1]; }
      @data = self.to_s.gsub(/^-.+/, '').gsub(/\n/, '')
    end
    
    def certifica factura
      factura.NoCertificado = @NoCertificado
      factura.Certificado = @data
    end
  
    def no_certificado
      @NoCertificado
    end
  
    def certificado
      @data
    end
  
    def issuername
        
      @a = nil  
      @b = nil  
      @c = nil  
      @d = nil  
      @e = nil  
      @f = nil  
      @g = nil  
      @h = nil  
      @i = nil  
      @j = nil  
      @k = nil  
        
      self.issuer.to_a.each do |array|

        if array[0] == "unstructuredName"
          @a = "OID.1.2.840.113549.1.9.2=#{array[1]}, "
        end

        if array[0] == "x500UniqueIdentifier"
          @b = "OID.2.5.4.45=#{array[1]}, "
        end

        if array[0] == "L"
          @c = "L=#{array[1]}, "
        end

        if array[0] == "ST"
          @d = "S=#{array[1]}, "
        end
  
        if array[0] == "C"
          @e = "C=#{array[1]}, "
        end
  
        if array[0] == "postalCode"
          @f = "PostalCode=#{array[1]}, "
        end
  
        if array[0] == "street"
          @g = "STREET=#{array[1]}, "
        end

        if array[0] == "emailAddress"
          @h = "E=#{array[1]}, "
        end
  
        if array[0] == "OU"
          @i = "OU=#{array[1]}, "
        end
  
        if array[0] == "O"
          @j = "O=#{array[1]}, "
        end
  
        if array[0] == "CN"
          @k = "CN=#{array[1]}"
        end
  
      end

      return "#{@a}#{@b}#{@c}#{@d}#{@e}#{@f}#{@g}#{@h}#{@i}#{@j}#{@k}"
      
    end
        
  end
  
end