class S3UrlService
  def initialize(env: Rails.env)
    @s3 = Aws::S3::Resource.new

    @bucket_name = case env.to_s
                   when 'production' then Rails.application.credentials.dig(:aws, :s3_bucket_prod)
                   when 'development' then Rails.application.credentials.dig(:aws, :s3_bucket_dev)
                   else Rails.application.credentials.dig(:aws, :s3_bucket_dev)
                   end

    @bucket = @s3.bucket(@bucket_name)
  end

  def presigned_put_url(key, content_type:, expires_in: 300)
    obj = @bucket.object(key)
    obj.presigned_url(:put, expires_in: expires_in, content_type: content_type)
  end

  # **Attention ici** : Générer une URL pré-signée GET au lieu d'une URL publique
  def presigned_get_url(key, expires_in: 300)
    obj = @bucket.object(key)
    obj.presigned_url(:get, expires_in: expires_in)
  end

  # Garder la méthode url_for si tu veux accéder à l'URL publique sans signature
  def url_for(key)
    obj = @bucket.object(key)
    obj.public_url
  end
end



