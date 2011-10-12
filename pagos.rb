require 'rubygems'
require 'active_record'
require 'yaml'
require 'fileutils'
#require 'action_mailer'
require 'logger'
require 'mail'

dbconfig = YAML::load(File.open('config/database.yml'))
ActiveRecord::Base.pluralize_table_names = false
ActiveRecord::Base.establish_connection(dbconfig)

#File path
$ruta = "/data/reservas/inbound/"
$loaded = "/data/reservas/loaded/"

# Logging info
$log = Logger.new('tmp/log.txt','weekly')
$log.level = Logger::DEBUG
$log.info ".....................App Started - Ready to download and process files....................."

#if RUBY_VERSION =~ /1.9/
#    Encoding.default_external = Encoding::UTF_8
#    Encoding.default_internal = Encoding::UTF_8
#end

#Email configuration
Mail.defaults do
  retriever_method :pop3, :address    => 'mail.migracion.gov.do',
                          :port       => 995, #110, #995 ssl
                          :user_name  => 'erodriguez@migracion.gov.do',
                          :password   => 'm1gr4c10n1t',
                          :enable_ssl => true
end

#Table definitions
class PagosHeader < ActiveRecord::Base
  set_table_name "pagos_header"
  set_primary_key "id"
end

class PagosDetail < ActiveRecord::Base
  set_table_name "pagosreservas"
  set_primary_key "codigo"
end

class Pagos
  
  def readfile(filename)
    begin
      return File.open(filename,"r", :encoding => "ISO-8859-1:UTF-8") #forcing file encoding transcendence when file come from Guindows OS
    rescue
      $log.error "Unable to open the file #{filename}"
    end   
    
  end
  
  def readlines(content,filename)
    content.each { |lines|  
      idregistro = lines[0,2]
      #idregistro 01 indica el registro de encabezado
      if idregistro == "01" then
        idcompania = lines[2,3]
        idbanco = lines[5,8]
        cantidad = lines[13,7]
        monto = lines[20,13]
        fecha = lines[33,8]
        hora = lines[41,6]
        idlote = lines[47,10]
        
        putHeader(idregistro,idcompania,idbanco,cantidad,monto,fecha,hora,idlote,filename)
                
      elsif idregistro == "02"
        cliente = lines[2,20]
        nodocumento = lines[22,20]
        tipopago = lines[42,2] #06 = Cheque, 07 = Efectivo
        monto = lines[44,11]
        fecha = lines[55,8]
        idtrans = lines [63,10]
        cajero = lines[73,10]
        oficina = lines[83,3]
        codpago = lines[86,3]
        
        puts cliente+" - "+nodocumento

        putDetail(idregistro,cliente,nodocumento,tipopago,monto,fecha,idtrans,cajero,oficina,codpago,filename)                
      end 
    
    }    
  end  

  def putHeader(idregistro,idcompania,idbanco,cantidad,monto,fecha,hora,idlote,filename)    
    pheader = PagosHeader.new
    pheader.tiporegistro = idregistro
    pheader.empresa = idcompania
    pheader.id_banco = idbanco
    pheader.cantidad = cantidad
    pheader.monto = monto
    pheader.fecha = fecha
    pheader.hora = hora
    pheader.id_lote = idlote
    pheader.archivo = filename
    pheader.save        
  end
  
  def putDetail(idregistro,cliente,nodocumento,tipopago,monto,fecha,idtrans,cajero,oficina,codpago,filename)
    pdetail = PagosDetail.new
    pdetail.idcampo = idregistro
    pdetail.numerodecuenta = nodocumento
    pdetail.nocontrato = cliente
    pdetail.tipodepago = tipopago
    pdetail.monto = monto    
    pdetail.fecha = fecha    
    pdetail.idtransacc = idtrans    
    pdetail.cajero = cajero    
    pdetail.oficina = oficina    
    pdetail.codcausa = codpago   
    pdetail.archivo = filename               
    pdetail.save
  end
  
  def getemail()
    begin
      mail = Mail.find_and_delete(:what => :first, :count => 3)    
    rescue Exception => e
      $log.error "Error connecting to email account - #{e.message}"      
    end

    begin
      mail.each do  |email|
        email.attachments.each do |att|
          File.open($ruta+att.filename,"w+b",0644) { |f|  
            f.write att.body.decoded  
          }
        end
      end  
    rescue Exception => e
      $log.error "Error getting email messages - #{e.message}"
    end    
    
  end
    
end



pagos = Pagos.new
$log.info "Downloading email attachments"
pagos.getemail()

#pagostxt = File.join($ruta,"*.txt")
$log.info "Reading *.txt inside '#{$ruta}'"
Dir.foreach($ruta) { |e|
    
  fullpath = $ruta+e
  if File::file?(fullpath) then    

    if File.exists?(fullpath) then
      $log.info "Parsing file - '#{fullpath}'"
      #read and load into sqlserver the payments
      content = pagos.readfile(fullpath)
      pagos.readlines(content,e)
      
      #After txt file is loaded into DB, file is moved to a diferent location
      FileUtils.mv fullpath,$loaded  
      $log.info "File '#{fullpath}' was proccessed and moved to '#{$loaded}'"
            
    else
      $log.error "File does not exists - '#{fullpath}'"
    end

  end
  
}
$log.info ".....................Application finished execution....................."




