module SmartAnswer
  class PipCheckerFlow < Flow
    def define
      content_id "fcd0d669-2dfd-4c43-9892-d7e942f60912"
      name 'pip-checker'
      status :published
      satisfies_need "100389"

      ## Q1
      multiple_choice :are_you_getting_dla? do
        option :yes
        option :no

        # Used in later questions
        calculate :calculator do
          Calculators::PIPDates.new
        end

        calculate :getting_dla do |response|
          response == 'yes'
        end

        next_node do
          question :what_is_your_dob?
        end
      end

      ## Q2
      date_question :what_is_your_dob? do
        date_of_birth_defaults

        next_node do |response|
          calculator.dob = response
          if getting_dla
            if calculator.in_group_65?
              outcome :result_6
            elsif calculator.turning_16_before_oct_2013? || calculator.in_middle_group?
              outcome :result_7
            else
              outcome :result_5
            end
          else
            if calculator.is_65_or_over?
              outcome :result_2
            elsif calculator.is_16_to_64?
              outcome :result_3
            else
              outcome :result_1
            end
          end
        end
      end

      outcome :result_1
      outcome :result_2
      outcome :result_3
      outcome :result_5
      outcome :result_6
      outcome :result_7
    end
  end
end
