module CFDI
  # La clase principal para crear Comprobantes
  class Comprobante
  
    @@datosCadena = [:Version, :Fecha, :TipoDeComprobante, :FormaPago, :CondicionesDePago, :SubTotal, :Descuento, :TipoCambio, :Moneda, :Total, :MetodoPago, :LugarExpedicion, :NoCertificado, :Certificado, :Serie, :Folio, :Confirmacion]
    @@data = @@datosCadena+[:CfdiRelacionados, :Emisor, :Receptor, :Conceptos, :Impuestos, :Complemento, :Sello, :cancelada]
    attr_accessor *@@data
    
    @addenda = nil
  
    @@options = {
      :defaults => {
        :Moneda => 'MXN',
        :Version => '3.3',
        :SubTotal => 0.0,
        :TipoCambio => 1,
        :Conceptos => [],
        :Impuestos => [],
        :TipoDeComprobante => 'I',
        :tasa => 0.16
      }
    }
  
    def self.configure (options)
      @@options = Comprobante.rmerge @@options, options
      @@options
    end
  
    def initialize (data={}, options={})
      opts = Marshal::load(Marshal.dump(@@options))
      data = opts[:defaults].merge data
      @opciones = opts.merge options
      data.each do |k,v|
        method = "#{k}="
        next if !self.respond_to? method
        self.send method, v
      end
    end
    
    def addenda= addenda
      addenda = Addenda.new addenda unless addenda.is_a? Addenda
      @addenda = addenda
    end
  
    def subTotal
      ret = 0
      @Conceptos.each do |c|
        ret += c.Importe
      end
      ret
    end

    def total
      self.subTotal+(self.subTotal*0.16)
    end

    def emisor= emisor 
      emisor = Entidad.new emisor unless emisor.is_a? Entidad
      @Emisor = emisor;
    end

    def receptor= receptor 
      receptor = Entidad.new receptor unless receptor.is_a? Entidad
      @Receptor = receptor;
    end

    def conceptos= conceptos
      if conceptos.is_a? Array
        conceptos.map! do |concepto|
          concepto = Concepto.new concepto unless concepto.is_a? Concepto
        end
      elsif conceptos.is_a? Hash
        conceptos << Concepto.new(concepto)
      elsif conceptos.is_a? Concepto
        conceptos << conceptos
      end
      
      @conceptos = conceptos
      conceptos
    end
    
    def complemento= complemento
      complemento = Complemento.new complemento unless complemento.is_a? Complemento
      @complemento = complemento
      complemento
    end

    def fecha= fecha
      fecha = fecha.strftime('%FT%R:%S') unless fecha.is_a? String
      @fecha = fecha
    end

    def to_xml
      ns = {
        'xmlns:cfdi' => "http://www.sat.gob.mx/cfd/3",
        'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
        'xsi:schemaLocation' => "http://www.sat.gob.mx/cfd/3 http://www.sat.gob.mx/sitio_internet/cfd/3/cfdv33.xsd",
      }

      ns[:Version] = @Version
      ns[:Fecha] = @Fecha
      ns[:TipoDeComprobante] =  @TipoDeComprobante
      ns[:FormaPago] = @FormaPago
      ns[:CondicionesDePago] = @CondicionesDePago
      ns[:SubTotal] = self.subTotal
      ns[:Descuento] = @Descuento if @Descuento
      ns[:TipoCambio] = @TipoCambio if @TipoCambio
      ns[:Moneda] = @Moneda
      ns[:Total] = self.total
      ns[:MetodoPago] = @MetodoPago
      ns[:NoCertificado] = @NoCertificado if @NoCertificado
      ns[:Certificado] = @Certificado if @Certificado
      ns[:Serie] = @Serie if @Serie
      ns[:Folio] = @Folio
      ns[:Confirmacion] = @Confirmacion if @Confirmacion
      ns[:Sello] = @Sello if @Sello
      ns[:LugarExpedicion] = @LugarExpedicion if @LugarExpedicion
          
      if (@addenda)
        ns["xmlns:#{@addenda.Nombre}"] = @addenda.namespace
        ns['xsi:schemaLocation'] += ' '+[@addenda.namespace, @addenda.xsd].join(' ')
      end

      @@data = @@datosCadena+[:CfdiRelacionados, :Emisor, :Receptor, :Conceptos, :Impuestos, :Complemento, :Sello, :cancelada]

            
      @builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
        xml.Comprobante(ns) do
          ins = xml.doc.root.add_namespace_definition('cfdi', 'http://www.sat.gob.mx/cfd/3')
          xml.doc.root.namespace = ins
                  
          xml.Emisor(@Emisor.em)  {
          }
          xml.Receptor(@Receptor.re) {
          }
          xml.Conceptos {
            @Conceptos.each do |concepto|
              xml.Concepto(              
              :ClaveProdServ => concepto.ClaveProdSer, 
              :NoIdentificacion => concepto.NoIdentificacion,
              :Cantidad => concepto.Cantidad, 
              :ClaveUnidad => concepto.ClaveUnidad, 
              :Descripcion => concepto.Descripcion, 
              :ValorUnitario => concepto.ValorUnitario, 
              :Importe => concepto.Importe)
            end
          }
          xml.Impuestos({:TotalImpuestosTrasladados => self.subTotal*0.16}) {
            xml.Traslados {
              @Impuestos.each do |impuesto|
                 xml.Traslado({:Impuesto => impuesto[:Impuesto], :TipoFactor => impuesto[:TipoFactor], :TasaOCuota => impuesto[:TasaOCuota], :Importe => (self.subTotal*impuesto[:TasaOCuota].to_f).round(2)})
              end
            }
          }
          xml.Complemento {
            if @complemento
              nsTFD = {
                'xsi:schemaLocation' => 'http://www.sat.gob.mx/TimbreFiscalDigital http://www.sat.gob.mx/TimbreFiscalDigital/TimbreFiscalDigital.xsd',
                'xmlns:tfd' => 'http://www.sat.gob.mx/TimbreFiscalDigital',
                'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance'                
              }
              xml['tfd'].TimbreFiscalDigital(@complemento.to_h.merge nsTFD) {
              }
            end
          }
          
          if (@addenda)
            xml.Addenda {
              @addenda.data.each do |k,v|
                if v.is_a? Hash
                  xml[@addenda.Nombre].send(k, v)
                elsif v.is_a? Array
                  xml[@addenda.Nombre].send(k, v)
                else
                  xml[@addenda.Nombre].send(k, v)
                end
              end
            }
          end
          
        end
      end
      @builder.to_xml
    end

    def to_h
      hash = {}
      @@data.each do |key|
        data = deep_to_h send(key)
        hash[key] = data
      end
      
      return hash
    end
  
    def cadena_original
      doc = Nokogiri::XML(self.to_xml)
      spec = Gem::Specification.find_by_name("cfdi")
      xslt = Nokogiri::XSLT(File.read(spec.gem_dir + "/lib/cadenaoriginal_3_3.xslt"))
      
      return xslt.transform(doc)
    end
  
    def self.rmerge defaults, other_hash
      result = defaults.merge(other_hash) do |key, oldval, newval|
        oldval = oldval.to_hash if oldval.respond_to?(:to_hash)
        newval = newval.to_hash if newval.respond_to?(:to_hash)
        oldval.class.to_s == 'Hash' && newval.class.to_s == 'Hash' ? Comprobante.rmerge(oldval, newval) : newval
      end
      result
    end

    private

    def deep_to_h value
      
      if value.is_a? ElementoComprobante
        original = value.to_h
        value = {}
        original.each do |k,v|
          value[k] = deep_to_h v
        end
        
      elsif value.is_a?(Array)
        value = value.map do |v|
          deep_to_h v
        end
      end

      value
    end
  
  end

end