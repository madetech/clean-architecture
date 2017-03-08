require 'active_support/core_ext/hash/reverse_merge'
require 'active_model'
require 'action_view'
require 'ostruct'

class ApplicationController
  class Params < OpenStruct
    def require(name)
      to_h
    end
  end

  def params=(params)
    @params = Params.new(params)
  end

  def params
    @params
  end

  def user_instance_var
    @user
  end
end

class View
  include ActionView::Helpers::FormHelper

  attr_accessor :output_buffer

  def polymorphic_path(_, _)
    '/dummy/url'
  end

  def protect_against_forgery?
    true
  end

  def form_authenticity_token(token = nil)
    'a token'
  end
  alias_method :request_forgery_protection_token, :form_authenticity_token
end

module Spree
  class Order
    def self.find(id)
      new
    end

    def discount
      10
    end

    def update!(attrs)
      true
    end
  end

  class User
    include ActiveModel::Model

    def self.create(attrs)
      new(attrs).tap(&:valid?)
    end

    attr_reader :email
    validates :email, presence: true

    def initialize(email:, name:, password:)
      @email = email
      @name = name
      @password = password
    end
  end
end

class FakeGateway
  def create_user(attrs)
    Spree::User.new(attrs).tap(&:valid?).errors
  end
end

require_relative '../lib/orders/domain/discountable_order'
require_relative '../lib/orders/gateway/order'
require_relative '../lib/orders/use_case/apply_order_discount'

require_relative '../lib/users/gateway/user'
require_relative '../lib/users/use_case/register_user'

require_relative '../app/controllers/user_registration_controller'
