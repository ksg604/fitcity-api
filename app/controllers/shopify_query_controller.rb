class ShopifyQueryController < ApplicationController
  before_action :get_shopify_client

  def get_knee_sleeves
    # make the GraphQL query string
    query = query_for_product("SBD Knee Sleeves")

    # Process data
    sbd_knee_sleeves = @client.query(query: query).body["data"]["products"]["edges"][0]["node"]
    product = helpers.process_product(sbd_knee_sleeves)

    respond_to do |format|
      format.json{ render :json => {product: product} }
    end 
  end

  def get_sbd_belt
    query = query_for_product("SBD Belt")

    sbd_belt = @client.query(query: query).body["data"]["products"]["edges"][0]["node"]
    product = helpers.process_product(sbd_belt)

    respond_to do |format|
      format.json{ render :json => {product: product} }
    end 
  end

  def get_notorious_lifters
    query = query_for_product("Notorious Lifters")

    notorious_lifters = @client.query(query: query).body["data"]["products"]["edges"][0]["node"]
    product = helpers.process_product(notorious_lifters)

    respond_to do |format|
      format.json{ render :json => {product: product} }
    end 
  end

  private 
    def get_shopify_client
      # For anything which needs authenticated access via OAuth
      # session = ShopifyAPI::Utils::SessionUtils.load_current_session(cookies: request.cookies, is_online: true)

      # initalize the shopify api client
      @client = ShopifyAPI::Clients::Graphql::Storefront.new(Rails.application.credentials.shopify.shop_url, Rails.application.credentials.shopify.storefront_api_token)
    end

    def query_for_product(product_name)
      query = <<~QUERY
      {
        products(first: 1, query: "#{product_name}") {
          edges {
            node {
              title
              descriptionHtml
              variants(first: 6) {
                edges {
                  node {
                    id
                    image {
                      url
                    }
                    selectedOptions {
                      name
                      value
                    }
                    price {
                      amount
                    }
                    quantityAvailable
                  }
                }
              }
            }
          }
        }
      }
      QUERY
    end
end
