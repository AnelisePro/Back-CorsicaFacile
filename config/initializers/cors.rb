Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins %r{\Ahttps:\/\/.*corsicafacile\.fr\z},
            %r{\Ahttps:\/\/front-corsica-facile(-\w+)?\.vercel\.app\z}, 
            'http://localhost:3000'

    resource '*',
      headers: :any,
      expose: ['Authorization'],
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true
  end
end
