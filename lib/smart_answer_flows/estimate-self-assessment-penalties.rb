module SmartAnswer
  class EstimateSelfAssessmentPenaltiesFlow < Flow
    def define
      content_id "32b54f44-fca1-4480-b13b-ddeb0b0238e1"
      name 'estimate-self-assessment-penalties'
      status :published
      satisfies_need "100615"

      calculator_dates = {
        online_filing_deadline: {
          "2011-12": Date.new(2013, 1, 31),
          "2012-13": Date.new(2014, 1, 31),
          "2013-14": Date.new(2015, 1, 31),
        },
        offline_filing_deadline: {
          "2011-12": Date.new(2012, 10, 31),
          "2012-13": Date.new(2013, 10, 31),
          "2013-14": Date.new(2014, 10, 31),
        },
        payment_deadline: {
          "2011-12": Date.new(2013, 1, 31),
          "2012-13": Date.new(2014, 1, 31),
          "2013-14": Date.new(2015, 1, 31),
        },
      }

      multiple_choice :which_year? do
        option :"2011-12"
        option :"2012-13"
        option :"2013-14"

        save_input_as :tax_year

        calculate :start_of_next_tax_year do |response|
          if response == '2011-12'
            Date.new(2012, 4, 6)
          elsif response == '2012-13'
            Date.new(2013, 4, 6)
          else
            Date.new(2014, 4, 6)
          end
        end
        calculate :start_of_next_tax_year_formatted do
          start_of_next_tax_year.strftime("%e %B %Y")
        end

        calculate :one_year_after_start_date_for_penalties do |response|
          if response == '2011-12'
            Date.new(2014, 2, 01)
          elsif response == '2012-13'
            Date.new(2015, 2, 01)
          else
            Date.new(2016, 2, 01)
          end
        end
        next_node do
          question :how_submitted?
        end
      end

      multiple_choice :how_submitted? do
        option :online
        option :paper

        save_input_as :submission_method

        next_node do
          question :when_submitted?
        end
      end

      date_question :when_submitted? do
        from { 3.year.ago(Date.today) }
        to { 2.years.since(Date.today) }

        save_input_as :filing_date

        calculate :filing_date_formatted do
          filing_date.strftime("%e %B %Y")
        end

        next_node do |response|
          if response < start_of_next_tax_year
            raise SmartAnswer::InvalidResponse
          else
            question :when_paid?
          end
        end
      end

      date_question :when_paid? do
        from { 3.year.ago(Date.today) }
        to { 2.years.since(Date.today) }

        save_input_as :payment_date

        next_node do |response|
          if filing_date > response
            raise SmartAnswer::InvalidResponse
          else
            calculator = Calculators::SelfAssessmentPenalties.new(
              submission_method: submission_method,
              filing_date: filing_date,
              payment_date: response,
              dates: calculator_dates,
              tax_year: tax_year
            )
            if calculator.paid_on_time?
              outcome :filed_and_paid_on_time
            else
              question :how_much_tax?
            end
          end
        end
      end

      money_question :how_much_tax? do
        save_input_as :estimated_bill

        next_node do
          outcome :late
        end
      end

      outcome :late do
        precalculate :calculator do
          Calculators::SelfAssessmentPenalties.new(
            submission_method: submission_method,
            filing_date: filing_date,
            payment_date: payment_date,
            estimated_bill: estimated_bill,
            dates: calculator_dates,
            tax_year: tax_year
          )
        end

        precalculate :late_filing_penalty do
          calculator.late_filing_penalty
        end

        precalculate :total_owed do
          calculator.total_owed_plus_filing_penalty
        end

        precalculate :interest do
          calculator.interest
        end

        precalculate :late_payment_penalty do
          calculator.late_payment_penalty
        end
      end

      outcome :filed_and_paid_on_time
    end
  end
end
