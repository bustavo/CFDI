module CFDI
  class Impuestos < ElementoComprobante
    @cadenaOriginal = [:TotalImpuestosTrasladados, :totalImpuestosRetenidos, :traslados, :retenciones]

    attr_accessor(*@cadenaOriginal)

    def initialize data={}
      self.traslados = data[:traslados] || []
      self.retenciones = data[:retenciones] || []
      self.TotalImpuestosTrasladados = data[:TotalImpuestosTrasladados] if data[:TotalImpuestosTrasladados]
      self.totalImpuestosRetenidos = data[:totalImpuestosRetenidos] if data[:totalImpuestosRetenidos]
    end

    def traslados= value
      @traslados = value.map { |t|
        t.is_a?(ImpuestoGenerico) ? t : Impuestos::Traslado.new({
          tasa: t[:tasa],
          impuesto: t[:impuesto] || 'IVA',
          importe: t[:importe]
        })
      }
      @TotalImpuestosTrasladados = suma(:traslados) if @traslados.count > 0
    end

    def retenciones= value
      @retenciones = value.map { |t|
        t.is_a?(ImpuestoGenerico) ? t : Impuestos::Retencion.new({
          tasa: t[:tasa],
          impuesto: t[:impuesto] || 'IVA',
          importe: t[:importe]
        })
      }
      @totalImpuestosRetenidos = suma(:retenciones) if @retenciones.count > 0
    end

    def TotalImpuestosTrasladados= valor
      @TotalImpuestosTrasladados = valor.to_f
    end

    def totalImpuestosRetenidos= valor
      @totalImpuestosRetenidos = valor.to_f
    end

    def count
      traslados.count + retenciones.count
    end

    def suma tipo_impuestos
      instance_variable_get("@#{tipo_impuestos}").map(&:importe).reduce(0.0, &:+)
    end

    def total
      suma(:traslados) - suma(:retenciones)
    end

    class ImpuestoGenerico < ElementoComprobante
      # @private
      @cadenaOriginal = [:impuesto, :tasa, :importe]
      # @private
      attr_accessor(*@cadenaOriginal)

      # Asigna la tasa del impuesto
      # @param  valor [String, Float, #to_f] Cualquier objeto que responda a #to_f
      def tasa= valor
        @tasa = valor.to_f
      end

      # Asigna el importe del impuesto
      # @param  valor [String, Float, #to_f] Cualquier objeto que responda a #to_f
      def importe= valor
        @importe = valor.to_f
      end

    end

    class Traslado < ImpuestoGenerico
      # @private
      @cadenaOriginal = [:impuesto, :tasa, :importe]
      # @private
      attr_accessor(*@cadenaOriginal)

      # # Asigna la tasa del impuesto
      # # @param  valor [String, Float, #to_f] Cualquier objeto que responda a #to_f
      # def tasa= valor
      #   @tasa = valor.to_f
      # end

      # # Asigna el importe del impuesto
      # # @param  valor [String, Float, #to_f] Cualquier objeto que responda a #to_f
      # def importe= valor
      #   @importe = valor.to_f
      # end
    end

    class Retencion < ImpuestoGenerico
      # @private
      @cadenaOriginal = [:impuesto, :tasa, :importe]
      # @private
      attr_accessor(*@cadenaOriginal)

      # # Asigna la tasa del impuesto
      # # @param  valor [String, Float, #to_f] Cualquier objeto que responda a #to_f
      # def tasa= valor
      #   @tasa = valor.to_f
      # end

      # # Asigna el importe del impuesto
      # # @param  valor [String, Float, #to_f] Cualquier objeto que responda a #to_f
      # def importe= valor
      #   @importe = valor.to_f
      # end
    end
  end

end
