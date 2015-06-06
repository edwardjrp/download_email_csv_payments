require 'rubygems'
require 'active_record'
require 'yaml'
require 'fileutils'
require 'logger'
require 'mail'
#require File.expand_path('../pagos_models', __FILE__)
require File.expand_path('../payments.rb', __FILE__)

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



payments = Payments.new
$log.info "Downloading email attachments"
payments.get_email

#pagostxt = File.join($ruta,"*.txt")
$log.info "Reading *.txt inside '#{$ruta}'"

=begin
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
=end
$log.info ".....................Application finished execution....................."




