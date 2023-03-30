module Errors
  class Unauthorized < StandardError
    def initialize(msg="Unauthorized")
      super
    end
  end

  class InvalidToken < StandardError
    attr_reader :token_type
    def initialize(msg="Invalid Refresh Token", token_type="Some Token")
      @token_type = token_type
      msg = "Invalid #{@token_type}"
      super(msg)
    end
  end

  class MissingToken < StandardError
    attr_reader :token_type
    def initialize(msg="Missing Refresh Token", token_type="Some Token")
      @token_type = token_type
      msg = "Missing #{@token_type}"
      super(msg)
    end
  end

  class InvalidUser < StandardError
    def initialize(msg="No user associated with that email")
      super(msg)
    end
  end

  class ShopifyError < StandardError
    def initialize(msg="Shopify API Error: ", error="some shopify error")
      msg = "Shopify API Errors: #{error}"
      super(msg)
    end
  end
end