
#Email configuration
Mail.defaults do
  retriever_method :pop3, :address    => 'mail.myhost.com',
                          :port       => 995, #110, #995 ssl
                          :user_name  => 'email_account@myhost.com',
                          :password   => 'changeme',
                          :enable_ssl => true
end

class Payments
  
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
        
        put_header(idregistro,idcompania,idbanco,cantidad,monto,fecha,hora,idlote,filename)
                
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

        put_detail(idregistro,cliente,nodocumento,tipopago,monto,fecha,idtrans,cajero,oficina,codpago,filename)
      end 
    
    }    
  end  

  def put_header(idregistro,idcompania,idbanco,cantidad,monto,fecha,hora,idlote,filename)
    pheader = PaymentsHeader.new
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
  
  def put_detail(idregistro,cliente,nodocumento,tipopago,monto,fecha,idtrans,cajero,oficina,codpago,filename)
    pdetail = PaymentsDetail.new
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
  
  def get_email
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
