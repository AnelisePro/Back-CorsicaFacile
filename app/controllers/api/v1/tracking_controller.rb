class Api::V1::TrackingController < ApplicationController
  before_action :set_artisan, only: [:profile_view, :contact_click]
  
  # POST /api/v1/tracking/artisans/:artisan_id/view
  def profile_view
    begin
      ArtisanStatisticsService.track_profile_view(
        @artisan.id,
        user_ip: request.remote_ip,
        user_agent: request.user_agent,
        location: params[:location],
        session_start: params[:session_start]&.to_i
      )
      
      render json: { status: 'success' }
    rescue => e
      Rails.logger.error "Tracking error: #{e.message}"
      render json: { status: 'error', message: e.message }, status: :unprocessable_entity
    end
  end
  
  # POST /api/v1/tracking/artisans/:artisan_id/contact
  def contact_click
    begin
      ArtisanStatisticsService.track_contact_click(
        @artisan.id,
        time_on_page: params[:time_on_page]&.to_i
      )
      
      render json: { status: 'success' }
    rescue => e
      Rails.logger.error "Tracking error: #{e.message}"
      render json: { status: 'error', message: e.message }, status: :unprocessable_entity
    end
  end
  
  # 🆕 NOUVELLE MÉTHODE : GET /api/v1/tracking/reverse_geocode
  def reverse_geocode
    lat = params[:lat]
    lon = params[:lon]
    
    return render json: { error: 'Coordonnées manquantes' }, status: 400 unless lat && lon
    
    begin
      require 'net/http'
      require 'json'
      
      url = "https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=#{lat}&lon=#{lon}&zoom=10&addressdetails=1"
      uri = URI(url)
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      
      request = Net::HTTP::Get.new(uri)
      request['User-Agent'] = 'ArtisanTracker/1.0'
      
      response = http.request(request)
      
      if response.code == '200'
        data = JSON.parse(response.body)
        
        city = data.dig('address', 'city') || 
               data.dig('address', 'town') || 
               data.dig('address', 'village') ||
               data.dig('address', 'municipality')
               
        region = data.dig('address', 'state') || 
                 data.dig('address', 'region')
        
        if city && region
          location = "#{city}, #{region}"
          render json: { location: location, details: data }
        else
          render json: { error: 'Localisation non trouvée' }, status: 404
        end
      else
        render json: { error: 'Erreur API externe' }, status: 500
      end
      
    rescue => e
      Rails.logger.error "Reverse geocoding error: #{e.message}"
      render json: { error: e.message }, status: 500
    end
  end
  
  private
  
  def set_artisan
    @artisan = Artisan.find(params[:artisan_id])
  rescue ActiveRecord::RecordNotFound
    render json: { status: 'error', message: 'Artisan not found' }, status: :not_found
  end
end
