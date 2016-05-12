require_relative '../test_helper'

module SmartAnswer
  class FormattingHelperTest < ActiveSupport::TestCase
    include FormattingHelper

    test "#format_money doesn't add pence for amounts in whole pounds" do
      assert_equal '£1', format_money('1.00')
      assert_equal '£1', format_money(Money.new('1.00'))
    end

    test "#format_money adds pence for amounts that aren't whole pounds" do
      assert_equal '£1.23', format_money('1.23')
      assert_equal '£1.23', format_money(Money.new('1.23'))
    end

    test '#format_date returns the date formatted using "%e %B %Y"' do
      assert_equal ' 1 January 2015', format_date(Date.parse('2015-01-01'))
    end

    test '#format_date returns nil when the value is nil' do
      assert_equal nil, format_date(nil)
    end

    test '#format_salary returns whole number of pounds plus the period in which it was earned' do
      assert_equal '£123 per week', format_salary(Salary.new('123.45', 'week'))
    end
  end
end
