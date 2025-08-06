namespace :artisans do
  desc "Reset monthly response counters"
  task reset_monthly_counters: :environment do
    puts "Réinitialisation des compteurs de réponses mensuelles..."

    start_of_month = Time.current.beginning_of_month

    artisans_to_reset = Artisan.where(
      "last_response_reset_at IS NULL OR last_response_reset_at < ?", start_of_month
    )

    if artisans_to_reset.any?
      count = artisans_to_reset.update_all(
        monthly_response_count: 0,
        last_response_reset_at: start_of_month
      )

      puts "Réinitialisation effectuée pour #{count} artisan(s)."
    else
      puts "Aucun artisan à réinitialiser ce mois-ci."
    end
  end
end
