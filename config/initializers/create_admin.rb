# config/initializers/create_admin.rb
if Rails.env.production?
  Rails.application.config.after_initialize do
    ActiveRecord::Base.connection_pool.with_connection do
      if ActiveRecord::Base.connection.table_exists?('admins')
        admin_email = ENV['ADMIN_DEFAULT_EMAIL'] || "anelisegambiz@gmail.com"
        admin_password = ENV['ADMIN_DEFAULT_PASSWORD'] || "CorsicaFacile2025!"
        
        admin = Admin.find_or_create_by(email: admin_email) do |a|
          a.password = admin_password
          a.password_confirmation = admin_password
          a.first_name = "Jenny"
          a.last_name = "Admin"
          a.role = "admin"
          a.active = true
        end
        
        # Forcer l'affichage du message
        message = admin.previously_new_record? ? 
          "✅ Admin créé: #{admin_email}" : 
          "✅ Admin existe: #{admin_email}"
        
        Rails.logger.info message
        $stdout.puts message
        $stdout.flush
      end
    rescue => e
      error_msg = "❌ Erreur admin: #{e.message}"
      Rails.logger.error error_msg
      $stdout.puts error_msg
      $stdout.flush
    end
  end
end
