class ShopifyMutationController < ApplicationController
  before_action :init_client

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
  end

  private 
    def init_client
      # For anything which needs authenticated access via OAuth
      # session = ShopifyAPI::Utils::SessionUtils.load_current_session(cookies: request.cookies, is_online: true)

      # initalize the shopify api client
      @client = ShopifyAPI::Clients::Graphql::Storefront.new(Rails.application.credentials.shopify.shop_url, Rails.application.credentials.shopify.storefront_api_token)
    end
end
