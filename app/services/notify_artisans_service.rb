class NotifyArtisansService
  def initialize(besoin)
    @besoin = besoin
  end

  def call
    expertise = @besoin.type_prestation
    artisans = Artisan.joins(:expertises).where(expertises: { name: expertise })

    artisans.find_each do |artisan|
      artisan.notifications.create!(
        message: "Nouveau besoin: #{@besoin.type_prestation}",
        link: "/artisan/besoins/#{@besoin.id}",
        read: false
      )
    end
  end
end