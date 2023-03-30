class User < ApplicationRecord

  # users.password_digest in the database is a :string
  require "BCrypt"
  require "Errors"

  has_secure_password
  
  has_many :refresh_tokens
  has_many :password_reset_tokens
  validates_associated :refresh_tokens
  validates_associated :password_reset_tokens
  before_create do
    init_cart
    create_customer
  end
  
  attr_accessor :token_iat

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, on: :create
  validates :password, confirmation: { case_sensitive: true }, length: { minimum: 8, maximum: 32 }, 
            format: { with: /(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9])(?=.*[!@#$%^&*])[A-Za-z0-9!@#$%^&*]{8,32}/ },
            on: :create
  validates :password_confirmation, presence: true, on: :create

  # def password
  #   @password ||= Password.new(password_digest)
  # end

  # def password=(new_password)
  #   @password = Password.create(new_password)
  #   self.password_digest = @password
  # end

  def init_cart
    @client = ShopifyAPI::Clients::Graphql::Storefront.new(Rails.application.credentials.shopify.shop_url, Rails.application.credentials.shopify.storefront_api_token)

    mutation = <<-MUTATION
      mutation cartCreate {
        cartCreate (input: {
          lines: []
        }) {
          cart {
            # Cart fields
            id
          }
          userErrors {
            field
            message
          }
        }
      }
    MUTATION

    cart_data = @client.query(query: mutation).body["data"]["cartCreate"]
    cart_creation_errors = cart_data["userErrors"]
    raise Errors::ShopifyError.new("Shopify API Errors: ", cart_creation_errors) unless cart_creation_errors.empty?

    self.cart_id = cart_data["cart"]["id"]
  end

  def create_customer 
    mutation =<<~MUTATION
      mutation customerCreate($input: CustomerCreateInput!) {
        customerCreate(input: $input) {
          customer {
            email
          }
          customerUserErrors {
            message
          }
        }
      }
      MUTATION

      variables = {
        "input": {
          "email": self.email,
          "password": self.password
        }
      }
      
      begin
        response = @client.query(query: mutation, variables: variables)
        raise Errors::ShopifyError.new("Shopify API Errors:", "Query to create customer failed with status code #{response.code}") unless response.code == 200
        customer_create_data = response.body["data"]["customerCreate"]
        raise Errors::ShopifyError.new("Shopify API Errors: ", "No data returned from Shopify API on customer creation query") unless customer_create_data.present?
        customer_creation_errors = customer_create_data["customerUserErrors"] unless customer_create_data.nil?
        raise Errors::ShopifyError.new("Shopify API Errors: ", customer_creation_errors) unless customer_creation_errors.empty?
      rescue => exception
        if exception.message.include? "Email has already been taken"
          puts "Exception occurred during customer creation: #{self.email} is already a customer"
        else 
          puts "Exception occurred during customer creation: #{exception} on attempted customer creation of #{self.email}"
        end
      end
  end 
end
