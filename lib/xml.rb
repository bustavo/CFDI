module CFDI

  def self.from_xml(data)
    xml = Nokogiri::XML(data);
    xml.remove_namespaces!
    factura = Comprobante.new
    
    comprobante = xml.at_xpath('//Comprobante')
    emisor = xml.at_xpath('//Emisor')
    de = emisor.at_xpath('//DomicilioFiscal')
    exp = emisor.at_xpath('//LugarExpedicion')
    receptor = xml.at_xpath('//Receptor')
    dr = receptor.at_xpath('//Domicilio')
    cr = xml.at_xpath('//CfdiRelacionados')
    
    factura.version = comprobante.attr('Version')
    factura.serie = comprobante.attr('Serie')
    factura.folio = comprobante.attr('Folio')
    factura.fecha = Time.parse(comprobante.attr('Fecha'))
    factura.NoCertificado = comprobante.attr('NoCertificado')
    factura.certificado = comprobante.attr('Certificado')
    factura.sello = comprobante.attr('Sello')
    factura.formaDePago = comprobante.attr('FormaPago')
    factura.condicionesDePago = comprobante.attr('CondicionesDePago')
    factura.tipoDeComprobante = comprobante.attr('TipoDeComprobante')
    factura.lugarExpedicion = comprobante.attr('LugarExpedicion')
    factura.metodoDePago = comprobante.attr('MetodoPago')
    factura.moneda = comprobante.attr('Moneda')
        
    rf = emisor.at_xpath('//RegimenFiscal')

    emisor = {
      :Rfc => emisor.attr('Rfc'),
      :Nombre => emisor.attr('Nombre'),
      :RegimenFiscal => rf  && rf.attr('RegimenFiscal'),
      :LugarExpedicion => emisor.attr('LugarExpedicion')
    }
    
    factura.emisor = emisor;
    
    factura.receptor = {
      :Rfc => receptor.attr('Rfc'),
      :UsoCFDI => receptor.attr('UsoCFDI')
    }
        
    factura.conceptos = []
    xml.xpath('//Concepto').each do |concepto|
      total = concepto.attr('importe').to_f
      hash = {
        :NoIdentificacion => concepto.attr('NoIdentificacion'),
        :ClaveProdSer => concepto.attr('ClaveProdSer'),
        :Cantidad => concepto.attr('Cantidad').to_f,
        :ClaveUnidad => concepto.attr('ClaveUnidad'),
        :Descripcion => concepto.attr('Descripcion'),
        :ValorUnitario => concepto.attr('ValorUnitario').to_f,
        :Importe => concepto.attr('Importe').to_f
      }
      factura.conceptos << Concepto.new(hash)
    end
        
    timbre = xml.at_xpath('//TimbreFiscalDigital')

    if timbre
      version = timbre.attr('version');
      uuid = timbre.attr('UUID')
      fecha = timbre.attr('FechaTimbrado')
      sello = timbre.attr('selloCFD')
      certificado = timbre.attr('noCertificadoSAT')
      factura.complemento = {
        :UUID => uuid,
        :selloCFD => sello,
        :FechaTimbrado => fecha,
        :noCertificadoSAT => certificado,
        :version => version,
        :selloSAT => timbre.attr('selloSAT')
      }
    end

    factura.impuestos << {:Impuesto => '002'}
    
    factura
    
  end
  
end