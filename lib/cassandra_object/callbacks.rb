module CassandraObject
  module Callbacks
    extend ActiveSupport::Concern

    depends_on ActiveSupport::Callbacks

    included do
      define_callbacks :before_save, :after_save, :before_create, :after_create
    end
  end
end