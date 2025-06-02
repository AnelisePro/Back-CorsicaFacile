class ExpertisesController < ApplicationController
  def index
    default_expertises = [
      "Antenniste", "Assainisseur", "Spécialiste balnéo", "Ingénieur en bâtiment", "Opérateur de centrale à béton",
      "Calorifugeur", "Canalisateur", "Chapiste", "Charpentier", "Chef de chantier", "Chauffagiste",
      "Cheministe/Fumisterie", "Cloisonneur", "Climaticien", "Conducteur d'engins de chantier", "Conducteur de travaux",
      "Cordiste", "Cordonnier", "Couturier", "Couvreur", "Cuisiniste", "Déboucheur", "Déménageur", "Démolisseur",
      "Dessinateur-projeteur", "Désamianteur", "Désinsectiseur", "Diagnostiqueur", "Ébéniste", "Monteur échafaudeur",
      "Électricien", "Économiste de la construction", "Technicien en électroménager", "Enduiseur",
      "Nettoyage/entretien de bâtiments", "Installateur/réparateur d'escaliers mécaniques", "Étancheur", "Façadier",
      "Ferronnier", "Forgeron", "Foreur", "Géomètre-topographe", "Spécialiste du goudronnage", "Poseur de gouttière",
      "Graveur", "Grutier", "Technicien en traitement de l'humidité", "Installateur de systèmes de sécurité incendie",
      "Installateur de mobilier", "Installateur de systèmes de sécurité", "Installateur de systèmes photovoltaïques",
      "Installeteur de systèmes d'irrigation", "Isolateur", "Jointeur", "Jardinier", "Maçon", "Marbrier", "Menuisier",
      "Installateur/réparateur de monte-charges", "Multi-services", "Installateur/réparateur de paratonnerres",
      "Paysagiste", "Peintre", "Pisciniste", "Plâtrier/Plaquiste", "Plombier", "Spécialiste du PMR",
      "Installateur/réparateur de portes automatiques et tambours", "Poseur de revêtement de sol", "Potier", "Ramoneur",
      "Restaurateur de meubles", "Serrurier", "Spécialiste des terrasses en bois", "Spécialiste du vitrail",
      "Tailleur de pierre", "Technicien du traitement de l'eau", "Terrassier", "Poseur de toiles tendues", "Vitrier",
      "Installateur/réparateur de volets roulants", "Wifi télécom", "Zingueur"
    ]

    # Expertises sauvegardées dans la BDD
    artisan_expertises = Expertise.pluck(:name)

    # Fusionner et dédupliquer
    expertises = (default_expertises + artisan_expertises).uniq.sort

    render json: expertises
  end
end

