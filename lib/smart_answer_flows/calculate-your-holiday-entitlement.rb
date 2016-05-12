module SmartAnswer
  class CalculateYourHolidayEntitlementFlow < Flow
    def define
      content_id "deedf6f8-389b-4b34-a5b1-faa9ef909a70"
      name 'calculate-your-holiday-entitlement'
      status :published
      satisfies_need "100143"

      # Q1
      multiple_choice :basis_of_calculation? do
        option "days-worked-per-week"
        option "hours-worked-per-week"
        option "casual-or-irregular-hours"
        option "annualised-hours"
        option "compressed-hours"
        option "shift-worker"
        save_input_as :calculation_basis

        calculate :leaving_date do
          nil
        end
        calculate :leave_year_start_date do
          nil
        end
        calculate :start_date do
          nil
        end

        next_node do |response|
          case response
          when 'days-worked-per-week', 'hours-worked-per-week'
            question :calculation_period?
          when 'casual-or-irregular-hours'
            question :casual_or_irregular_hours?
          when 'annualised-hours'
            question :annualised_hours?
          when 'compressed-hours'
            question :compressed_hours_how_many_hours_per_week?
          when 'shift-worker'
            question :shift_worker_basis?
          end
        end
      end

      # Q2
      multiple_choice :calculation_period? do
        option "full-year"
        option "starting"
        option "leaving"
        option "starting-and-leaving"
        save_input_as :holiday_period

        next_node do |response|
          case response
          when "starting", "starting-and-leaving"
            question :what_is_your_starting_date?
          when "leaving"
            question :what_is_your_leaving_date?
          else
            if calculation_basis == "days-worked-per-week"
              question :how_many_days_per_week?
            else
              question :how_many_hours_per_week?
            end
          end
        end
      end

      # Q3
      value_question :how_many_days_per_week?, parse: Float do
        calculate :days_per_week do |response|
          days_per_week = response
          raise InvalidResponse if days_per_week <= 0 || days_per_week > 7
          days_per_week
        end
        next_node do
          outcome :days_per_week_done
        end
      end

      # Q4
      date_question :what_is_your_starting_date? do
        from { Date.civil(1.year.ago.year, 1, 1) }
        to { Date.civil(1.year.since(Date.today).year, 12, 31) }
        save_input_as :start_date

        next_node do
          if holiday_period == "starting-and-leaving"
            question :what_is_your_leaving_date?
          else
            question :when_does_your_leave_year_start?
          end
        end
      end

      # Q5
      date_question :what_is_your_leaving_date? do
        from { Date.civil(1.year.ago.year, 1, 1) }
        to { Date.civil(1.year.since(Date.today).year, 12, 31) }
        save_input_as :leaving_date

        next_node do
          if holiday_period == "starting-and-leaving"
            case calculation_basis
            when "days-worked-per-week"
              question :how_many_days_per_week?
            when "hours-worked-per-week"
              question :how_many_hours_per_week?
            when "shift-worker"
              question :shift_worker_hours_per_shift?
            end
          else
            question :when_does_your_leave_year_start?
          end
        end
      end

      # Q21
      date_question :when_does_your_leave_year_start? do
        from { Date.civil(1.year.ago.year, 1, 1) }
        to { Date.civil(1.year.since(Date.today).year, 12, 31) }
        save_input_as :leave_year_start_date

        next_node do
          case calculation_basis
          when "days-worked-per-week"
            question :how_many_days_per_week?
          when "hours-worked-per-week"
            question :how_many_hours_per_week?
          when "shift-worker"
            question :shift_worker_hours_per_shift?
          end
        end
      end

      # Q10
      value_question :how_many_hours_per_week?, parse: Float do
        save_input_as :hours_per_week

        next_node do
          outcome :hours_per_week_done
        end
      end

      value_question :casual_or_irregular_hours?, parse: Float do
        calculate :total_hours do |response|
          hours = response
          raise InvalidResponse if hours <= 0
          hours
        end

        next_node do
          outcome :casual_or_irregular_hours_done
        end
      end

      value_question :annualised_hours?, parse: Float do
        calculate :total_hours do |response|
          hours = response
          raise InvalidResponse if hours <= 0
          hours
        end

        next_node do
          outcome :annualised_hours_done
        end
      end

      value_question :compressed_hours_how_many_hours_per_week?, parse: Float do
        calculate :hours_per_week do |response|
          hours = response
          raise InvalidResponse if hours <= 0 || hours > 168
          hours
        end
        next_node do
          question :compressed_hours_how_many_days_per_week?
        end
      end

      value_question :compressed_hours_how_many_days_per_week?, parse: Float do
        calculate :days_per_week do |response|
          days = response
          raise InvalidResponse if days <= 0 || days > 7
          days
        end

        next_node do
          outcome :compressed_hours_done
        end
      end

      multiple_choice :shift_worker_basis? do
        option "full-year"
        option "starting"
        option "leaving"
        option "starting-and-leaving"
        save_input_as :holiday_period

        next_node do |response|
          case response
          when 'full-year'
            question :shift_worker_hours_per_shift?
          when 'starting', 'starting-and-leaving'
            question :what_is_your_starting_date?
          when 'leaving'
            question :what_is_your_leaving_date?
          end
        end
      end

      value_question :shift_worker_hours_per_shift?, parse: Float do
        calculate :hours_per_shift do |response|
          hours_per_shift = response
          raise InvalidResponse if hours_per_shift <= 0
          hours_per_shift
        end
        next_node do
          question :shift_worker_shifts_per_shift_pattern?
        end
      end

      value_question :shift_worker_shifts_per_shift_pattern?, parse: Integer do
        calculate :shifts_per_shift_pattern do |response|
          shifts = response
          raise InvalidResponse if shifts <= 0
          shifts
        end
        next_node do
          question :shift_worker_days_per_shift_pattern?
        end
      end

      value_question :shift_worker_days_per_shift_pattern?, parse: Float do
        calculate :days_per_shift_pattern do |response|
          days = response
          raise InvalidResponse if days < shifts_per_shift_pattern
          days
        end

        next_node do
          outcome :shift_worker_done
        end
      end

      outcome :shift_worker_done do
        precalculate :calculator do
          Calculators::HolidayEntitlement.new(
            start_date: start_date,
            leaving_date: leaving_date,
            leave_year_start_date: leave_year_start_date,
            hours_per_shift: hours_per_shift,
            shifts_per_shift_pattern: shifts_per_shift_pattern,
            days_per_shift_pattern: days_per_shift_pattern
          )
        end
        precalculate :holiday_entitlement_shifts do
          calculator.formatted_shift_entitlement
        end
        precalculate :hours_per_shift do
          calculator.strip_zeros hours_per_shift
        end
      end

      outcome :days_per_week_done do
        precalculate :days_per_week_calculated do
          (days_per_week < 5 ? days_per_week : 5)
        end
        precalculate :calculator do
          Calculators::HolidayEntitlement.new(
            days_per_week: (leave_year_start_date.nil? ? days_per_week : days_per_week_calculated),
            start_date: start_date,
            leaving_date: leaving_date,
            leave_year_start_date: leave_year_start_date
          )
        end
        precalculate :holiday_entitlement_days do
          calculator.formatted_full_time_part_time_days
        end
      end

      outcome :hours_per_week_done do
        precalculate :calculator do
          Calculators::HolidayEntitlement.new(
            hours_per_week: hours_per_week,
            start_date: start_date,
            leaving_date: leaving_date,
            leave_year_start_date: leave_year_start_date
          )
        end
        precalculate :holiday_entitlement_hours_and_minutes do
          calculator.full_time_part_time_hours_and_minutes
        end
        precalculate :holiday_entitlement_hours do
          holiday_entitlement_hours_and_minutes.first
        end
        precalculate :holiday_entitlement_minutes do
          holiday_entitlement_hours_and_minutes.last
        end
      end

      outcome :casual_or_irregular_hours_done do
        precalculate :calculator do
          Calculators::HolidayEntitlement.new(total_hours: total_hours)
        end
        precalculate :holiday_entitlement_hours do
          calculator.casual_irregular_entitlement.first
        end
        precalculate :holiday_entitlement_minutes do
          calculator.casual_irregular_entitlement.last
        end
      end

      outcome :compressed_hours_done do
        precalculate :calculator do
          Calculators::HolidayEntitlement.new(
            hours_per_week: hours_per_week,
            days_per_week: days_per_week
          )
        end
        precalculate :holiday_entitlement_hours do
          calculator.compressed_hours_entitlement.first
        end
        precalculate :holiday_entitlement_minutes do
          calculator.compressed_hours_entitlement.last
        end
        precalculate :hours_daily do
          calculator.compressed_hours_daily_average.first
        end
        precalculate :minutes_daily do
          calculator.compressed_hours_daily_average.last
        end
      end

      outcome :annualised_hours_done do
        precalculate :calculator do
          Calculators::HolidayEntitlement.new(total_hours: total_hours)
        end
        precalculate :average_hours_per_week do
          calculator.formatted_annualised_hours_per_week
        end
        precalculate :holiday_entitlement_hours do
          calculator.annualised_entitlement.first
        end
        precalculate :holiday_entitlement_minutes do
          calculator.annualised_entitlement.last
        end
      end
    end
  end
end
