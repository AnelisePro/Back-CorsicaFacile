class ArtisanSubscriptionRenewalNotificationJob
  def self.run
    new.perform
  end

  def perform
    # Calcul des dates pour les relances mensuelles
    two_months_before = Date.today + 2.months
    one_year_ago = Date.today - 1.year

    # Requête pour trouver les artisans à notifier
    artisans_to_notify = Artisan
      .left_joins(:notifications)
      .where("subscription_started_at BETWEEN ? AND ?", two_months_before, one_year_ago)
      .where.not(
        notifications: {
          title: 'Relance mise à jour KBIS & Assurance',
          created_at: (Date.today - 1.month)..Date.today
        }
      )
      .or(
        Artisan.where(
          "subscription_started_at BETWEEN ? AND ? AND id NOT IN (
            SELECT notifiable_id FROM notifications
            WHERE title = 'Relance mise à jour KBIS & Assurance'
            AND created_at >= ?
          )", two_months_before, one_year_ago, Date.today - 1.month
        )
      )
      .distinct

    # Création des notifications
    artisans_to_notify.find_each do |artisan|
      Notification.create!(
        notifiable: artisan,
        title: notification_title(artisan.subscription_started_at),
        body: notification_body(artisan.company_name, artisan.subscription_started_at),
        read: false,
        notification_type: :subscription_renewal
      )
    end
  end

  private

  def notification_title(subscription_date)
    months_remaining = ((subscription_date + 1.year - Date.today) / 30).to_i
    case months_remaining
    when 0 then "Votre abonnement expire ce mois-ci !"
    when 1 then "Votre abonnement expire dans 1 mois"
    else "Votre abonnement expire dans #{months_remaining} mois"
    end
  end

  def notification_body(company_name, subscription_date)
    months_remaining = ((subscription_date + 1.year - Date.today) / 30).to_i
    case months_remaining
    when 0
      <<~BODY.strip
        Bonjour #{company_name},

        Votre abonnement à notre plateforme expire ce mois-ci.
        Il est impératif de mettre à jour votre KBIS et votre attestation d'assurance professionnelle
        dès que possible pour continuer à bénéficier de nos services sans interruption.

        Cordialement,
        L'équipe Corsica Facile
      BODY
    when 1
      <<~BODY.strip
        Bonjour #{company_name},

        Votre abonnement à notre plateforme expire dans 1 mois.
        Merci de préparer la mise à jour de votre KBIS et de votre attestation d'assurance professionnelle.

        Cordialement,
        L'équipe Corsica Facile
      BODY
    else
      <<~BODY.strip
        Bonjour #{company_name},

        Votre abonnement à notre plateforme expire dans #{months_remaining} mois.
        Nous vous rappelons que vous devrez mettre à jour votre KBIS et votre attestation
        d'assurance professionnelle avant cette date.

        Cordialement,
        L'équipe Corsica Facile
      BODY
    end
  end
end




