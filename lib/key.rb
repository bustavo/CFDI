module CFDI
  
  require 'openssl'
  
  class Key < OpenSSL::PKey::RSA

    def initialize file, password=nil
      if file.is_a? String
        file = File.read(file)
      end
      super file, password
    end
    
    def sella factura
      cadena_original = factura.cadena_original
      factura.Sello = Base64::encode64(self.sign(OpenSSL::Digest::SHA256.new, cadena_original)).gsub(/\n/, '')
    end
    
  end
  
end