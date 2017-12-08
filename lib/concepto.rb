module CFDI

  class Concepto < ElementoComprobante
    
    @cadenaOriginal = [:NoIdentificacion, :ClaveProdSer, :Cantidad, :ClaveUnidad, :Descripcion, :ValorUnitario, :Importe]
    attr_accessor *@cadenaOriginal

    def cadena_original
      return [
        @NoIdentificacion,
        @ClaveProdSer,
        @Cantidad,
        @ClaveUnidad,
        @Descripcion,
        self.ValorUnitario,
        self.Importe
      ]
    end
        
    def descripcion= descripcion
      @Descripcion = descripcion.strip
      @Descripcion
    end

    def valorUnitario= dineros
      @ValorUnitario = dineros.to_f
      @ValorUnitario
    end

    def importe
      return @ValorUnitario*@Cantidad
    end

    def cantidad= qty
      @Cantidad = qty.to_i
      @Cantidad
    end
    
  end

end