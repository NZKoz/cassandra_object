module CassandraObject
  module IntegerType
    def encode(int)
      raise ArgumentError.new("#{self} requires an Integer") unless int.kind_of?(Integer)
      int.to_s
    end
    module_function :encode

    def decode(str)
      raise ArgumentError.new("#{str} isn't a String that looks like a Integer") unless str.kind_of?(String) && str.match(/\A\d+\Z/)
      str.to_i
    end
    module_function :decode
  end

  module FloatType
    def encode(float)
      raise ArgumentError.new("#{self} requires a Float") unless float.kind_of?(Float)
      float.to_s
    end
    module_function :encode

    def decode(str)
      raise ArgumentError.new("#{str} isn't a String that looks like a Float") unless str.kind_of?(String) && str.match(/\A\d+(\.\d+)\Z/)
      str.to_f
    end
    module_function :decode
  end

  module DateType
    FORMAT = '%Y-%m-%d'

    def encode(date)
      raise ArgumentError.new("#{self} requires a Date") unless date.kind_of?(Date)
      date.strftime(FORMAT)
    end
    module_function :encode

    def decode(str)
      raise ArgumentError.new("#{str} isn't a String that looks like a Date") unless str.kind_of?(String) && str.match(/\A\d{4}\-\d{2}\-\d{2}\Z/)
      Date.strptime(str, FORMAT)
    end
    module_function :decode
  end

  module TimeType
    # lifted from the implementation of Time.xmlschema and simplified
    REGEX = /\A\s*
              (-?\d+)-(\d\d)-(\d\d)
              T
              (\d\d):(\d\d):(\d\d)
              (\.\d*)?
              (Z|[+-]\d\d:\d\d)?
              \s*\z/ix

    def encode(time)
      raise ArgumentError.new("#{self} requires a Time") unless time.kind_of?(Time)
      time.xmlschema
    end
    module_function :encode

    def decode(str)
      raise ArgumentError.new("#{str} isn't a String that looks like a Time") unless str.kind_of?(String) && str.match(REGEX)
      Time.xmlschema(str)
    end
    module_function :decode
  end
end