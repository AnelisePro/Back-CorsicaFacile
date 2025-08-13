class ArtisanStatisticsService
  def self.track_profile_view(artisan_id, user_ip: nil, user_agent: nil, location: nil, session_start: nil)
    date = Date.current
    stat = find_or_create_stat(artisan_id, date)
    
    # Incrémenter les vues
    stat.increment!(:profile_views)
    
    # Tracking des visiteurs uniques (basé sur IP + User Agent pour plus de précision)
    if user_ip.present?
      # Combinaison IP + User Agent pour différencier connecté/non-connecté
      ip_fingerprint = user_agent.present? ? "#{user_ip}_#{Digest::MD5.hexdigest(user_agent)[0..8]}" : user_ip
      redis_key = "visitor_#{artisan_id}_#{date}_#{Digest::MD5.hexdigest(ip_fingerprint)}"
      
      unless Rails.cache.exist?(redis_key)
        stat.increment!(:unique_visitors)
        Rails.cache.write(redis_key, true, expires_in: 1.day)
        Rails.logger.info "New visitor: #{user_ip} for artisan #{artisan_id}"
      else
        stat.increment!(:return_visitors)
        Rails.logger.info "Returning visitor: #{user_ip} for artisan #{artisan_id}"
      end
    end
    
    # Tracking par heure
    current_hour = Time.current.hour
    views_by_hour = stat.views_by_hour || {}
    views_by_hour[current_hour.to_s] = (views_by_hour[current_hour.to_s] || 0) + 1
    stat.update!(views_by_hour: views_by_hour)
    
    # Tracking géolocalisation amélioré
    location_to_save = location.presence || get_location_from_ip(user_ip)
    if location_to_save.present? && location_to_save != 'Localisation inconnue'
      locations = stat.visitor_locations || {}
      locations[location_to_save] = (locations[location_to_save] || 0) + 1
      stat.update!(visitor_locations: locations)
    else
      # Fallback pour localisation inconnue
      locations = stat.visitor_locations || {}
      locations['Localisation inconnue'] = (locations['Localisation inconnue'] || 0) + 1
      stat.update!(visitor_locations: locations)
    end
    
    # Tracking device type
    if user_agent.present?
      device_type = detect_device_type(user_agent)
      devices = stat.device_types || {}
      devices[device_type] = (devices[device_type] || 0) + 1
      stat.update!(device_types: devices)
    end
    
    # Session duration corrigé (conversion millisecondes -> secondes)
    if session_start.present?
      begin
        # Conversion millisecondes en secondes
        session_start_seconds = session_start.to_i / 1000
        duration = Time.current.to_i - session_start_seconds
        
        # Validation : durée positive et raisonnable (max 2 heures)
        if duration > 0 && duration < 7200
          update_avg_session_duration(stat, duration)
          Rails.logger.info "Session duration: #{duration}s for artisan #{artisan_id}"
        else
          Rails.logger.warn "Invalid session duration: #{duration}s for artisan #{artisan_id}"
        end
      rescue => e
        Rails.logger.error "Error calculating session duration: #{e.message}"
      end
    end
    
    stat
  end
  
  def self.track_contact_click(artisan_id, time_on_page: nil)
    date = Date.current
    stat = find_or_create_stat(artisan_id, date)
    
    stat.increment!(:contact_clicks)
    
    # Tracking du temps avant contact (conversion millisecondes -> secondes)
    if time_on_page.present?
      time_in_seconds = time_on_page.to_i / 1000 # Conversion ms -> s
      if time_in_seconds > 0 && time_in_seconds < 7200 # Max 2h
        stat.increment!(:contact_count_for_timing)
        new_total = stat.total_time_to_contact + time_in_seconds
        stat.update!(total_time_to_contact: new_total)
        Rails.logger.info "Time to contact: #{time_in_seconds}s for artisan #{artisan_id}"
      end
    end
    
    stat
  end
  
  private
  
  def self.find_or_create_stat(artisan_id, date)
    ArtisanStatistic.find_or_create_by(artisan_id: artisan_id, date: date) do |stat|
      stat.profile_views = 0
      stat.contact_clicks = 0
      stat.unique_visitors = 0
      stat.views_by_hour = {}
      stat.visitor_locations = {}
      stat.device_types = {}
      stat.avg_session_duration = 0.0
      stat.return_visitors = 0
      stat.total_time_to_contact = 0
      stat.contact_count_for_timing = 0
    end
  end
  
  def self.detect_device_type(user_agent)
    case user_agent.downcase
    when /mobile|android|iphone/
      'mobile'
    when /tablet|ipad/
      'tablet'
    else
      'desktop'
    end
  end
  
  # Géolocalisation côté serveur comme fallback
  def self.get_location_from_ip(ip)
    return 'Localisation inconnue' unless ip.present? && ip != '127.0.0.1' && ip != '::1'
    
    begin
      # Utilisation d'une API gratuite côté serveur
      require 'net/http'
      require 'json'
      
      uri = URI("http://ip-api.com/json/#{ip}?lang=fr")
      response = Net::HTTP.get_response(uri)
      
      if response.code == '200'
        data = JSON.parse(response.body)
        if data['status'] == 'success'
          city = data['city']
          region = data['regionName']
          country = data['country']
          
          # Formatage de la localisation
          if city.present? && region.present?
            return "#{city}, #{region}"
          elsif region.present?
            return region
          elsif country.present?
            return country
          end
        end
      end
    rescue => e
      Rails.logger.error "Geolocation API error: #{e.message}"
    end
    
    'Localisation inconnue'
  end
  
  def self.update_avg_session_duration(stat, new_duration)
    current_avg = stat.avg_session_duration || 0
    current_views = stat.profile_views - 1 # On vient d'incrémenter
    
    if current_views <= 0
      new_avg = new_duration.to_f
    else
      new_avg = ((current_avg * current_views) + new_duration) / stat.profile_views.to_f
    end
    
    stat.update!(avg_session_duration: new_avg.round(2))
  end
end

