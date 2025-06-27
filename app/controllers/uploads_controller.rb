class UploadsController < ApplicationController

  def presigned_url
    filename = params[:filename]
    content_type = params[:content_type]
    purpose = params[:purpose] # facultatif : "profile_picture", "project_image", "document", etc.

    if filename.blank? || content_type.blank?
      return render json: { error: 'Paramètres invalides.' }, status: :unprocessable_entity
    end

    # Création du préfixe de stockage S3
    key_prefix = case purpose
                 when 'profile_picture' then 'avatars/'
                 when 'project_image' then 'projects/'
                 when 'document' then 'documents/'
                 else 'uploads/'
                 end

    timestamp = Time.now.to_i
    sanitized_filename = filename.gsub(' ', '_')
    s3_key = "#{key_prefix}#{SecureRandom.uuid}_#{timestamp}_#{sanitized_filename}"

    s3_service = S3UrlService.new

    # Génération de l'URL pré-signée PUT
    presigned_url = s3_service.presigned_put_url(s3_key, content_type: content_type)

    render json: { url: presigned_url, key: s3_key }, status: :ok
  rescue => e
    Rails.logger.error "Erreur presigned_url: #{e.message}"
    render json: { error: 'Erreur lors de la génération de l’URL signée.' }, status: :unprocessable_entity
  end
end
