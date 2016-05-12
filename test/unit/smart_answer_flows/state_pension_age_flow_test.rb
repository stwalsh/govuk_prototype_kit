require_relative '../../test_helper'

require 'smart_answer_flows/state-pension-age'

module SmartAnswer
  class StatePensionAgeFlowTest < ActiveSupport::TestCase
    setup do
      @flow = StatePensionAgeFlow.build
    end

    context 'validation' do
      context "for :dob_age?" do
        setup do
          @question = @flow.node(:dob_age?)
          @state = SmartAnswer::State.new(@question)
          @state.gender = 'male'
        end

        should "raise if the date of birth is later than today's date" do
          invalid_date_of_birth = 1.week.from_now.to_date
          @state.response = invalid_date_of_birth
          assert_raise(SmartAnswer::InvalidResponse) do
            @question.transition(@state, invalid_date_of_birth)
          end
        end
      end
    end
  end
end
