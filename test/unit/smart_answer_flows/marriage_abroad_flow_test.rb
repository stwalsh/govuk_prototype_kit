require_relative '../../test_helper'
require_relative 'flow_unit_test_helper'

require 'smart_answer_flows/marriage-abroad'

module SmartAnswer
  class MarriageAbroadFlowTest < ActiveSupport::TestCase
    include FlowUnitTestHelper

    setup do
      @calculator = Calculators::MarriageAbroadCalculator.new
      @flow = MarriageAbroadFlow.build

      world_location = stub('WorldLocation',
        slug: 'afghanistan', name: 'Afghanistan', fco_organisation: nil)
      WorldLocation.stubs(:all).returns([world_location])
      WorldLocation.stubs(:find).with('afghanistan').returns(world_location)
    end

    should 'start with the country_of_ceremony? question' do
      assert_equal :country_of_ceremony?, @flow.start_state.current_node
    end

    context 'when answering country_of_ceremony? question' do
      setup do
        Calculators::MarriageAbroadCalculator.stubs(:new).returns(@calculator)
        setup_states_for_question(:country_of_ceremony?,
          responding_with: 'afghanistan')
      end

      should 'instantiate and store calculator' do
        assert_same @calculator, @new_state.calculator
      end

      should 'store parsed response on calculator as ceremony_country' do
        assert_equal 'afghanistan', @calculator.ceremony_country
      end

      context 'responding with an invalid ceremony country' do
        setup do
          @calculator.stubs(:valid_ceremony_country?).returns(false)
        end

        should 'raise an exception' do
          assert_raise(SmartAnswer::InvalidResponse) do
            setup_states_for_question(:country_of_ceremony?,
              responding_with: 'unknown-country',
              initial_state: { calculator: @calculator })
          end
        end
      end
    end

    context 'when answering legal_residency? question' do
      setup do
        Calculators::MarriageAbroadCalculator.stubs(:new).returns(@calculator)
        setup_states_for_question(:legal_residency?,
          responding_with: 'uk', initial_state: {
            calculator: @calculator })
      end

      should 'store parsed response on calculator as resident_of' do
        assert_equal 'uk', @calculator.instance_variable_get('@resident_of')
      end
    end

    context 'when answering what_is_your_partners_nationality? question' do
      setup do
        Calculators::MarriageAbroadCalculator.stubs(:new).returns(@calculator)
        setup_states_for_question(:what_is_your_partners_nationality?,
          responding_with: 'partner_british', initial_state: {
            calculator: @calculator })
      end

      should 'store parsed response on calculator as partner_nationality' do
        assert_equal 'partner_british', @calculator.instance_variable_get('@partner_nationality')
      end
    end

    context 'when answering partner_opposite_or_same_sex? question' do
      setup do
        Calculators::MarriageAbroadCalculator.stubs(:new).returns(@calculator)
        setup_states_for_question(:partner_opposite_or_same_sex?,
          responding_with: 'same_sex', initial_state: {
            calculator: @calculator })
      end

      should 'store parsed response on calculator as sex_of_your_partner' do
        assert_equal 'same_sex', @calculator.instance_variable_get('@sex_of_your_partner')
      end
    end

    context 'when answering marriage_or_pacs? question' do
      setup do
        Calculators::MarriageAbroadCalculator.stubs(:new).returns(@calculator)
        setup_states_for_question(:marriage_or_pacs?,
          responding_with: 'marriage', initial_state: {
            calculator: @calculator })
      end

      should 'store parsed response on calculator as marriage_or_pacs' do
        assert_equal 'marriage', @calculator.instance_variable_get('@marriage_or_pacs')
      end
    end
  end
end
