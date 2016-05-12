module SmartAnswer
  class StudentFinanceCalculatorFlow < Flow
    def define
      content_id "434b6eb5-33c8-4300-aba3-f5ead58600b8"
      name 'student-finance-calculator'
      status :published
      satisfies_need "100133"

      #Q1
      multiple_choice :when_does_your_course_start? do
        option :"2015-2016"
        option :"2016-2017"

        save_input_as :start_date
        next_node do
          question :what_type_of_student_are_you?
        end
      end

      #Q2
      multiple_choice :what_type_of_student_are_you? do
        option :"uk-full-time"
        option :"uk-part-time"
        option :"eu-full-time"
        option :"eu-part-time"

        save_input_as :course_type
        next_node do
          question :how_much_are_your_tuition_fees_per_year?
        end
      end

      #Q3
      money_question :how_much_are_your_tuition_fees_per_year? do
        calculate :tuition_fee_amount do |response|
          if course_type == "uk-full-time" || course_type == 'eu-full-time'
            raise SmartAnswer::InvalidResponse if response > 9000
          else
            raise SmartAnswer::InvalidResponse if response > 6750
          end
          Money.new(response)
        end

        next_node do
          case course_type
          when 'uk-full-time'
            question :where_will_you_live_while_studying?
          when 'uk-part-time'
            question :do_any_of_the_following_apply_all_uk_students?
          when 'eu-full-time', 'eu-part-time'
            outcome :outcome_eu_students
          end
        end
      end
      #Q4
      multiple_choice :where_will_you_live_while_studying? do
        option :'at-home'
        option :'away-outside-london'
        option :'away-in-london'

        save_input_as :where_living
        next_node do
          question :whats_your_household_income?
        end
      end

      #Q5
      money_question :whats_your_household_income? do
        calculate :calculator do |response|
          Calculators::StudentFinanceCalculator.new(
            course_start: start_date,
            household_income: response,
            residence: where_living
          )
        end

        calculate :maintenance_grant_amount do
          calculator.maintenance_grant_amount
        end

        # loan amount depends on maintenance grant amount and household income
        calculate :maintenance_loan_amount do
          calculator.maintenance_loan_amount
        end

        next_node do
          question :do_any_of_the_following_apply_uk_full_time_students_only?
        end
      end

      #Q6a uk full-time students
      checkbox_question :do_any_of_the_following_apply_uk_full_time_students_only? do
        option :"children-under-17"
        option :"dependant-adult"
        option :"has-disability"
        option :"low-income"
        option :no

        calculate :uk_ft_circumstances do |response|
          response.split(',')
        end

        next_node do
          question :what_course_are_you_studying?
        end
      end

      #Q6b uk students
      checkbox_question :do_any_of_the_following_apply_all_uk_students? do
        option :"has-disability"
        option :"low-income"
        option :no

        calculate :all_uk_students_circumstances do |response|
          response.split(',')
        end

        next_node do
          question :what_course_are_you_studying?
        end
      end

      #Q7
      multiple_choice :what_course_are_you_studying? do
        option :"teacher-training"
        option :"dental-medical-healthcare"
        option :"social-work"
        option :"none-of-the-above"

        save_input_as :course_studied

        next_node do
          case course_type
          when 'uk-full-time'
            outcome :outcome_uk_full_time_students
          when 'uk-part-time'
            outcome :outcome_uk_all_students
          else
            outcome :outcome_eu_students
          end
        end
      end

      outcome :outcome_uk_full_time_students

      outcome :outcome_uk_all_students

      outcome :outcome_eu_students
    end
  end
end
