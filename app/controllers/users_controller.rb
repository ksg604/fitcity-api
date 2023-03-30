class UsersController < ApplicationController

  wrap_parameters :user, include: [:email, :password, :password_confirmation]
  before_action :authenticate_user, only: [:get_my_info, :get_cart, :add_product_to_cart]
  before_action :get_shopify_client, only: [:get_cart, :add_product_to_cart, :update_cart]
  require "Jwt"
  require "Errors"

  def index
    # Get all users
  end

  def show 
    # show
  end

  def create
    if request.original_url.include? "api" 
      user = User.new(create_user_params)

      begin
        user.save!
        access_token, refresh_token = Jwt::Issuer.issue_tokens(user)

        # Server responds with JWT in the response body and refresh token in an http only cookie

        cookies["refresh_token"] = {
          expires: Time.now + 24.hours,
          secure: false,
          http_only: true,
          value: refresh_token.encrypted_token
        }

        respond_to do |format|
          format.json { render :json => { access_token: access_token } }
        end
      rescue => exception
        logger.error "Exception: #{exception}"
        if exception.message.include? "doesn't match"
          render :json => { message: exception }, status: :unprocessable_entity
        elsif exception.message.include? "Email has already been taken"
          render :json => { message: exception }, status: :bad_request
        else 
          render :json => { message: exception }, status: :bad_request
        end
        
      end
    else 
      p "web ui action"
    end
  end

  def login
    user = User.find_by(email: login_user_params[:email])
    
    if !user || !user.authenticate(login_user_params[:password])
      render :json => { message: "Invalid email or password" }, status: :unauthorized
    else
      access_token, refresh_token = Jwt::Issuer.issue_tokens(user)

      cookies["refresh_token"] = {
        expires: Time.now + 24.hours,
        secure: false,
        http_only: true,
        value: refresh_token.encrypted_token
      }

      respond_to do |format|
        format.json { render :json => { access_token: access_token } }
      end
    end
  end

  def logout
    Jwt::Revoker.revoke(request.cookies["refresh_token"])

    respond_to do |format|
      format.json { render :json => { status: "Successfully logged out"} }
    end
  end

  def refresh
    # If client detects it does not have an access token, attempt to refresh the token
    begin
      new_access_token, new_refresh_token = Jwt::Refresh.refresh!(request.cookies["refresh_token"])
    rescue => exception
      if exception.message.include?("Invalid Refresh Token")
        return render :json => { message: exception }, status: :unauthorized     
      end
      access_token_expired = exception.message.split("exception: ").include?("Missing Access Token")
    end

    cookies["refresh_token"] = {
      expires: Time.now + 24.hours,
      secure: false,
      http_only: true,
      value: new_refresh_token.encrypted_token
    }

    respond_to do |format|
      format.json { render :json => { access_token: new_access_token } }
    end
  end

  def get_my_info
    respond_to do |format|
      format.json { render :json => { email: @user.email } }
    end
  end

  def request_reset_password
    require "Tokens"

    @user = User.find_by(request_reset_password_params)
    raise Errors::InvalidUser unless @user.present?

    token = Tokens::PasswordResetToken.issue_token(@user)

    password_reset_url = "http://10.0.0.31:3000/profile/settings/reset-password?token=#{token.encrypted_token}"

    respond_to do |format|
      begin
        UserMailer.with(password_reset_url: password_reset_url).send_password_reset_email(@user.email).deliver
        format.json { render :json => { message: "Successfully sent password reset email"} }
      rescue => exception
        logger.error "Exception: #{exception}"
      end
    end
  end

  def reset_password
    token = params[:token]

    existing_pw_reset_token = PasswordResetToken.find_by(encrypted_token: token)
    user = User.find_by(id: existing_pw_reset_token.user_id)

    user.password = params[:new_password]
    user.save

    respond_to do |format|
      format.json { render :json => {message: "Successfully reset password"}}
    end
  end

  def get_cart
  
    shopify_res = @client.query(query: helpers.get_cart_query(@user.cart_id))
    # If we get no cart from the Shopify API, create a new cart and make the query for that
    if shopify_res.body["data"]["cart"].nil?
      @user.init_cart
      @user.save
      shopify_res = @client.query(query: helpers.get_cart_query(@user.cart_id))
    end

    raise Errors::ShopifyError.new("Shopify API Errors: Could not retrieve cart: Invalid Cart", "Could not retrieve cart: Invalid Cart") unless shopify_res.body["data"]["cart"].present?
    cart = helpers.process_cart(shopify_res.body)
    return render :json => {cart: cart} 
  end

  def add_product_to_cart
    mutation = <<-MUTATION
      mutation cartLinesAdd($cartId: ID!, $lines: [CartLineInput!]!) {
        cartLinesAdd(cartId: $cartId, lines: $lines) {
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

    variables = {
      "cartId": params["cart_id"],
      "lines": [
        {
          "merchandiseId": params["product_id"],
          "quantity": 1,
        }
      ]
    }

    shopify_res = @client.query(query: mutation, variables: variables)
    raise Errors::ShopifyError.new("Shopify API Errors: ", "Could not add product to cart") unless shopify_res.body["errors"].nil? && 
                                                                                            shopify_res.body["data"]["cartLinesAdd"]["userErrors"].empty?
    
    return render :json => {cart: shopify_res.body} 
  end

  def update_cart
    mutation = <<-MUTATION
      mutation cartLinesUpdate($cartId: ID!, $lines: [CartLineUpdateInput!]!) {
        cartLinesUpdate(cartId: $cartId, lines: $lines) {
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

    variables = {
      "cartId": params["cart_id"],
      "lines": [
        {
          "id": params["line_id"],
          "merchandiseId": params["merchandise_id"],
          "quantity": params["quantity"],
        }
      ]
    }

    shopify_res = @client.query(query: mutation, variables: variables)
    raise Errors::ShopifyError.new("Shopify API Errors: ", "Could not add product to cart") unless shopify_res.body["errors"].nil? && 
                                                                                            shopify_res.body["data"]["cartLinesUpdate"]["userErrors"].empty?

    return render :json => {cart: shopify_res.body} 
  end

  private
    # Using a private method to encapsulate the permissible parameters
    # is just a good pattern since you'll be able to reuse the same
    # permit list between create and update. Also, you can specialize
    # this method with per-user checking of permissible attributes.
    def create_user_params
      params.require(:user).permit(:email, :password, :password_confirmation)
    end

    def login_user_params
      params.require(:user).permit(:email, :password)
    end

    def request_reset_password_params
      params.require(:user).permit(:email)
    end

    def authenticate_user
      begin
        @user, @decoded_token = authenticate
      rescue => exception
        access_token_expired = exception.message.split("exception: ").include?("Missing Access Token")
        if access_token_expired 
          render :json => { message: "Access token expired" }, status: :unauthorized
        end
      end
    end 

    def get_shopify_client
      # For anything which needs authenticated access via OAuth
      # session = ShopifyAPI::Utils::SessionUtils.load_current_session(cookies: request.cookies, is_online: true)

      # initalize the shopify api client
      @client = ShopifyAPI::Clients::Graphql::Storefront.new(Rails.application.credentials.shopify.shop_url, Rails.application.credentials.shopify.storefront_api_token)
    end
end
