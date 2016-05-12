require_relative '../../test_helper'
require_relative 'flow_unit_test_helper'

require 'smart_answer_flows/calculate-statutory-sick-pay'

module SmartAnswer
  class CalculateStatutorySickPayFlowTest < ActiveSupport::TestCase
    include FlowUnitTestHelper

    setup do
      @calculator = Calculators::StatutorySickPayCalculator.new
      @flow = CalculateStatutorySickPayFlow.build
    end

    context 'when answering last_sick_day? question' do
      setup do
        @calculator.sick_start_date = Date.parse('2015-01-01')
      end

      context 'and sickness period is valid period of incapacity for work' do
        setup do
          @calculator.stubs(valid_period_of_incapacity_for_work?: true)
          setup_states_for_question(:last_sick_day?, responding_with: '2015-01-03',
            initial_state: { calculator: @calculator })
        end

        should 'go to has_linked_sickness? question' do
          assert_equal :has_linked_sickness?, @new_state.current_node
          assert_node_exists :has_linked_sickness?
        end
      end

      context 'and sickness period is not valid period of incapacity for work' do
        setup do
          @calculator.stubs(valid_period_of_incapacity_for_work?: false)
          setup_states_for_question(:last_sick_day?, responding_with: '2015-01-03',
            initial_state: { calculator: @calculator })
        end

        should 'go to must_be_sick_for_4_days outcome' do
          assert_equal :must_be_sick_for_4_days, @new_state.current_node
          assert_node_exists :must_be_sick_for_4_days
        end
      end
    end

    context 'when answering linked_sickness_end_date? question' do
      setup do
        @calculator.stubs(
          within_eight_weeks_of_current_sickness_period?: true,
          at_least_1_day_before_first_sick_day?: true,
          valid_linked_period_of_incapacity_for_work?: true
        )
      end

      context 'and linked sickness ends more than 8 weeks before sickness starts' do
        setup do
          @calculator.stubs(within_eight_weeks_of_current_sickness_period?: false)
        end

        should 'raise an exception' do
          exception = assert_raise(SmartAnswer::InvalidResponse) do
            setup_states_for_question(
              :linked_sickness_end_date?,
              responding_with: '2015-01-07',
              initial_state: { calculator: @calculator }
            )
          end
          assert_equal 'must_be_within_eight_weeks', exception.message
        end
      end

      context 'and linked sickness ends the day before sickness starts' do
        setup do
          @calculator.stubs(at_least_1_day_before_first_sick_day?: false)
        end

        should 'raise an exception' do
          exception = assert_raise(SmartAnswer::InvalidResponse) do
            setup_states_for_question(
              :linked_sickness_end_date?,
              responding_with: '2015-01-31',
              initial_state: { calculator: @calculator }
            )
          end
          assert_equal 'must_be_at_least_1_day_before_first_sick_day', exception.message
        end
      end

      context 'and linked sickness period is less than 4 calendar days long' do
        setup do
          @calculator.stubs(valid_linked_period_of_incapacity_for_work?: false)
        end

        should 'raise an exception' do
          exception = assert_raise(SmartAnswer::InvalidResponse) do
            setup_states_for_question(
              :linked_sickness_end_date?,
              responding_with: '2015-01-03',
              initial_state: { calculator: @calculator }
            )
          end
          assert_equal 'must_be_valid_period_of_incapacity_for_work', exception.message
        end
      end
    end
  end
end
