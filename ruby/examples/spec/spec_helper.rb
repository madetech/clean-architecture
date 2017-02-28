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
  class Order; end

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

Dir[__dir__ + '/../{lib,app}/**/*.rb'].each { |f| require f }
