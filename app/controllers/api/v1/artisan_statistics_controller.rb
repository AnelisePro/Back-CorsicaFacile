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
    unique_visitors = stats.sum(:unique_visitors)
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
        unique_visitors: unique_visitors,
        total_contact_clicks: total_contacts,
        conversion_rate: conversion_rate,
        average_rating: average_rating,
        total_reviews: total_reviews,
        last_updated: Time.current.iso8601
      }
    }
  end
  
  def get_advanced_statistics(period)
    basic_stats = get_basic_statistics(period)
    stats = current_artisan.artisan_statistics.send("current_#{period}")
    
    # Évolution dans le temps
    views_evolution = stats.group(:date).sum(:profile_views)
                          .transform_keys { |date| date.strftime('%d/%m') }
    contacts_evolution = stats.group(:date).sum(:contact_clicks)
                             .transform_keys { |date| date.strftime('%d/%m') }
    
    # Top locations (limité aux 10 premières)
    all_locations = {}
    stats.each do |stat|
      (stat.visitor_locations || {}).each do |location, count|
        all_locations[location] = (all_locations[location] || 0) + count
      end
    end
    top_locations = all_locations.sort_by { |_, count| -count }.first(10)
    
    # Device breakdown
    all_devices = {}
    stats.each do |stat|
      (stat.device_types || {}).each do |device, count|
        all_devices[device] = (all_devices[device] || 0) + count
      end
    end
    
    # Moyennes
    avg_session_duration = stats.where('avg_session_duration > 0').average(:avg_session_duration)&.round(1) || 0.0
    total_return = stats.sum(:return_visitors)
    total_unique = stats.sum(:unique_visitors)
    return_rate = total_unique > 0 ? (total_return.to_f / total_unique * 100).round(1) : 0.0
    
    # Temps moyen avant contact
    total_time = stats.sum(:total_time_to_contact)
    contact_count = stats.sum(:contact_count_for_timing)
    avg_time_to_contact = contact_count > 0 ? 
                         ArtisanStatistic.new(total_time_to_contact: total_time, contact_count_for_timing: contact_count)
                                        .avg_time_to_contact_formatted : "N/A"
    
    # Distribution des avis
    reviews_distribution = current_artisan.reviews.group(:rating).count
    
    # Heure de pointe
    all_hours = {}
    stats.each do |stat|
      (stat.views_by_hour || {}).each do |hour, count|
        all_hours[hour.to_i] = (all_hours[hour.to_i] || 0) + count
      end
    end
    peak_hour = all_hours.max_by { |_, count| count }&.first || 12
    
    basic_stats[:data].merge!({
      views_evolution: views_evolution,
      contacts_evolution: contacts_evolution,
      visitor_locations: top_locations,
      device_breakdown: all_devices,
      avg_session_duration: avg_session_duration,
      return_visitor_rate: return_rate,
      reviews_distribution: reviews_distribution,
      avg_time_to_contact: avg_time_to_contact,
      peak_hour: "#{peak_hour}h",
      views_by_hour: all_hours.sort.to_h
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
end

