require 'active_record'

class PaymentsHeader < ActiveRecord::Base
  set_table_name "pagos_header"
  set_primary_key "id"
end

class PaymentsDetail < ActiveRecord::Base
  set_table_name "pagosreservas"
  set_primary_key "codigo"
end
