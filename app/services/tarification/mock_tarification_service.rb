module Tarification
  class MockTarificationService
    def tarif(entity, date, activity)
      tarif = nil
      if activity.id < 50
        # quantité PMA
        tarifs = [4.0, 115.0, 82.0, 206.0, 123, 41.0, 12.0, 240.0, 103.0, 200.0, 370.0, 40.0, 103.0, 60.0]
        tarif = tarifs[activity.id - 1]
      elsif activity.id < 100
        # quantité PCA
        tarifs = [15_000, 17_500, 12_250, 19_250, 35_000, 0, 65_000, 22_750, 26_250, 5000, 330, 5572, 655, 50_075]
        tarif = tarifs[activity.id - 51]
      elsif activity.id < 200
        # qualité
        tarifs = [24, 23, 25, 42, 17, 54, 28, 20, 23, 15]
        tarif = tarifs[activity.id - 100]
      end
      raise "no tarif for #{entity}, #{date} #{activity.name} #{activity.id}" unless tarif
      tarif
    end
  end
end
