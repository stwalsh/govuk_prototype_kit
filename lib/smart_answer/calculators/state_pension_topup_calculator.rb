module SmartAnswer::Calculators
  class StatePensionTopupCalculator
    FEMALE_YOUNGEST_DOB = Date.parse('1953-04-05')
    MALE_YOUNGEST_DOB = Date.parse('1951-04-05')
    TOPUP_START_DATE = Date.parse('2015-10-12')
    TOPUP_END_DATE = Date.parse('2017-04-05')
    FEMALE_RETIREMENT_AGE = 62
    MALE_RETIREMENT_AGE = 65

    def lump_sum_and_age(dob, weekly_amount, gender)
      return [] if too_young?(dob, gender)
      rows = []
      dob = leap_year_birthday?(dob) ? dob + 1.day : dob
      age = age_at_date(dob, TOPUP_START_DATE)
      (TOPUP_START_DATE.year..TOPUP_END_DATE.year).each do |_|
        break if birthday_after_topup_end?(dob, age)
        rows << { amount: lump_sum_amount(age, weekly_amount), age: age } if age >= retirement_age(gender)
        age += 1
      end
      rows
    end

    def too_young?(date_of_birth, gender = 'female')
      case gender
      when 'female'
        date_of_birth > FEMALE_YOUNGEST_DOB
      when 'male'
        date_of_birth > MALE_YOUNGEST_DOB
      end
    end

  private

    def retirement_age(gender)
      if gender == 'female'
        FEMALE_RETIREMENT_AGE
      elsif gender == 'male'
        MALE_RETIREMENT_AGE
      end
    end

    def lump_sum_amount(age, weekly_amount)
      data_query = StatePensionTopupDataQuery.new
      if data_query.age_and_rates(age)
        total = data_query.age_and_rates(age) * weekly_amount.to_f
      else
        total = 0
      end
      SmartAnswer::Money.new(total)
    end

    def birthday_after_topup_end?(dob, age)
      birthday = Date.new(TOPUP_END_DATE.year, dob.month, dob.day)
      age_at_topup_end = age_at_date(dob, TOPUP_END_DATE)
      (age > age_at_topup_end) && (birthday >= TOPUP_END_DATE)
    end

    def age_at_date(dob, date)
      years = date.year - dob.year
      birthday = Date.new(date.year, dob.month, dob.day)
      if date < birthday
        years = years - 1
      end
      years
    end

    def leap_year_birthday?(dob)
      Date.new(dob.year).leap? && (dob.month == 2 && dob.day == 29)
    end
  end
end
