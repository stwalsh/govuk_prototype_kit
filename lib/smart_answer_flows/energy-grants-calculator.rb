module SmartAnswer
  class EnergyGrantsCalculatorFlow < Flow
    def define
      content_id "20c0a04d-1db4-4828-bd40-bc99954ca5f9"
      name 'energy-grants-calculator'
      status :published
      satisfies_need "100259"

      # Q1
      multiple_choice :what_are_you_looking_for? do
        option :help_with_fuel_bill
        option :help_energy_efficiency
        option :help_boiler_measure
        option :all_help
        save_input_as :which_help

        calculate :flat_type do
          nil
        end
        calculate :may_qualify_for_affordable_warmth_obligation do
          nil
        end
        calculate :incomesupp_jobseekers_1 do
          nil
        end
        calculate :incomesupp_jobseekers_2 do
          nil
        end
        calculate :age_variant do
          nil
        end

        calculate :bills_help do |response|
          %w(help_with_fuel_bill).include?(response) ? :bills_help : nil
        end
        calculate :measure_help do |response|
          %w(help_energy_efficiency help_boiler_measure).include?(response) ? :measure_help : nil
        end
        calculate :both_help do |response|
          %w(all_help).include?(response) ? :both_help : nil
        end

        calculate :warm_home_discount_amount do
          ''
        end

        next_node do |response|
          case response
          when 'help_with_fuel_bill'
            question :what_are_your_circumstances? # Q2
          else
            question :what_are_your_circumstances_without_bills_help? # Q2A
          end
        end
      end

      # Q2
      checkbox_question :what_are_your_circumstances? do
        option :benefits
        option :property
        option :permission
        option :social_housing

        calculate :circumstances do |response|
          response.split(",")
        end

        calculate :benefits_claimed do
          []
        end

        validate(:error_perm_prop_house) { |r| ! r.include?('permission,property,social_housing') }
        validate(:error_prop_house) { |r| ! r.include?('property,social_housing') }
        validate(:error_perm_prop) { |r| ! r.include?('permission,property') }
        validate(:error_perm_house) { |r| ! r.include?('permission,social_housing') }

        next_node do
          question :date_of_birth? # Q3
        end
      end

      # Q2A
      checkbox_question :what_are_your_circumstances_without_bills_help? do
        option :benefits
        option :property
        option :permission

        calculate :circumstances do |response|
          response.split(",")
        end

        calculate :benefits_claimed do
          []
        end

        validate(:error_perm_prop) { |r| ! r.include?('permission,property') }

        next_node_calculation(:measure) {
          %w(help_energy_efficiency help_boiler_measure).include?(which_help)
        }

        next_node do |response|
          if both_help
            question :date_of_birth?
          elsif measure
            if response == 'benefits'
              question :which_benefits?
            else
              question :when_property_built?
            end
          end
        end
      end

      # Q3
      date_question :date_of_birth? do
        date_of_birth_defaults

        calculate :age_variant do |response|
          dob = response
          if dob < Date.new(1951, 7, 5)
            :winter_fuel_payment
          elsif dob < 60.years.ago(Date.today + 1)
            :over_60
          end
        end

        next_node do
          if circumstances.include?('benefits')
            question :which_benefits?
          elsif bills_help
            outcome :outcome_help_with_bills # outcome 1
          else
            question :when_property_built? # Q6
          end
        end
      end

      # Q4
      checkbox_question :which_benefits? do
        option :pension_credit
        option :income_support
        option :jsa
        option :esa
        option :child_tax_credit
        option :working_tax_credit
        option :universal_credit

        calculate :benefits_claimed do |response|
          response.split(",")
        end
        calculate :incomesupp_jobseekers_2 do |response|
          if %w(working_tax_credit).include?(response)
            if age_variant == :over_60
              :incomesupp_jobseekers_2
            end
          end
        end

        next_node_calculation(:disabled_or_have_children_question) do |response|
          response == 'income_support' ||
            response == 'jsa' ||
            response == 'esa' ||
            response == 'working_tax_credit' ||
            response.include?('universal_credit') ||
            %w{child_tax_credit esa income_support jsa pension_credit}.all? { |key| response.include? key } ||
            %w{child_tax_credit esa income_support pension_credit}.all? { |key| response.include? key } ||
            %w{child_tax_credit esa jsa pension_credit}.all? { |key| response.include? key }
        end

        next_node do |response|
          if %w{pension_credit child_tax_credit}.include?(response)
            if bills_help
              outcome :outcome_help_with_bills # outcome 1
            else
              question :when_property_built? # Q6
            end
          elsif disabled_or_have_children_question
            question :disabled_or_have_children? # Q5
          elsif bills_help
            outcome :outcome_help_with_bills # outcome 1
          else
            question :when_property_built? # Q6
          end
        end
      end

      # Q5
      checkbox_question :disabled_or_have_children? do
        option :disabled
        option :disabled_child
        option :child_under_5
        option :child_under_16
        option :pensioner_premium
        option :work_support_esa

        calculate :incomesupp_jobseekers_1 do |response|
          case response
          when 'disabled', 'disabled_child', 'child_under_5', 'pensioner_premium'
            :incomesupp_jobseekers_1
          end
        end
        calculate :incomesupp_jobseekers_2 do |response|
          case response
          when 'child_under_16', 'work_support_esa'
            if circumstances.include?('social_housing') || (benefits_claimed.include?('working_tax_credit') && age_variant != :over_60)
              nil
            else
              :incomesupp_jobseekers_2
            end
          end
        end

        calculate :may_qualify_for_affordable_warmth_obligation do |response|
          response != 'none' && benefits_claimed.include?('universal_credit')
        end

        next_node do
          if bills_help
            outcome :outcome_help_with_bills # outcome 1
          else
            question :when_property_built? # Q6
          end
        end
      end

      # Q6
      multiple_choice :when_property_built? do
        option :"on-or-after-1995"
        option :"1940s-1984"
        option :"before-1940"
        save_input_as :property_age

        calculate :modern do |response|
          %w(on-or-after-1995).include?(response)
        end
        calculate :older do |response|
          %w(1940s-1984).include?(response)
        end
        calculate :historic do |response|
          %w(before-1940).include?(response)
        end

        next_node do
          question :type_of_property?
        end
      end

      # Q7a
      multiple_choice :type_of_property? do
        option :house
        option :flat
        save_input_as :property_type

        next_node do |response|
          case response
          when 'house'
            if modern
              question :home_features_modern?
            elsif older
              question :home_features_older?
            else
              question :home_features_historic?
            end
          else
            question :type_of_flat?
          end
        end
      end

      # Q7b
      multiple_choice :type_of_flat? do
        option :top_floor
        option :ground_floor
        save_input_as :flat_type

        next_node do
          if modern
            question :home_features_modern?
          elsif older
            question :home_features_older?
          else
            question :home_features_historic?
          end
        end
      end

      # Q8a modern
      checkbox_question :home_features_modern? do
        option :mains_gas
        option :electric_heating
        option :loft_attic_conversion
        option :draught_proofing

        calculate :features do |response|
          response.split(",")
        end

        next_node_calculation(:modern_and_gas_and_electric_heating) do |response|
          modern && response.include?('mains_gas') && response.include?('electric_heating')
        end

        next_node_calculation(:measure_help_and_property_permission_circumstance) do
          measure_help && (circumstances & %w(property permission)).any?
        end

        next_node_calculation(:no_benefits) { circumstances.exclude?('benefits') }

        next_node_calculation(:property_permission_circumstance_and_benefits) do
          (circumstances & %w(property permission)).any? && ((benefits_claimed & %w(child_tax_credit esa pension_credit)).any? || incomesupp_jobseekers_1 || incomesupp_jobseekers_2)
        end

        next_node do
          if modern_and_gas_and_electric_heating
            outcome :outcome_no_green_deal_no_energy_measures
          elsif measure_help_and_property_permission_circumstance
            outcome :outcome_measures_help_green_deal
          elsif no_benefits
            outcome :outcome_bills_and_measures_no_benefits
          elsif property_permission_circumstance_and_benefits
            outcome :outcome_bills_and_measures_on_benefits_eco_eligible
          else
            outcome :outcome_bills_and_measures_on_benefits_not_eco_eligible
          end
        end
      end

      # Q8b
      checkbox_question :home_features_historic? do
        option :mains_gas
        option :electric_heating
        option :modern_double_glazing
        option :loft_attic_conversion
        option :loft_insulation
        option :solid_wall_insulation
        option :modern_boiler
        option :draught_proofing

        calculate :features do |response|
          response.split(",")
        end

        next_node_calculation(:measure_help_and_property_permission_circumstance) do
          measure_help && (circumstances & %w(property permission)).any?
        end

        next_node_calculation(:no_benefits) { circumstances.exclude?('benefits') }

        next_node_calculation(:property_permission_circumstance_and_benefits) do
          (circumstances & %w(property permission)).any? && ((benefits_claimed & %w(child_tax_credit esa pension_credit)).any? || incomesupp_jobseekers_1 || incomesupp_jobseekers_2)
        end

        next_node do
          if measure_help_and_property_permission_circumstance
            outcome :outcome_measures_help_green_deal
          elsif no_benefits
            outcome :outcome_bills_and_measures_no_benefits
          elsif property_permission_circumstance_and_benefits
            outcome :outcome_bills_and_measures_on_benefits_eco_eligible
          else
            outcome :outcome_bills_and_measures_on_benefits_not_eco_eligible
          end
        end
      end

      # Q8c
      checkbox_question :home_features_older? do
        option :mains_gas
        option :electric_heating
        option :modern_double_glazing
        option :loft_attic_conversion
        option :loft_insulation
        option :solid_wall_insulation
        option :cavity_wall_insulation
        option :modern_boiler
        option :draught_proofing

        calculate :features do |response|
          response.split(",")
        end

        next_node_calculation(:measure_help_and_property_permission_circumstance) do
          measure_help && (circumstances & %w(property permission)).any?
        end

        next_node_calculation(:no_benefits) { circumstances.exclude?('benefits') }

        next_node_calculation(:property_permission_circumstance_and_benefits) do
          (circumstances & %w(property permission)).any? && ((benefits_claimed & %w(child_tax_credit esa pension_credit)).any? || incomesupp_jobseekers_1 || incomesupp_jobseekers_2)
        end

        next_node do
          if measure_help_and_property_permission_circumstance
            outcome :outcome_measures_help_green_deal
          elsif no_benefits
            outcome :outcome_bills_and_measures_no_benefits
          elsif property_permission_circumstance_and_benefits
            outcome :outcome_bills_and_measures_on_benefits_eco_eligible
          else
            outcome :outcome_bills_and_measures_on_benefits_not_eco_eligible
          end
        end
      end

      outcome :outcome_help_with_bills do
        precalculate :may_qualify_for_affordable_warmth_obligation do
          may_qualify_for_affordable_warmth_obligation
        end
        precalculate :incomesupp_jobseekers_1 do
          incomesupp_jobseekers_1
        end
      end

      outcome :outcome_measures_help_green_deal do
        precalculate :flat_type do
          flat_type
        end
      end

      outcome :outcome_bills_and_measures_no_benefits do
        precalculate :flat_type do
          flat_type
        end
        precalculate :under_green_deal do
          both_help && !circumstances.include?('benefits')
        end
      end

      outcome :outcome_bills_and_measures_on_benefits_eco_eligible do
        precalculate :may_qualify_for_affordable_warmth_obligation do
          may_qualify_for_affordable_warmth_obligation
        end
        precalculate :incomesupp_jobseekers_1 do
          incomesupp_jobseekers_1
        end
        precalculate :flat_type do
          flat_type
        end
        precalculate :under_green_deal do
          !((both_help && circumstances.include?('property')) || (circumstances.include?('permission') && circumstances.include?('pension_credit')) || incomesupp_jobseekers_1 || incomesupp_jobseekers_2 || (benefits_claimed & %w(esa child_tax_credit working_tax_credit)).any?)
        end
      end

      outcome :outcome_bills_and_measures_on_benefits_not_eco_eligible do
        precalculate :may_qualify_for_affordable_warmth_obligation do
          may_qualify_for_affordable_warmth_obligation
        end
        precalculate :incomesupp_jobseekers_1 do
          incomesupp_jobseekers_1
        end
        precalculate :flat_type do
          flat_type
        end
        precalculate :under_green_deal do
          both_help && age_variant == :over_60 && (benefits_claimed & %w(esa child_tax_credit working_tax_credit) || incomesupp_jobseekers_1 || incomesupp_jobseekers_2)
        end
      end

      outcome :outcome_no_green_deal_no_energy_measures
    end
  end
end
