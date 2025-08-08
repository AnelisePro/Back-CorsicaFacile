class Api::V1::ArtisanStatisticsController < ApplicationController
  before_action :authenticate_artisan!
  before_action :check_statistics_access
  
  def index
    period = params[:period] || 'month'
    
    stats = case params[:type]
    when 'basic'
      get_basic_statistics(period)
    when 'advanced'
      return render json: { error: 'Premium requis' }, status: :forbidden unless current_artisan.can_view_advanced_stats?
      get_advanced_statistics(period)
    else
      get_all_available_statistics(period)
    end
    
    render json: stats
  end
  
  private
  
  def check_statistics_access
    unless current_artisan.can_view_basic_stats?
      render json: { error: 'Formule Pro ou Premium requise' }, status: :forbidden
    end
  end
  
  def get_basic_statistics(period)
    stats = current_artisan.artisan_statistics.send("current_#{period}")
    
    total_views = stats.sum(:profile_views)
    total_contacts = stats.sum(:contact_clicks)
    conversion_rate = total_views > 0 ? (total_contacts.to_f / total_views * 100).round(2) : 0.0
    
    # Reviews stats
    reviews = current_artisan.reviews
    average_rating = reviews.any? ? reviews.average(:rating).to_f.round(1) : 0.0
    total_reviews = reviews.count
    
    {
      type: 'basic',
      period: period,
      data: {
        total_profile_views: total_views,
        total_contact_clicks: total_contacts,
        conversion_rate: conversion_rate,
        average_rating: average_rating,
        total_reviews: total_reviews
      }
    }
  end
  
  def get_advanced_statistics(period)
    basic_stats = get_basic_statistics(period)
    stats = current_artisan.artisan_statistics.send("current_#{period}")
    
    # Évolution dans le temps
    views_evolution = stats.group(:date).sum(:profile_views)
    contacts_evolution = stats.group(:date).sum(:contact_clicks)
    
    # Agrégation des données JSON
    all_locations = {}
    all_devices = {}
    total_session_duration = 0.0
    total_return_visitors = 0
    
    stats.each do |stat|
      # Locations
      stat.visitor_locations.each do |location, count|
        all_locations[location] = (all_locations[location] || 0) + count
      end
      
      # Devices
      stat.device_types.each do |device, count|
        all_devices[device] = (all_devices[device] || 0) + count
      end
      
      total_session_duration += stat.avg_session_duration
      total_return_visitors += stat.return_visitors
    end
    
    # Distribution des notes
    reviews_distribution = current_artisan.reviews.group(:rating).count
    
    basic_stats[:data].merge!({
      views_evolution: views_evolution,
      contacts_evolution: contacts_evolution,
      visitor_locations: all_locations.sort_by { |_, count| -count }.first(10),
      device_breakdown: all_devices,
      avg_session_duration: stats.count > 0 ? (total_session_duration / stats.count).round(2) : 0.0,
      return_visitor_rate: calculate_return_rate(stats),
      reviews_distribution: reviews_distribution,
      avg_time_to_contact: calculate_avg_time_to_contact(period)
    })
    
    basic_stats[:type] = 'advanced'
    basic_stats
  end
  
  def get_all_available_statistics(period)
    if current_artisan.can_view_advanced_stats?
      get_advanced_statistics(period)
    else
      get_basic_statistics(period)
    end
  end
  
  def calculate_return_rate(stats)
    total_views = stats.sum(:profile_views)
    total_returns = stats.sum(:return_visitors)
    total_views > 0 ? (total_returns.to_f / total_views * 100).round(2) : 0.0
  end
  
  def calculate_avg_time_to_contact(period)
    # Logique pour calculer le temps moyen avant premier contact
    # Ceci nécessiterait un tracking plus avancé
    "2h 30min" # Placeholder
  end
end
