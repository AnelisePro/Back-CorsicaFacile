class Api::V1::ArtisansController < ApplicationController
  def premium
    artisans = Artisan
      .includes(:expertises, avatar_attachment: :blob)
      .where(membership_plan: 'Premium')
      .where(verified: true)
      .where(banned_at: nil)

    render json: artisans.map { |a| 
      {
        id: a.id,
        company_name: a.company_name,
        city: a.address,
        avatar_url: a.avatar.attached? ? url_for(a.avatar) : nil,
        expertises: a.expertises.map(&:name),
        profile_url: "/artisans/#{a.id}"
      }
    }
  end
end
