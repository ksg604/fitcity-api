scope :api do
  post "/users/login", to: "users#login"
  post "/users/logout", to: "users#logout"
  post "/users/request-reset-password", to: "users#request_reset_password"
  post "/users/reset-password", to: "users#reset_password"
  post "/users/refresh", to: "users#refresh"
  get "/users/me", to: "users#get_my_info"

  get "/users/cart", to: "users#get_cart"
  post "/users/cart", to: "users#add_product_to_cart"
  put "/users/cart", to: "users#update_cart"


  get "/auth/login", to: "shopify_auth#login"
  get "/auth/callback", to: "shopify_auth#callback"

  get "/products/knee-sleeves", to: "shopify_query#get_knee_sleeves"
  get "/products/lifting-belts", to: "shopify_query#get_sbd_belt"
  get "/products/footwear", to: "shopify_query#get_notorious_lifters"

  resources :users
end
