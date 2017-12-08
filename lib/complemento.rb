module CFDI

  # Un complemento fiscal, o Timbre
  class Complemento < ElementoComprobante
    
    # los datos del timbre
    @cadenaOriginal = [:Version, :UUID, :FechaTimbrado, :RfcProvCertif, :Leyenda, :SelloCFD, :NoCertificadoSAT, :selloSAT, :version]
    attr_accessor *@cadenaOriginal
    
    # Regresa la cadena Original del Timbre Fiscal Digital del SAT
    #
    # @return [String] la cadena formada
    def cadena
      return "||#{Version}|#{@UUID}|#{@FechaTimbrado}|#{RfcProvCertif}|#{Leyenda}|#{SelloCFD}|#{NoCertificadoSAT}||"
    end
    
  end

end