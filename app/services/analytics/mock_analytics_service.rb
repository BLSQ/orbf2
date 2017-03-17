module Analytics
  class MockAnalyticsService
    def entities
      [
        Analytics::Entity.new(1, "Maqokho HC", ["hospital_group_id"]),
        Analytics::Entity.new(2, "fosa", ["fosa_group_id"])
      ]
    end

    def activity_and_values(package, date)
      # build from data element group and analytics api
      activity_and_values_quantity_pma = [ # PMA
        [new_activity(1, "Number of new outpatient consultations for curative care consultations"),
         [new_values(655.0, 655.0), new_values(652.0, 652.0), new_values(654.0, 654.0)]],
        [new_activity(2, "Number of pregnant women having their first antenatal care visit in the first trimester"),
         [new_values(0.0, 0.0), new_values(1.0, 1.0), new_values(0.0, 1.0)]],
        [new_activity(3, "Number of pregnant women with fourth or last antenatal care visit in last month of pregnancy"),
         [new_values(2.0, 0.0), new_values(2.0, 0.0), new_values(2.0, 0.0)]],
        [new_activity(4, "Number of new outpatient consultations for curative care consultations 2"),
         [new_values(7.0, 7.0), new_values(7.0, 7.0), new_values(7.0, 7.0)]],
        [new_activity(5, "Number of women delivering in health facilities"),
         [new_values(6.0, 6.0), new_values(6.0, 6.0), new_values(6.0, 6.0)]],
        [new_activity(6, "Number of women with newborns with a postnatal care visit between 24 hours and 1 week of delivery"),
         for_quarter(new_values(0.0, 0.0))],
        [new_activity(7, "Number of patients referred who arrive at the District/local hospital"),
         for_quarter(new_values(96.0, 96.0))],
        [new_activity(8, "Number of new and follow up users of short-term modern contraceptive methods"),
         for_quarter(new_values(0.0, 0.0))],
        [new_activity(9, "Number of children under 1 year fully immunized"),
         for_quarter(new_values(13.0, 13.0))],
        [new_activity(10, "Number of malnourished children detected and ?treated?"),
         for_quarter(new_values(1.0, 1.0))],
        [new_activity(11, "Number of notified HIV-Positive tuberculosis patients completed treatment and/or cured"),
         for_quarter(new_values(0.0, 0.0))],
        [new_activity(12, "Number of HIV+ TB patients initiated and currently on ART"),
         for_quarter(new_values(1.0, 1.0))],
        [new_activity(13, "Number of children born to HIV-Positive women who receive a confirmatory HIV test at 18 months after birth"),
         for_quarter(new_values(1.0, 1.0))],
        [new_activity(14, "Number of children (0-14 years) with HIV infection initiated and currently on ART"),
         for_quarter(new_values(1.0, 1.0))]
      ]

      # PCA
      activity_and_values_quantity_pca = [
        [new_activity(51, "Contre référence de l'hopital arrivée au CS"),
         for_quarter(new_values(144, 136, 0.0))],
        [new_activity(52, "Femmes enceintes dépistées séropositive et mise sous traitement ARV (tri prophylaxie/trithérapie)"),
         for_quarter(new_values(0, 0, 0.0))],
        [new_activity(53, "Clients sous traitement ARV suivi pendant les 6 premiers mois"),
         for_quarter(new_values(5, 5, 0.0))],
        [new_activity(54, "Enfants éligibles au traitement ARV et qui ont été initié au traitement ARV au cours du mois"),
         for_quarter(new_values(0, 0, 0.0))],
        [new_activity(55, "Accouchement dystocique effectué chez une parturiente référée des Centres de Santé"),
         for_quarter(new_values(46, 46, 0.0))],
        [new_activity(56, "Césarienne"),
         for_quarter(new_values(45, 45, 0.0))],
        [new_activity(57, "Intervention Chirurgicale en service de Gynécologie Obstétrique et Chirurgie"),
         for_quarter(new_values(47, 47, 0.0))],
        [new_activity(58, "Depistage des cas TBC positifs"),
         for_quarter(new_values(2, 2, 0.0))],
        [new_activity(59, "Nombre de cas TBC traites et gueris"),
         for_quarter(new_values(3, 3, 0.0))],
        [new_activity(60, "IST diagnostiqués et traités"),
         for_quarter(new_values(2, 2, 0.0))],
        [new_activity(61, "Diagnostic et traitement des cas de paludisme simple chez les enfants"),
         for_quarter(new_values(18, 18, 0.0))],
        [new_activity(62, "Diagnostic et traitement des cas de paludisme grave chez les enfants"),
         for_quarter(new_values(33, 33, 0.0))],
        [new_activity(63, "Diagnostic et traitement des cas de paludisme simple chez les femmes enceintes"),
         for_quarter(new_values(0, 0, 0.0))],
        [new_activity(64, "Diagnostic et traitement des cas de paludisme grave chez les femmes enceintes"),
         for_quarter(new_values(0, 0, 0.0))]
      ]

      activity_and_values_quality = [
        [new_activity(100, "General Management"),
         new_values(19.0)],
        [new_activity(101, "Environmental Health"),
         new_values(23.0)],
        [new_activity(102, "General consultations"),
         new_values(25)],
        [new_activity(103, "Child Survival"),
         new_values(30)],
        [new_activity(104, "Family Planning"),
         new_values(9)],
        [new_activity(105, "Maternal Health"),
         new_values(45)],
        [new_activity(106, "STI, HIV and TB"),
         new_values(22)],
        [new_activity(107, "Essential drugs Management"),
         new_values(20)],
        [new_activity(108, "Priority Drugs and supplies"),
         new_values(20)],
        [new_activity(109, "Community based services"),
         new_values(12)]

      ]

      return limit_values_to_date(activity_and_values_quantity_pca, date) if package.name.downcase.include?("quantity pca")
      return limit_values_to_date(activity_and_values_quantity_pma, date) if package.name.downcase.include?("quantity pma")
      return activity_and_values_quality if package.name.downcase.include?("quality")
      raise "no data for #{name} and #{date}"
    end

    private

    def new_activity(id, name)
      ActivityForm.new(id: id, name: name)
    end

    def new_values(claimed = 0.0, verified = 0.0, validated = 0.0)
      Analytics::Values.new(nil, claimed: claimed, verified: verified, validated: validated, max_score: 10.0)
    end

    def for_quarter(value)
      quarter = []
      quarter << new_values(value.facts[:claimed], value.facts[:verified], value.facts[:validated])
      quarter << new_values(value.facts[:claimed] + 2, value.facts[:claimed] + 1, value.facts[:validated])
      quarter << new_values(value.facts[:claimed], value.facts[:claimed], value.facts[:validated])
      quarter
    end

    def limit_values_to_date(activity_and_values, date)
      current_quarter_end = Date.today.to_date.end_of_month
      quarter_dates = [(current_quarter_end - 2.months).end_of_month, (current_quarter_end - 1.month).end_of_month, current_quarter_end]
      index_to_keep = quarter_dates.index(date)
      raise "no data for #{date} vs #{quarter_dates}" unless index_to_keep
      filtered = activity_and_values.map do |activity, values|
        values[index_to_keep].date = date.to_date.end_of_month
        [activity, values[index_to_keep]]
      end
      filtered
    end
  end
end
