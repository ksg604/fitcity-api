Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ['http://10.0.0.31:3000']
    resource '*', 
    headers: :any, 
    methods: [:get, :post, :put], 
    credentials: true, expose: ["Location"]
  end
end