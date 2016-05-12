module SmartAnswer
  class ChildcareCostsForTaxCreditsFlow < Flow
    def define
      content_id "f8c575b7-d7a2-41a4-9911-069a06f1a2cc"
      name 'childcare-costs-for-tax-credits'
      status :published
      satisfies_need "100422"

      #Q1
      multiple_choice :currently_claiming? do
        option :yes
        option :no

        calculate :cost_change_4_weeks do
          nil
        end

        next_node do |response|
          case response
          when 'yes'
            question :have_costs_changed? #Q3
          when 'no'
            question :how_often_use_childcare? #Q2
          end
        end
      end

      #Q2
      multiple_choice :how_often_use_childcare? do
        option :regularly_less_than_year
        option :regularly_more_than_year
        option :only_short_while

        next_node do |response|
          case response
          when 'regularly_less_than_year'
            question :how_often_pay_1? #Q4
          when 'regularly_more_than_year'
            question :pay_same_each_time? #Q11
          when 'only_short_while'
            outcome :call_helpline_detailed #O1
          end
        end
      end

      #Q3
      multiple_choice :have_costs_changed? do
        option :yes
        option :no

        next_node do |response|
          case response
          when 'yes'
            question :how_often_pay_2? #Q5
          when 'no'
            outcome :no_change #O2
          end
        end
      end

      #Q4
      multiple_choice :how_often_pay_1? do
        option :weekly_same_amount
        option :weekly_diff_amount
        option :monthly_same_amount
        option :monthly_diff_amount
        option :other

        next_node do |response|
          case response
          when 'weekly_same_amount'
            question :round_up_weekly #O3
          when 'weekly_diff_amount'
            question :how_much_52_weeks_1? #Q7
          when 'monthly_same_amount'
            question :how_much_each_month? #Q10
          when 'monthly_diff_amount', 'other'
            question :how_much_12_months_1? #Q6
          end
        end
      end

      #Q5
      multiple_choice :how_often_pay_2? do
        option :weekly_same_amount
        option :weekly_diff_amount
        option :monthly_same_amount
        option :monthly_diff_amount
        option :other

        next_node do |response|
          case response
          when 'weekly_same_amount'
            question :new_weekly_costs? #Q17
          when 'weekly_diff_amount', 'other'
            question :how_much_52_weeks_2? #Q8
          when 'monthly_same_amount'
            question :new_monthly_cost? #Q19
          when 'monthly_diff_amount'
            question :how_much_12_months_2? #Q9
          end
        end
      end

      #Q6
      money_question :how_much_12_months_1? do
        calculate :weekly_cost do |response|
          Calculators::ChildcareCostCalculator.weekly_cost(response)
        end
        next_node do
          outcome :weekly_costs_are_x #O4
        end
      end

      #Q7
      money_question :how_much_52_weeks_1? do
        calculate :weekly_cost do |response|
          Calculators::ChildcareCostCalculator.weekly_cost(response)
        end
        next_node do
          outcome :weekly_costs_are_x #O4
        end
      end

      #Q8
      money_question :how_much_52_weeks_2? do
        calculate :weekly_cost do |response|
          Calculators::ChildcareCostCalculator.weekly_cost(response)
        end

        next_node do |response|
          amount = Money.new(response)
          amount == 0 ? outcome(:no_longer_paying) : question(:old_weekly_amount_1?)
        end
      end

      #Q9
      money_question :how_much_12_months_2? do
        calculate :weekly_cost do |response|
          Calculators::ChildcareCostCalculator.weekly_cost(response)
        end

        next_node do |response|
          amount = Money.new(response)
          amount == 0 ? outcome(:no_longer_paying) : question(:old_weekly_amount_1?)
        end
      end

      #Q10
      money_question :how_much_each_month? do
        calculate :weekly_cost do |response|
          Calculators::ChildcareCostCalculator.weekly_cost_from_monthly(response)
        end
        next_node do
          outcome :weekly_costs_are_x #O4
        end
      end

      #Q11
      multiple_choice :pay_same_each_time? do
        option :yes
        option :no

        next_node do |response|
          case response
          when 'yes'
            question :how_often_pay_providers? #Q12
          when 'no'
            question :how_much_spent_last_12_months? #Q16
          end
        end
      end

      #Q12
      multiple_choice :how_often_pay_providers? do
        option :weekly
        option :fortnightly
        option :every_4_weeks
        option :every_month
        option :termly
        option :yearly
        option :other

        next_node do |response|
          case response
          when 'weekly'
            outcome :round_up_weekly #O3
          when 'fortnightly'
            question :how_much_fortnightly? #Q13
          when 'every_4_weeks'
            question :how_much_4_weeks? #Q14
          when 'every_month'
            question :how_much_each_month? #Q10
          when 'termly', 'other'
            outcome :call_helpline_plain #O5
          when 'yearly'
            question :how_much_yearly? #Q15
          end
        end
      end

      #Q13
      money_question :how_much_fortnightly? do
        calculate :weekly_cost do |response|
          Calculators::ChildcareCostCalculator.weekly_cost_from_fortnightly(response)
        end

        next_node do
          outcome :weekly_costs_are_x #O4
        end
      end

      #Q14
      money_question :how_much_4_weeks? do
        calculate :weekly_cost do |response|
          Calculators::ChildcareCostCalculator.weekly_cost_from_four_weekly(response)
        end
        next_node do
          outcome :weekly_costs_are_x #04
        end
      end

      #Q15
      money_question :how_much_yearly? do
        calculate :weekly_cost do |response|
          Calculators::ChildcareCostCalculator.weekly_cost(response)
        end
        next_node do
          outcome :weekly_costs_are_x #O4
        end
      end

      #Q16
      money_question :how_much_spent_last_12_months? do
        calculate :weekly_cost do |response|
          Calculators::ChildcareCostCalculator.weekly_cost(response)
        end
        next_node do
          outcome :weekly_costs_are_x #O4
        end
      end

      #Q17
      money_question :new_weekly_costs? do
        calculate :new_weekly_costs do |response|
          Float(response).ceil
        end

        next_node do |response|
          amount = Money.new(response)
          amount == 0 ? outcome(:no_longer_paying) : question(:old_weekly_amount_2?)
        end
      end

      #Q18
      money_question :old_weekly_amount_1? do
        # get weekly amount from Q8 or Q9 (whichever the user answered)
        # calculate different using input from Q18
        calculate :old_weekly_cost do |response|
          Float(response).ceil
        end

        calculate :weekly_difference do
          Calculators::ChildcareCostCalculator.cost_change(weekly_cost, old_weekly_cost)
        end

        calculate :weekly_difference_abs do
          weekly_difference.abs
        end

        next_node do
          outcome :cost_changed
        end
      end

      #Q19
      money_question :new_monthly_cost? do
        calculate :new_weekly_costs do |response|
          Calculators::ChildcareCostCalculator.weekly_cost_from_monthly(response)
        end

        next_node do |response|
          amount = Money.new(response)
          amount == 0 ? outcome(:no_longer_paying) : question(:old_weekly_amount_3?)
        end
      end

      #Q20
      money_question :old_weekly_amount_2? do
        calculate :old_weekly_costs do |response|
          Float(response).ceil
        end

        calculate :weekly_difference do
          Calculators::ChildcareCostCalculator.cost_change(new_weekly_costs, old_weekly_costs)
        end

        calculate :weekly_difference_abs do
          weekly_difference.abs
        end

        calculate :cost_change_4_weeks do true end

        next_node do
          outcome :cost_changed
        end
      end

      #Q21
      money_question :old_weekly_amount_3? do
        calculate :old_weekly_costs do |response|
          Float(response).ceil
        end

        calculate :weekly_difference do
          Calculators::ChildcareCostCalculator.cost_change(new_weekly_costs, old_weekly_costs)
        end

        calculate :weekly_difference_abs do
          weekly_difference.abs
        end

        next_node do
          outcome :cost_changed
        end
      end

      ### Outcomes

      #O1
      outcome :call_helpline_detailed

      #O5
      outcome :call_helpline_plain

      #O2
      outcome :no_change

      #O3
      outcome :round_up_weekly

      #O4
      outcome :weekly_costs_are_x

      #O6, 7, 8
      outcome :cost_changed do
        precalculate :ten_or_more do
          weekly_difference_abs >= 10
        end

        precalculate :cost_change_4_weeks do
          cost_change_4_weeks || false
        end

        precalculate :title_change_text do
          weekly_difference >= 10 ? "increased" : "decreased"
        end

        precalculate :difference_money do
          Money.new(weekly_difference.abs)
        end
      end

      #O9
      outcome :no_longer_paying
    end
  end
end
