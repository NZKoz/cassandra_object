module CassandraObject
  module Callbacks
    extend ActiveSupport::Concern

    included do
      extend ActiveModel::Callbacks
      define_model_callbacks :save, :create, :destroy
    end
  end
end