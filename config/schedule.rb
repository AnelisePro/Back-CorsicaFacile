set :output, 'log/cron.log'
set :environment, ENV['RAILS_ENV'] || :development

# Exécution quotidienne à 9h pour vérifier les relances mensuelles
every 1.day, at: '9:00 am' do
  runner "ArtisanSubscriptionRenewalNotificationJob.run"
end

# Configuration pour développement (optionnel)
if ENV['RAILS_ENV'] == 'development'
  # Exécution plus fréquente pour les tests
  every 1.hour do
    runner "ArtisanSubscriptionRenewalNotificationJob.run"
  end
end


