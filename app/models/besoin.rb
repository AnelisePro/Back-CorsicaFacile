class Besoin < ApplicationRecord
  belongs_to :client

  def parsed_schedule
    return nil if schedule.blank?
    
    begin
      JSON.parse(schedule)
    rescue JSON::ParserError => e
      Rails.logger.error "Erreur de parsing du schedule pour Besoin #{id}: #{e.message}"
      # Si le schedule n'est pas un JSON valide, retourner un objet par défaut
      {
        type: 'single_day',
        start_time: '09:00',
        end_time: '17:00'
      }
    end
  end
end

