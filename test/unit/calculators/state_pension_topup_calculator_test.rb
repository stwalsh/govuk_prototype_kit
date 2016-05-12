require_relative "../../test_helper"

module SmartAnswer::Calculators
  class StatePensionTopupCalculatorTest < ActiveSupport::TestCase
    context "checking lump sum amount" do
      setup do
        @calculator = StatePensionTopupCalculator.new
      end

      should "be 8010 for age of 69" do
        assert_equal 8010, @calculator.send(:lump_sum_amount, 69, 10)
      end

      should "be rate for 100 year olds for age of over 100" do
        rate_for_100_year_olds = @calculator.send(:lump_sum_amount, 100, 1)
        assert_equal rate_for_100_year_olds, @calculator.send(:lump_sum_amount, 150, 1)
      end

      should "be 2,720 for age of 80" do
        assert_equal 2720, @calculator.send(:lump_sum_amount, 80, 5)
      end
    end

    context "check lump sum amount and age" do
      setup do
        @calculator = StatePensionTopupCalculator.new
      end

      should "Show age of 64" do
        assert_equal 64, @calculator.send(:age_at_date, Date.parse('1951-04-06'), Date.parse('2015-10-12'))
      end

      should "Show age of 85" do
        assert_equal 85, @calculator.send(:age_at_date, Date.parse('1930-04-06'), Date.parse('2015-10-12'))
      end
    end

    context "check return value for lump sum amount and age male" do
      setup do
        @calculator = StatePensionTopupCalculator.new
      end

      should "Show 2 rates for ages 85 and 86" do
        assert_equal [{ amount: 3940.0, age: 85 }, { amount: 3660.0, age: 86 }], @calculator.lump_sum_and_age(Date.parse('1930-04-06'), 10, 'male')
      end
    end

    context "check return value for lump sum amount and age" do
      setup do
        @calculator = StatePensionTopupCalculator.new
      end

      should "show three rates for a woman born on 1953-04-05 who wants to top up her pension by £1 a week" do
        expectation = [
          { amount: 956.0, age: 62 },
          { amount: 934.0, age: 63 },
          { amount: 913.0, age: 64 },
        ]
        assert_equal expectation, @calculator.lump_sum_and_age(Date.parse('1953-04-05'), 1, 'female')
      end

      should "show three rates for a woman born on 1952-10-13 who wants to top up her pension by £1 a week" do
        expectation = [
          { amount: 956.0, age: 62 },
          { amount: 934.0, age: 63 },
          { amount: 913.0, age: 64 },
        ]
        assert_equal expectation, @calculator.lump_sum_and_age(Date.parse('1952-10-13'), 1, 'female')
      end

      should "show two rates for a man born on 1951-04-05 who wants to top up his pension by £1 a week" do
        expectation = [
          { amount: 890.0, age: 65 },
          { amount: 871.0, age: 66 },
        ]
        assert_equal expectation, @calculator.lump_sum_and_age(Date.parse('1951-04-05'), 1, 'male')
      end

      should "show no rates for women born on 1953-04-06 or after because they're too young to qualify" do
        assert_equal [], @calculator.lump_sum_and_age(Date.parse('1953-04-06'), 1, 'female')
      end

      should "show no rates for men born on 1951-04-06 or after because they're too young to qualify" do
        assert_equal [], @calculator.lump_sum_and_age(Date.parse('1951-04-06'), 1, 'male')
      end
    end

    context '#too_young?' do
      setup do
        @calculator = StatePensionTopupCalculator.new
      end

      context 'when gender is female' do
        setup do
          @threshold_date = StatePensionTopupCalculator::FEMALE_YOUNGEST_DOB
        end

        should 'be true if date of birth is after threshold date' do
          assert @calculator.too_young?(@threshold_date + 1, 'female')
        end

        should 'be false if date of birth is on threshold date' do
          refute @calculator.too_young?(@threshold_date, 'female')
        end
      end

      context 'when gender is male' do
        setup do
          @threshold_date = StatePensionTopupCalculator::MALE_YOUNGEST_DOB
        end

        should 'be true if date of birth is after threshold date' do
          assert @calculator.too_young?(@threshold_date + 1, 'male')
        end

        should 'be false if date of birth is on threshold date' do
          refute @calculator.too_young?(@threshold_date, 'male')
        end
      end
    end
  end
end
