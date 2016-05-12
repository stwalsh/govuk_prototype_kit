module SmartAnswer
  class CalculateYourChildMaintenanceFlow < Flow
    def define
      content_id "42c2e944-7977-4297-b142-aa9406756dd2"
      name 'calculate-your-child-maintenance'
      status :published
      satisfies_need "100147"

      ## Q0
      multiple_choice :are_you_paying_or_receiving? do
        option :pay
        option :receive

        save_input_as :paying_or_receiving

        next_node do
          question :how_many_children_paid_for?
        end
      end

      ## Q1
      multiple_choice :how_many_children_paid_for? do
        option "1_child"
        option "2_children"
        option "3_children"

        precalculate :paying_or_receiving_text do
          paying_or_receiving == "pay" ? "paying" : "receiving"
        end

        precalculate :paying_or_receiving_hint do
          if paying_or_receiving == "pay"
            "Enter the total number of children - including children that you have family based arrangements for. They will be included in the calculation and you'll need to supply information about them when arranging Child Maintenance.".html_safe
          else
            "Enter children from 1 partner only and make a separate calculation for each partner."
          end
        end

        # rubocop:disable Style/SymbolProc
        calculate :number_of_children do |response|
          ## to_i will look for the first integer in the string
          response.to_i
        end
        # rubocop:enable Style/SymbolProc

        next_node do
          question :gets_benefits?
        end
      end

      ## Q2
      multiple_choice :gets_benefits? do
        save_input_as :benefits
        option "yes"
        option "no"

        precalculate :benefits_title do
          if paying_or_receiving == "pay"
            "Do you get any of these benefits?"
          else
            "Does the parent paying child maintenance get any of these benefits?"
          end
        end

        calculate :calculator do
          Calculators::ChildMaintenanceCalculator.new(number_of_children, benefits, paying_or_receiving)
        end

        next_node do |response|
          case response
          when 'yes'
            question :how_many_nights_children_stay_with_payee?
          when 'no'
            question :gross_income_of_payee?
          end
        end
      end

      ## Q3
      money_question :gross_income_of_payee? do
        precalculate :income_title do
          if paying_or_receiving == "pay"
            "What is your weekly gross income?"
          else
            "What is the weekly gross income of the parent paying child maintenance?"
          end
        end

        next_node_calculation :rate_type do |response|
          calculator.income = response
          calculator.rate_type
        end

        next_node do
          case rate_type
          when :nil
            outcome :nil_rate_result
          when :flat
            outcome :flat_rate_result
          else
            question :how_many_other_children_in_payees_household?
          end
        end
      end

      ## Q4
      value_question :how_many_other_children_in_payees_household?, parse: Integer do
        precalculate :number_of_children_title do
          if paying_or_receiving == "pay"
            "How many other children live in your household?"
          else
            "How many other children live in the household of the parent paying child maintenance?"
          end
        end

        calculate :calculator do |response|
          calculator.number_of_other_children = response
          calculator
        end
        next_node do
          question :how_many_nights_children_stay_with_payee?
        end
      end

      ## Q5
      multiple_choice :how_many_nights_children_stay_with_payee? do
        option 0
        option 1
        option 2
        option 3
        option 4

        precalculate :how_many_nights_title do
          if paying_or_receiving == "pay"
            "On average, how many nights a year do the children stay over with you?"
          else
            "On average, how many nights a year do the children stay over with the parent paying child maintenance?"
          end
        end

        calculate :child_maintenance_payment do |response|
          calculator.number_of_shared_care_nights = response.to_i
          sprintf("%.0f", calculator.calculate_maintenance_payment)
        end

        next_node_calculation :rate_type do |response|
          calculator.number_of_shared_care_nights = response.to_i
          calculator.rate_type
        end

        next_node do
          case rate_type
          when :nil
            outcome :nil_rate_result
          when :flat
            outcome :flat_rate_result
          else
            outcome :reduced_and_basic_rates_result
          end
        end
      end

      outcome :nil_rate_result

      outcome :flat_rate_result do
        precalculate :flat_rate_amount do
          sprintf('%.2f', calculator.base_amount)
        end
        precalculate :collect_fees do
          sprintf('%.2f', calculator.collect_fees)
        end
        precalculate :total_fees do
          sprintf('%.2f', calculator.total_fees(flat_rate_amount, collect_fees))
        end
        precalculate :total_yearly_fees do
          sprintf('%.2f', calculator.total_yearly_fees(collect_fees))
        end
      end

      outcome :reduced_and_basic_rates_result do
        precalculate :rate_type_formatted do
          rate_type = calculator.rate_type
          if rate_type.to_s == 'basic_plus'
            'basic plus'
          else
            rate_type.to_s
          end
        end
        precalculate :child_maintenance_payment do
          sprintf('%.2f', child_maintenance_payment)
        end
        precalculate :collect_fees do
          sprintf('%.2f', calculator.collect_fees_cmp(child_maintenance_payment))
        end
        precalculate :total_fees do
          sprintf('%.2f', calculator.total_fees_cmp(child_maintenance_payment, collect_fees))
        end
        precalculate :total_yearly_fees do
          sprintf('%.2f', calculator.total_yearly_fees(collect_fees))
        end
      end
    end
  end
end
