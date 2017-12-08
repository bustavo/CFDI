module CFDI
  
  class Entidad < ElementoComprobante

    @cadenaOriginal = [:Rfc, :Nombre, :RegimenFiscal, :UsoCFDI]
    @data = @cadenaOriginal
    attr_accessor *@cadenaOriginal
    
    def cadena_original
      return [
        @Rfc,
        @Nombre,
        @RegimenFiscal,
        @UsoCFDI
      ].flatten
    end

    def em
      return ({
        :Nombre => @Nombre,
        :Rfc => @Rfc,
        :RegimenFiscal => @RegimenFiscal
      })
    end
        
    def re
      return ({
        :Rfc => @Rfc,
        :UsoCFDI => @UsoCFDI
      })
    end
    
  end
  
end