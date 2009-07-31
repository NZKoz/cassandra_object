module CassandraObject
  class Collection < Array
    attr_accessor :last_column_name
  end
end