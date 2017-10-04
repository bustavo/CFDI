module CFDI
  
  require 'openssl'
  
  # Certificados en formato X590
  # 
  # En español, el archivo `.cer`
  class Certificado < OpenSSL::X509::Certificate
    
    # el número de certificado
    attr_reader :noCertificado
    # el certificado en Base64
    attr_reader :data

    # Importar un certificado de sellado
    # @param  file [IO, String] El `path` del certificado o un objeto #IO
    # 
    # @return [CFDI::Certificado] Un certificado
    def initialize (file)
      
      if file.is_a? String
        file = File.read(file)
      end
            
      super file
      
      @noCertificado = '';
      # Normalmente son strings de tipo:
      # 3230303031303030303030323030303030323933
      # por eso sólo tomamos cada segundo dígito
      self.serial.to_s(16).scan(/.{2}/).each {|v| @noCertificado << v[1]; }
      #self.serial.to_s(16).scan(/.{2}/).each {|v| @noCertificado += v[1]; }
      @data = self.to_s.gsub(/^-.+/, '').gsub(/\n/, '')
      
    end
    

    # Certifica una factura
    # @param  factura [CFDI::Comprobante] El comprobante a certificar
    # 
    # @return [CFDI::Comprobante] El comprobante certificado (con `#noCertificado` y `#certificado`)
    def certifica factura
      
      factura.noCertificado = @noCertificado
      factura.certificado = @data
      
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