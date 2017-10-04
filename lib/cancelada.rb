module CFDI

  require 'active_support/ordered_hash'

  # La clase principal para crear Comprobantes
  class Cancelada
  
    @@data = [:rfcemisor, :fecha, :uuid, :digest, :signature, :issuername, :serialnumber, :certificate, :key, :password]
    attr_accessor *@@data
    
    @@options = {
      :defaults => {}
    }
    
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
    
    def fecha= fecha
      fecha = fecha.strftime('%FT%R:%S') unless fecha.is_a? String
      @fecha = fecha
    end

    # Canonical version of data to be signed
    # Step ONE
    def canonicalized_data

      parametros = ActiveSupport::OrderedHash.new
      parametros["xmlns"] = "http://cancelacfd.sat.gob.mx"
      parametros["xmlns:xsd"] = "http://www.w3.org/2001/XMLSchema"
      parametros["xmlns:xsi"] = "http://www.w3.org/2001/XMLSchema-instance"
      parametros["Fecha"] = @fecha
      parametros["RfcEmisor"] = @rfcemisor
      
      @builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
        xml.Cancelacion(parametros) do
          xml.Folios {
            xml.UUID(@uuid)
          }          
        end
      end
      
      return @builder.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::AS_XML | Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)
            
    end

    # Digest Value
    # Step TWO

    def digested_canonicalized_data
      
      @string = ""
      @string << CGI::unescapeHTML(self.canonicalized_data.gsub(/\n/, ''))
      return Base64::encode64(Digest::SHA1.digest(@string))
      
    end

    # Create a canonicalized version of the SignedInfo element
    # Step THREE
    
    def canonicalized_signed_info

      parametros = ActiveSupport::OrderedHash.new
      parametros["xmlns"] = "http://www.w3.org/2000/09/xmldsig#"
      parametros["xmlns:xsd"] = "http://www.w3.org/2001/XMLSchema"
      parametros["xmlns:xsi"] = "http://www.w3.org/2001/XMLSchema-instance"
      
      @builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
        xml.SignedInfo(parametros) do

          xml.CanonicalizationMethod({'Algorithm' => "http://www.w3.org/TR/2001/REC-xml-c14n-20010315"}) do
            xml.TEST
          end
          
          xml.SignatureMethod({'Algorithm' => "http://www.w3.org/2000/09/xmldsig#rsa-sha1"}) do
            xml.TEST
          end
          
          xml.Reference({'URI' => ""}) do
            
            xml.Transforms do
              xml.Transform({ 'Algorithm' => "http://www.w3.org/2000/09/xmldsig#enveloped-signature" }) do
                xml.TEST
              end
            end
          
            xml.DigestMethod({ 'Algorithm' => "http://www.w3.org/2000/09/xmldsig#sha1" }) do
              xml.TEST
            end
            
            xml.DigestValue(self.digested_canonicalized_data)
          
          end
        
        end
      end

      return @builder.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::AS_XML | Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)
      
    end

    # Compute the rsa-sha1 signature of the SignedInfo element using the private key
    # Step FOUR
    
    def computed_signed_info
      
      llave = CFDI::Key.new @key, @password

      return Base64::encode64(llave.sign(OpenSSL::Digest::SHA1.new, CGI::unescapeHTML(self.canonicalized_signed_info.gsub('<TEST/>','').gsub(/\n/, ''))))
            
    end

    # Compose the final output XML document
    # Step FIVE
    def xml_final_output

      parametros = ActiveSupport::OrderedHash.new
      parametros["xmlns"] = "http://cancelacfd.sat.gob.mx"
      parametros["xmlns:xsd"] = "http://www.w3.org/2001/XMLSchema"
      parametros["xmlns:xsi"] = "http://www.w3.org/2001/XMLSchema-instance"
      parametros["Fecha"] = @fecha
      parametros["RfcEmisor"] = @rfcemisor
      
      @certificate = CFDI::Certificado.new @certificate
                  
      @builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
        xml.Cancelacion(parametros) do
          xml.Folios {
            xml.UUID(@uuid)
          }
          xml.Signature({'xmlns' => "http://www.w3.org/2000/09/xmldsig#" }) do
            xml.SignedInfo do 
              xml.CanonicalizationMethod({'Algorithm' =>"http://www.w3.org/TR/2001/REC-xml-c14n-20010315"})
              xml.SignatureMethod({'Algorithm' => "http://www.w3.org/2000/09/xmldsig#rsa-sha1"})
              
              xml.Reference({'URI' => ""}) do
            
                xml.Transforms do
                  xml.Transform({ 'Algorithm' => "http://www.w3.org/2000/09/xmldsig#enveloped-signature" })
                end
          
                xml.DigestMethod({ 'Algorithm' => "http://www.w3.org/2000/09/xmldsig#sha1" })
                xml.DigestValue(self.digested_canonicalized_data)
          
              end
              
            end
            xml.SignatureValue(self.computed_signed_info)
            xml.KeyInfo do 
              xml.X509Data do
                xml.X509IssuerSerial do
                  xml.X509IssuerName(@certificate.issuername)
                  xml.X509SerialNumber(@certificate.serial)
                end
                xml.X509Certificate(@certificate.data)
              end
            end
          end
        end
      end
      
      CGI::unescapeHTML(@builder.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::AS_XML).strip.gsub(/\n/, ''))
      
    end




    def digest_a
      ns = {
        'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
        'xmlns:xsd' => "http://www.w3.org/2001/XMLSchema",
        'xmlns' => "http://cancelacfd.sat.gob.mx"
      }

      ns[:Fecha] = @fecha
      ns[:RfcEmisor] = @rfcemisor
                  
      @builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
        xml.Cancelacion(ns) do
          xml.Folios {
            xml.UUID(@uuid)
          }          
        end
      end
      
      @digested = Base64::encode64(OpenSSL::Digest::SHA1.hexdigest(@builder.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::AS_XML | Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)).strip)
      
    end

    def signed_info

      @builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
        xml.SignedInfo do

          xml.CanonicalizationMethod({'Algorithm' => "http://www.w3.org/TR/2001/REC‐xml‐c14n‐20010315"})
          xml.SignatureMethod({'Algorithm' => "http://www.w3.org/2000/09/xmldsig#rsa‐sha1"})
          
          xml.Reference({'URI' => ""}) do
            
            xml.Transforms do
              xml.Transform({ 'Algorithm' => "http://www.w3.org/2000/09/xmldsig#enveloped‐signature" })
            end
          
            xml.DigestMethod({ 'Algorithm' => "http://www.w3.org/2000/09/xmldsig#sha1" })
            xml.DigestValue(self.digest_a)
          
          end
        
        end
      end

      @builder.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::AS_XML | Nokogiri::XML::Node::SaveOptions::NO_DECLARATION).strip.gsub(/\n/, '')
      
    end

    def sello
      
      llave = CFDI::Key.new @key, @password
      @digested = Base64::encode64(llave.sign(OpenSSL::Digest::SHA1.new, self.signed_info))
      
    end

    def to_xml
      ns = {
        'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
        'xmlns:xsd' => "http://www.w3.org/2001/XMLSchema",
        'xmlns' => "http://cancelacfd.sat.gob.mx"
      }

      ns[:fecha] = @fecha
      ns[:rfcemisor] = @rfcemisor
                  
      @builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
        xml.Cancelacion(ns) do
          xml.Folios {
            xml.UUID(@uuid)
          }          
        end
      end
      @builder.to_xml
    end

    def xml_output
      ns = {
        'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
        'xmlns:xsd' => "http://www.w3.org/2001/XMLSchema",
        'xmlns' => "http://cancelacfd.sat.gob.mx"
      }

      ns[:Fecha] = @fecha
      ns[:RfcEmisor] = @rfcemisor
      
      @certificate = CFDI::Certificado.new @certificate
                  
      @builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
        xml.Cancelacion(ns) do
          xml.Folios {
            xml.UUID(@uuid)
          }
          xml.Signature({'xmlns' => "http://www.w3.org/2000/09/xmldsig#" }) do
            xml.SignedInfo do 
              xml.CanonicalizationMethod({'Algorithm' =>"http://www.w3.org/TR/2001/REC‐xml‐c14n‐20010315"})
              xml.SignatureMethod({'Algorithm' => "http://www.w3.org/2000/09/xmldsig#rsa‐sha1"})
              
              xml.Reference({'URI' => ""}) do
            
                xml.Transforms do
                  xml.Transform({ 'Algorithm' => "http://www.w3.org/2000/09/xmldsig#enveloped‐signature" })
                end
          
                xml.DigestMethod({ 'Algorithm' => "http://www.w3.org/2000/09/xmldsig#sha1" })
                xml.DigestValue(self.digest_a)
          
              end
              
            end
            xml.SignatureValue(self.sello)
            xml.KeyInfo do 
              xml.X509Data do
                xml.X509IssuerSerial do
                  xml.X509IssuerName(@certificate.issuername)
                  xml.X509SerialNumber(@certificate.serial)
                end
                xml.X509Certificate(@certificate.data)
              end
            end
          end
        end
      end
      
      CGI::unescapeHTML(@builder.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::AS_XML).strip.gsub(/\n/, ''))
      
    end


    # Un hash con todos los datos del comprobante, listo para Hash.to_json
    # 
    # @return [Hash] El comprobante como Hash
    def to_h
      hash = {}
      @@data.each do |key|
        data = deep_to_h send(key)
        hash[key] = data
      end
      
      return hash
    end
  
    # @private
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
      
      #value = value.to_h if value.respond_to? :to_h
      #if value.each do |vi|
      #  value.map do |k,v|
      #    v = deep_to_h v
      #  end
      #end
      value
    end
  
  end
end