require_relative '../../test_helper'
require_relative 'flow_test_helper'
require 'gds_api/test_helpers/worldwide'

require 'smart_answer_flows/marriage-abroad'

class MarriageAbroadTest < ActiveSupport::TestCase
  include FlowTestHelper
  include GdsApi::TestHelpers::Worldwide

  def self.translations
    @translations ||= YAML.load_file("lib/smart_answer_flows/locales/en/marriage-abroad.yml")
  end

  setup do
    @location_slugs = %w(albania american-samoa anguilla argentina armenia aruba australia austria azerbaijan bahamas belarus belgium bonaire-st-eustatius-saba brazil british-indian-ocean-territory burma burundi cambodia canada china costa-rica cote-d-ivoire croatia colombia cyprus czech-republic democratic-republic-of-congo denmark ecuador egypt estonia finland france germany greece hong-kong indonesia iran ireland italy japan jordan kazakhstan kosovo kyrgyzstan laos latvia lebanon lithuania macao macedonia malta mayotte mexico monaco montenegro morocco netherlands nicaragua north-korea norway oman guatemala paraguay peru philippines poland portugal qatar russia rwanda saint-barthelemy san-marino saudi-arabia serbia seychelles slovakia slovenia south-africa st-maarten st-martin south-korea spain sweden switzerland thailand turkey turkmenistan ukraine united-arab-emirates usa uzbekistan vietnam wallis-and-futuna yemen zimbabwe).uniq
    worldwide_api_has_locations(@location_slugs)
    setup_for_testing_flow SmartAnswer::MarriageAbroadFlow
  end

  should "which country you want the ceremony to take place in" do
    assert_current_node :country_of_ceremony?
  end

  context "newly added country that has no logic to handle opposite sex marriages" do
    setup do
      worldwide_api_has_locations(['narnia'])
      worldwide_api_has_no_organisations_for_location('narnia')
      add_response 'ceremony_country'
      add_response 'partner_local'
      assert_raises(SmartAnswer::Question::Base::NextNodeUndefined) do
        add_response 'opposite_sex'
      end
    end
  end

  context "ceremony in ireland" do
    setup do
      worldwide_api_has_organisations_for_location('ireland', read_fixture_file('worldwide/ireland_organisations.json'))
      add_response 'ireland'
    end
    should "go to partner's sex question" do
      assert_current_node :partner_opposite_or_same_sex?
    end
    context "partner is opposite sex" do
      setup do
        add_response 'opposite_sex'
      end
      should "give outcome ireland os" do
        assert_current_node :outcome_ceremonies_in_ireland
      end
    end
    context "partner is same sex" do
      setup do
        add_response 'same_sex'
      end
      should "give outcome ireland ss" do
        assert_current_node :outcome_ceremonies_in_ireland
        expected_location = WorldLocation.find('ireland')
        assert_equal expected_location, current_state.calculator.world_location
      end
    end
  end

  context "ceremony is outside ireland" do
    setup do
      worldwide_api_has_organisations_for_location('bahamas', read_fixture_file('worldwide/bahamas_organisations.json'))
      add_response 'bahamas'
    end
    should "ask your country of residence" do
      assert_current_node :legal_residency?
      assert_equal 'Bahamas', current_state.calculator.ceremony_country_name
      assert_equal "the Bahamas", current_state.calculator.country_name_lowercase_prefix
    end

    context "resident in UK" do
      setup do
        add_response 'uk'
      end

      should "go to partner nationality question" do
        assert_current_node :what_is_your_partners_nationality?
        assert_equal 'Bahamas', current_state.calculator.ceremony_country_name
        assert_equal "the Bahamas", current_state.calculator.country_name_lowercase_prefix
      end

      context "partner is british" do
        setup do
          add_response 'partner_british'
        end
        should "ask what sex is your partner" do
          assert_current_node :partner_opposite_or_same_sex?
        end
        context "opposite sex partner" do
          setup do
            add_response 'opposite_sex'
          end
          should "give outcome opposite sex commonwealth" do
            assert_current_node :outcome_opposite_sex_marriage_in_commonwealth_countries
            expected_location = WorldLocation.find('bahamas')
            assert_equal expected_location, current_state.calculator.world_location
          end
        end
        context "same sex partner" do
          setup do
            add_response 'same_sex'
          end
          should "give outcome same sex all other countries" do
            assert_current_node :outcome_same_sex_marriage_and_civil_partnership_in_other_countries
          end
        end
      end
    end

    context "resident in the ceremony country" do
      setup do
        add_response 'ceremony_country'
      end

      should "go to partner's nationality question" do
        assert_current_node :what_is_your_partners_nationality?
        assert_equal 'Bahamas', current_state.calculator.ceremony_country_name
      end

      context "partner is local" do
        setup do
          add_response 'partner_local'
        end
        should "ask what sex is your partner" do
          assert_current_node :partner_opposite_or_same_sex?
        end
        context "opposite sex partner" do
          setup do
            add_response 'opposite_sex'
          end
          should "give outcome opposite sex commonwealth" do
            assert_current_node :outcome_opposite_sex_marriage_in_commonwealth_countries
            expected_location = WorldLocation.find('bahamas')
            assert_equal expected_location, current_state.calculator.world_location
          end
        end
        context "same sex partner" do
          setup do
            add_response 'same_sex'
          end
          should "give outcome all other countries" do
            assert_current_node :outcome_same_sex_marriage_and_civil_partnership_in_other_countries
          end
        end
      end
    end

    context "resident in 3rd country" do
      setup do
        add_response 'third_country'
      end

      should "go to partner's nationality question" do
        assert_current_node :what_is_your_partners_nationality?
        assert_equal 'Bahamas', current_state.calculator.ceremony_country_name
      end

      context "partner is local" do
        setup do
          add_response 'partner_local'
        end
        should "ask what sex is your partner" do
          assert_current_node :partner_opposite_or_same_sex?
        end
        context "opposite sex partner" do
          setup do
            add_response 'opposite_sex'
          end
          should "give outcome opposite sex commonwealth" do
            assert_current_node :outcome_opposite_sex_marriage_in_commonwealth_countries
            expected_location = WorldLocation.find('bahamas')
            assert_equal expected_location, current_state.calculator.world_location
          end
        end
        context "same sex partner" do
          setup do
            add_response 'same_sex'
          end
          should "give outcome all other countries" do
            assert_current_node :outcome_same_sex_marriage_and_civil_partnership_in_other_countries
          end
        end
      end
    end
  end

  context "local resident but ceremony not in zimbabwe" do
    setup do
      worldwide_api_has_organisations_for_location('australia', read_fixture_file('worldwide/australia_organisations.json'))
      add_response 'australia'
      add_response 'ceremony_country'
      add_response 'partner_british'
      add_response 'opposite_sex'
    end
    should "go to commonwealth os outcome" do
      assert_current_node :outcome_opposite_sex_marriage_in_commonwealth_countries
      expected_location = WorldLocation.find('australia')
      assert_equal expected_location, current_state.calculator.world_location
    end
  end

  context "uk resident but ceremony not in zimbabwe" do
    setup do
      worldwide_api_has_organisations_for_location('bahamas', read_fixture_file('worldwide/bahamas_organisations.json'))
      add_response 'bahamas'
      add_response 'uk'
      add_response 'partner_british'
      add_response 'opposite_sex'
    end
    should "go to commonwealth os outcome" do
      assert_current_node :outcome_opposite_sex_marriage_in_commonwealth_countries
      expected_location = WorldLocation.find('bahamas')
      assert_equal expected_location, current_state.calculator.world_location
    end
  end

  context "other resident but ceremony not in zimbabwe" do
    setup do
      worldwide_api_has_organisations_for_location('australia', read_fixture_file('worldwide/australia_organisations.json'))
      add_response 'australia'
      add_response 'third_country'
      add_response 'partner_british'
      add_response 'opposite_sex'
    end
    should "go to commonwealth os outcome" do
      assert_current_node :outcome_opposite_sex_marriage_in_commonwealth_countries
    end
  end

  context "ceremony in zimbabwe" do
    setup do
      worldwide_api_has_organisations_for_location('zimbabwe', read_fixture_file('worldwide/zimbabwe_organisations.json'))
      add_response 'zimbabwe'
    end
    should "go to commonwealth os outcome for uk resident " do
      add_response 'uk'
      add_response 'partner_british'
      add_response 'opposite_sex'
      assert_current_node :outcome_opposite_sex_marriage_in_commonwealth_countries
    end
    should "go to commonwealth os outcome for non-uk resident" do
      add_response 'ceremony_country'
      add_response 'partner_local'
      add_response 'opposite_sex'
      assert_current_node :outcome_opposite_sex_marriage_in_commonwealth_countries
    end
  end

  context "ceremony in south africa," do
    setup do
      worldwide_api_has_organisations_for_location('south-africa', read_fixture_file('worldwide/south-africa_organisations.json'))
      add_response 'south-africa'
    end
    context "resident in uk," do
      setup { add_response 'uk' }
      context "partner is british," do
        setup { add_response 'partner_british' }
        context "opposite sex" do
          setup { add_response 'opposite_sex' }
          should "go to south african or equivalent commonwealth marriage outcome" do
            assert_current_node :outcome_opposite_same_sex_marriage_residing_in_uk_or_south_africa
          end
        end
        context "same sex" do
          setup { add_response 'same_sex' }
          should "go to south african or equivalent commonwealth marriage outcome" do
            assert_current_node :outcome_opposite_same_sex_marriage_residing_in_uk_or_south_africa
          end
        end
      end
      context "partner is local," do
        setup { add_response 'partner_local' }
        context "opposite sex" do
          setup { add_response 'opposite_sex' }
          should "go to south african or equivalent commonwealth marriage outcome" do
            assert_current_node :outcome_opposite_same_sex_marriage_residing_in_uk_or_south_africa
          end
        end
        context "same sex" do
          setup { add_response 'same_sex' }
          should "go to south african or equivalent commonwealth marriage outcome" do
            assert_current_node :outcome_opposite_same_sex_marriage_residing_in_uk_or_south_africa
          end
        end
      end
      context "partner is other," do
        setup { add_response 'partner_other' }
        context "opposite sex" do
          setup { add_response 'opposite_sex' }
          should "go to south african or equivalent commonwealth marriage outcome" do
            assert_current_node :outcome_opposite_same_sex_marriage_residing_in_uk_or_south_africa
          end
        end
        context "same sex" do
          setup { add_response 'same_sex' }
          should "go to south african or equivalent commonwealth marriage outcome" do
            assert_current_node :outcome_opposite_same_sex_marriage_residing_in_uk_or_south_africa
          end
        end
      end
    end
    context "resident in ceremony country" do
      setup { add_response 'ceremony_country' }
      context "partner is british," do
        setup { add_response 'partner_british' }
        context "opposite sex" do
          setup { add_response 'opposite_sex' }
          should "go to south african or equivalent commonwealth marriage outcome" do
            assert_current_node :outcome_opposite_same_sex_marriage_residing_in_uk_or_south_africa
          end
        end
        context "same sex" do
          setup { add_response 'same_sex' }
          should "go to south african or equivalent commonwealth marriage outcome" do
            assert_current_node :outcome_opposite_same_sex_marriage_residing_in_uk_or_south_africa
          end
        end
      end
      context "partner is local," do
        setup { add_response 'partner_local' }
        context "opposite sex" do
          setup { add_response 'opposite_sex' }
          should "go to south african or equivalent commonwealth marriage outcome" do
            assert_current_node :outcome_opposite_same_sex_marriage_residing_in_uk_or_south_africa
          end
        end
        context "same sex" do
          setup { add_response 'same_sex' }
          should "go to south african or equivalent commonwealth marriage outcome" do
            assert_current_node :outcome_opposite_same_sex_marriage_residing_in_uk_or_south_africa
          end
        end
      end
      context "partner is other," do
        setup { add_response 'partner_other' }
        context "opposite sex" do
          setup { add_response 'opposite_sex' }
          should "go to south african or equivalent commonwealth marriage outcome" do
            assert_current_node :outcome_opposite_same_sex_marriage_residing_in_uk_or_south_africa
          end
        end
        context "same sex" do
          setup { add_response 'same_sex' }
          should "go to south african or equivalent commonwealth marriage outcome" do
            assert_current_node :outcome_opposite_same_sex_marriage_residing_in_uk_or_south_africa
          end
        end
      end
    end
    context "resident in elsewhere," do
      setup { add_response 'third_country' }
      context "partner is british," do
        setup { add_response 'partner_british' }
        context "opposite sex" do
          setup { add_response 'opposite_sex' }
          should "go to south african or equivalent commonwealth marriage outcome" do
            assert_current_node :outcome_opposite_same_sex_marriage_residing_in_uk_or_south_africa
          end
        end
        context "same sex" do
          setup { add_response 'same_sex' }
          should "go to south african or equivalent commonwealth marriage outcome" do
            assert_current_node :outcome_opposite_same_sex_marriage_residing_in_uk_or_south_africa
          end
        end
      end
      context "partner is local," do
        setup { add_response 'partner_local' }
        context "opposite sex" do
          setup { add_response 'opposite_sex' }
          should "go to south african or equivalent commonwealth marriage outcome" do
            assert_current_node :outcome_opposite_same_sex_marriage_residing_in_uk_or_south_africa
          end
        end
        context "same sex" do
          setup { add_response 'same_sex' }
          should "go to south african or equivalent commonwealth marriage outcome" do
            assert_current_node :outcome_opposite_same_sex_marriage_residing_in_uk_or_south_africa
          end
        end
      end
      context "partner is other," do
        setup { add_response 'partner_other' }
        context "opposite sex" do
          setup { add_response 'opposite_sex' }
          should "go to south african or equivalent commonwealth marriage outcome" do
            assert_current_node :outcome_opposite_same_sex_marriage_residing_in_uk_or_south_africa
          end
        end
        context "same sex" do
          setup { add_response 'same_sex' }
          should "go to south african or equivalent commonwealth marriage outcome" do
            assert_current_node :outcome_opposite_same_sex_marriage_residing_in_uk_or_south_africa
          end
        end
      end
    end
  end

  context "resident in cyprus, ceremony in cyprus" do
    setup do
      worldwide_api_has_organisations_for_location('cyprus', read_fixture_file('worldwide/cyprus_organisations.json'))
      add_response 'cyprus'
      add_response 'ceremony_country'
      add_response 'partner_other'
      add_response 'opposite_sex'
    end
    should "go to commonwealth os outcome" do
      assert_current_node :outcome_opposite_sex_marriage_in_commonwealth_countries
    end
  end

  context "resident in england, ceremony in cyprus, partner other" do
    setup do
      worldwide_api_has_organisations_for_location('cyprus', read_fixture_file('worldwide/cyprus_organisations.json'))
      add_response 'cyprus'
      add_response 'uk'
      add_response 'partner_other'
      add_response 'same_sex'
    end
    should "go to consular cp outcome" do
      assert_current_node :outcome_same_sex_civil_partnership_in_consular_countries
    end
  end

  context "uk resident ceremony in british indian ocean territory" do
    setup do
      worldwide_api_has_organisations_for_location('british-indian-ocean-territory', read_fixture_file('worldwide/british-indian-ocean-territory_organisations.json'))
      add_response 'british-indian-ocean-territory'
      add_response 'uk'
      add_response 'partner_local'
      add_response 'opposite_sex'
    end
    should "go to bot os outcome" do
      assert_current_node :outcome_opposite_sex_marriage_in_british_overseas_territory
    end
  end

  context "resident in anguilla, ceremony in anguilla" do
    setup do
      worldwide_api_has_organisations_for_location('anguilla', read_fixture_file('worldwide/anguilla_organisations.json'))
      add_response 'anguilla'
      add_response 'ceremony_country'
      add_response 'partner_other'
      add_response 'opposite_sex'
    end
    should "go to bos os outcome" do
      assert_current_node :outcome_opposite_sex_marriage_in_british_overseas_territory
    end
  end

  context "uk resident, ceremony in estonia, partner british" do
    setup do
      worldwide_api_has_organisations_for_location('estonia', read_fixture_file('worldwide/estonia_organisations.json'))
      add_response 'estonia'
      add_response 'uk'
      add_response 'partner_british'
      add_response 'opposite_sex'
    end
    should "go to consular cni os outcome" do
      assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_uk_or_ceremony_country
    end
  end

  context "resident in estonia, ceremony in estonia" do
    setup do
      worldwide_api_has_organisations_for_location('estonia', read_fixture_file('worldwide/estonia_organisations.json'))
      add_response 'estonia'
      add_response 'ceremony_country'
      add_response 'partner_local'
      add_response 'opposite_sex'
    end
    should "go to consular cni os outcome" do
      assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_uk_or_ceremony_country
    end
  end

  context "ceremony in Estonia, lives in 3rd country" do
    setup do
      worldwide_api_has_organisations_for_location('estonia', read_fixture_file('worldwide/estonia_organisations.json'))
      add_response 'estonia'
      add_response 'third_country'
      add_response 'partner_british'
      add_response 'opposite_sex'
    end
    should "go to outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_third_country" do
      assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_third_country
    end
  end

  context "local resident, ceremony in jordan, partner british" do
    setup do
      worldwide_api_has_organisations_for_location('jordan', read_fixture_file('worldwide/jordan_organisations.json'))
      add_response 'jordan'
      add_response 'ceremony_country'
      add_response 'partner_british'
      add_response 'opposite_sex'
    end
    should "go to consular cni os outcome" do
      assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_uk_or_ceremony_country
    end
  end
  # variants for italy
  context "ceremony in italy, resident in england, partner british" do
    setup do
      worldwide_api_has_organisations_for_location('italy', read_fixture_file('worldwide/italy_organisations.json'))
      add_response 'italy'
      add_response 'uk'
      add_response 'partner_british'
      add_response 'opposite_sex'
    end
    should "go to consular cni os outcome" do
      assert_current_node :outcome_opposite_sex_marriage_in_italy_when_residing_in_uk_or_italy
    end
  end

  context "ceremony in italy, resident in italy, partner local" do
    setup do
      worldwide_api_has_organisations_for_location('italy', read_fixture_file('worldwide/italy_organisations.json'))
      add_response 'italy'
      add_response 'ceremony_country'
      add_response 'partner_local'
      add_response 'opposite_sex'
    end
    should "go to consular cni os outcome" do
      assert_current_node :outcome_opposite_sex_marriage_in_italy_when_residing_in_uk_or_italy
    end
  end

  context "ceremony in italy, lives in 3rd country, partner other" do
    setup do
      worldwide_api_has_organisations_for_location('italy', read_fixture_file('worldwide/italy_organisations.json'))
      add_response 'italy'
      add_response 'third_country'
      add_response 'partner_other'
      add_response 'opposite_sex'
    end
    should "go to outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_third_country" do
      assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_third_country
    end
  end

  #variants for germany
  context "ceremony in germany, resident in germany, partner other" do
    setup do
      worldwide_api_has_organisations_for_location('germany', read_fixture_file('worldwide/germany_organisations.json'))
      add_response 'germany'
      add_response 'ceremony_country'
      add_response 'partner_other'
      add_response 'opposite_sex'
    end
    should "go to consular cni os outcome" do
      assert_current_node :outcome_opposite_sex_marriage_in_germany
    end
  end

  context "ceremony in germany, partner german, same sex" do
    setup do
      worldwide_api_has_organisations_for_location('germany', read_fixture_file('worldwide/germany_organisations.json'))
      add_response 'germany'
      add_response 'ceremony_country'
      add_response 'partner_local'
      add_response 'same_sex'
    end
    should "go to cp or equivalent outcome" do
      assert_current_node :outcome_same_sex_civil_partnership
    end
  end

  context "ceremony in germany, partner not german, same sex" do
    setup do
      worldwide_api_has_organisations_for_location('germany', read_fixture_file('worldwide/germany_organisations.json'))
      add_response 'germany'
      add_response 'ceremony_country'
      add_response 'partner_other'
      add_response 'same_sex'
    end
    should "go to ss marriage" do
      assert_current_node :outcome_same_sex_marriage_and_civil_partnership
    end
  end
  #variants for uk residency (again)
  context "ceremony in azerbaijan, resident in UK, partner non-irish" do
    setup do
      worldwide_api_has_organisations_for_location('azerbaijan', read_fixture_file('worldwide/azerbaijan_organisations.json'))
      add_response 'azerbaijan'
      add_response 'uk'
      add_response 'partner_local'
      add_response 'opposite_sex'
    end
    should "go to consular cni os outcome" do
      assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_uk_or_ceremony_country
    end
  end

  context "ceremony in azerbaijan, resident in the UK, opposite sex non-local partner" do
    setup do
      worldwide_api_has_organisations_for_location('azerbaijan', read_fixture_file('worldwide/azerbaijan_organisations.json'))
      add_response 'azerbaijan'
      add_response 'uk'
      add_response 'partner_other'
      add_response 'opposite_sex'
    end
    should "go to consular cni os outcome" do
      assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_uk_or_ceremony_country
    end
  end
  #variant for uk resident, ceremony not in italy
  context "ceremony in guatemala, resident in wales, partner other" do
    setup do
      worldwide_api_has_organisations_for_location('guatemala', read_fixture_file('worldwide/guatemala_organisations.json'))
      add_response 'guatemala'
      add_response 'uk'
      add_response 'partner_other'
    end
    should "go to consular cni os outcome for opposite sex marriage" do
      add_response 'opposite_sex'
      assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_uk_or_ceremony_country
    end

    should "go to outcome_same_sex_civil_partnership_in_consular_countries outcome for same sex marriage" do
      add_response 'same_sex'
      assert_current_node :outcome_same_sex_civil_partnership_in_consular_countries
    end
  end
  #variant for local resident, ceremony not in italy or germany
  context "ceremony in azerbaijan, resident in azerbaijan, partner other" do
    setup do
      worldwide_api_has_organisations_for_location('azerbaijan', read_fixture_file('worldwide/azerbaijan_organisations.json'))
      add_response 'azerbaijan'
      add_response 'ceremony_country'
      add_response 'partner_other'
      add_response 'opposite_sex'
    end
    should "go to consular cni os outcome" do
      assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_uk_or_ceremony_country
    end
  end

  context "ceremony in denmark, lives in 3rd country, partner opposite sex british" do
    setup do
      worldwide_api_has_organisations_for_location('denmark', read_fixture_file('worldwide/denmark_organisations.json'))
      add_response 'denmark'
      add_response 'third_country'
      add_response 'partner_british'
      add_response 'opposite_sex'
    end
    should "go to outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_third_country" do
      assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_third_country
    end
  end

  #variant for local residents (not germany or spain)
  context "ceremony in denmark, resident in denmark, partner other" do
    setup do
      worldwide_api_has_organisations_for_location('denmark', read_fixture_file('worldwide/denmark_organisations.json'))
      add_response 'denmark'
      add_response 'ceremony_country'
      add_response 'partner_other'
      add_response 'opposite_sex'
    end
    should "go to consular cni os outcome" do
      assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_uk_or_ceremony_country
    end
  end

  context "Spain" do
    setup do
      worldwide_api_has_organisations_for_location('spain', read_fixture_file('worldwide/spain_organisations.json'))
      add_response 'spain'
    end

    context "resident in uk, partner british, opposite sex" do
      setup do
        add_response 'uk'
        add_response 'partner_british'
        add_response 'opposite_sex'
      end
      should "go to outcome_ceremonies_in_spain with UK/OS specific phrases" do
        assert_current_node :outcome_ceremonies_in_spain
      end
    end

    context "resident in spain, partner local" do
      setup do
        add_response 'ceremony_country'
        add_response 'partner_local'
        add_response 'opposite_sex'
      end
      should "go to outcome_ceremonies_in_spain with ceremony country OS specific phrases" do
        assert_current_node :outcome_ceremonies_in_spain
      end
    end

    context "lives elsewhere, partner opposite sex other" do
      setup do
        add_response 'third_country'
        add_response 'partner_other'
        add_response 'opposite_sex'
      end

      should "go to outcome_ceremonies_in_spain with third country OS specific phrases" do
        assert_current_node :outcome_ceremonies_in_spain
      end
    end

    context "resident in england, partner british, same sex" do
      setup do
        add_response 'uk'
        add_response 'partner_british'
        add_response 'same_sex'
      end

      should "go to outcome_ceremonies_in_spain with UK/SS specific phrases" do
        assert_current_node :outcome_ceremonies_in_spain
      end
    end

    context "lives elsewhere, partner same sex other" do
      setup do
        add_response 'third_country'
        add_response 'partner_other'
        add_response 'same_sex'
      end

      should "go to outcome_ceremonies_in_spain with third country SS specific phrases" do
        assert_current_node :outcome_ceremonies_in_spain
      end
    end
  end

  context "ceremony in poland, lives elsewhere, partner local" do
    setup do
      worldwide_api_has_organisations_for_location('poland', read_fixture_file('worldwide/poland_organisations.json'))
      add_response 'poland'
      add_response 'ceremony_country'
      add_response 'partner_local'
      add_response 'opposite_sex'
    end
    should "go to os poland outcome" do
      assert_current_node :outcome_opposite_sex_marriage_in_poland_when_residing_in_uk_or_poland
    end
  end

  context "ceremony in azerbaijan, resident in azerbaijan, partner local" do
    setup do
      worldwide_api_has_organisations_for_location('azerbaijan', read_fixture_file('worldwide/azerbaijan_organisations.json'))
      add_response 'azerbaijan'
      add_response 'ceremony_country'
      add_response 'partner_local'
      add_response 'opposite_sex'
    end
    should "go to consular cni os outcome" do
      assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_uk_or_ceremony_country
    end
  end
  #variant for foreign resident, ceremony not in italy
  context "ceremony in azerbaijan, lives elsewhere, partner local" do
    setup do
      worldwide_api_has_organisations_for_location('azerbaijan', read_fixture_file('worldwide/azerbaijan_organisations.json'))
      add_response 'azerbaijan'
      add_response 'third_country'
      add_response 'partner_local'
      add_response 'opposite_sex'
    end
    should "go to outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_third_country" do
      assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_third_country
    end
  end

  context "ceremony in poland, lives in 3rd country, partner british" do
    setup do
      worldwide_api_has_organisations_for_location('poland', read_fixture_file('worldwide/poland_organisations.json'))
      add_response 'poland'
      add_response 'third_country'
      add_response 'partner_british'
      add_response 'opposite_sex'
    end
    should "go to outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_third_country" do
      assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_third_country
    end
  end

  context "ceremony in belgium, lives in 3rd country, partner british" do
    setup do
      worldwide_api_has_organisations_for_location('belgium', read_fixture_file('worldwide/belgium_organisations.json'))
      add_response 'belgium'
    end

    should "go to outcome_opposite_sex_marriage_in_affirmation_countries for opposite sex marriages" do
      add_response 'third_country'
      add_response 'partner_other'
      add_response 'opposite_sex'
      assert_current_node :outcome_opposite_sex_marriage_in_affirmation_countries
    end

    should "go to outcome_same_sex_civil_partnership_in_affirmation_countries for same sex marriages for residents in a third country" do
      add_response 'third_country'
      add_response 'partner_british'
      add_response 'same_sex'
      assert_current_node :outcome_same_sex_civil_partnership_in_affirmation_countries
    end

    should "go to outcome_same_sex_civil_partnership_in_affirmation_countries for same sex marriages for residents in Belgium" do
      add_response 'ceremony_country'
      add_response 'partner_british'
      add_response 'same_sex'
      assert_current_node :outcome_same_sex_civil_partnership_in_affirmation_countries
    end
  end

  context "ceremony in armenia, resident in the UK, partner other" do
    setup do
      worldwide_api_has_organisations_for_location('armenia', read_fixture_file('worldwide/armenia_organisations.json'))
      add_response 'armenia'
      add_response 'uk'
      add_response 'partner_other'
      add_response 'opposite_sex'
    end
    should "go to consular cni os outcome" do
      assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_uk_or_ceremony_country
    end
  end

  #France or french overseas territories outcome
  context "ceremony in fot" do
    setup do
      worldwide_api_has_organisations_for_location('mayotte', read_fixture_file('worldwide/mayotte_organisations.json'))
      add_response 'mayotte'
    end
    should "go to marriage in france or fot outcome" do
      assert_current_node :outcome_marriage_in_france_or_french_overseas_territory
    end
  end

  context "ceremony in france" do
    setup do
      worldwide_api_has_organisations_for_location('france', read_fixture_file('worldwide/france_organisations.json'))
      add_response 'france'
      add_response 'marriage'
    end
    should "go to france or fot marriage outcome" do
      assert_current_node :outcome_marriage_in_france_or_french_overseas_territory
    end
  end

  #tests for affirmation to marry outcomes
  context "ceremony in thailand, resident in the UK, partner other" do
    setup do
      worldwide_api_has_organisations_for_location('thailand', read_fixture_file('worldwide/thailand_organisations.json'))
      add_response 'thailand'
      add_response 'uk'
      add_response 'partner_other'
      add_response 'opposite_sex'
    end
    should "go to os affirmation outcome" do
      assert_current_node :outcome_opposite_sex_marriage_in_affirmation_countries
    end
  end

  context "ceremony in colombia, partner colombian national, opposite sex" do
    setup do
      worldwide_api_has_organisations_for_location('colombia', read_fixture_file('worldwide/colombia_organisations.json'))
      add_response 'colombia'
      add_response 'uk'
      add_response 'partner_local'
      add_response 'opposite_sex'
    end
    should "go to os affirmation outcome" do
      assert_current_node :outcome_opposite_sex_marriage_in_colombia
    end
  end

  context "ceremony in Egypt, resident in egypt, partner british" do
    setup do
      worldwide_api_has_organisations_for_location('egypt', read_fixture_file('worldwide/egypt_organisations.json'))
      add_response 'egypt'
      add_response 'ceremony_country'
      add_response 'partner_british'
      add_response 'opposite_sex'
    end
    should "go to os affirmation outcome" do
      assert_current_node :outcome_opposite_sex_marriage_in_affirmation_countries
    end
  end

  context "ceremony in lebanon, lives elsewhere, partner other" do
    setup do
      worldwide_api_has_organisations_for_location('lebanon', read_fixture_file('worldwide/lebanon_organisations.json'))
      add_response 'lebanon'
      add_response 'third_country'
      add_response 'partner_other'
      add_response 'opposite_sex'
    end
    should "go to os affirmation outcome" do
      assert_current_node :outcome_opposite_sex_marriage_in_affirmation_countries
    end
  end

  context "ceremony in UAE, resident in UAE, partner local" do
    setup do
      worldwide_api_has_organisations_for_location('united-arab-emirates', read_fixture_file('worldwide/united-arab-emirates_organisations.json'))
      add_response 'united-arab-emirates'
      add_response 'ceremony_country'
      add_response 'partner_local'
      add_response 'opposite_sex'
    end
    should "go to os affirmation outcome" do
      assert_current_node :outcome_opposite_sex_marriage_in_affirmation_countries
    end
  end

  context "ceremony in Oman, resident in Oman, partner local" do
    setup do
      worldwide_api_has_organisations_for_location('oman', read_fixture_file('worldwide/oman_organisations.json'))
      add_response 'oman'
      add_response 'ceremony_country'
      add_response 'partner_local'
      add_response 'opposite_sex'
    end
    should "go to os oman outcome" do
      assert_current_node :outcome_opposite_sex_marriage_in_oman
    end
  end

  context "ceremony in Turkey, resident in the UK, partner local" do
    setup do
      worldwide_api_has_organisations_for_location('turkey', read_fixture_file('worldwide/turkey_organisations.json'))
      add_response 'turkey'
      add_response 'uk'
      add_response 'partner_local'
      add_response 'opposite_sex'
    end
    should "go to os affirmation outcome" do
      assert_current_node :outcome_opposite_sex_marriage_in_affirmation_countries
    end
  end

  context "ceremony in Turkey, resident in Turkey, partner other" do
    setup do
      worldwide_api_has_organisations_for_location('turkey', read_fixture_file('worldwide/turkey_organisations.json'))
      add_response 'turkey'
      add_response 'ceremony_country'
      add_response 'partner_other'
      add_response 'opposite_sex'
    end
    should "go to os affirmation outcome" do
      assert_current_node :outcome_opposite_sex_marriage_in_affirmation_countries
    end
  end

  context "ceremony in Ecuador, resident in Ecuador, partner other" do
    should "go to outcome os affirmation" do
      worldwide_api_has_organisations_for_location('ecuador', read_fixture_file('worldwide/ecuador_organisations.json'))
      add_response 'ecuador'
      add_response 'ceremony_country'
      add_response 'partner_other'
      add_response 'opposite_sex'
      assert_current_node :outcome_opposite_sex_marriage_in_affirmation_countries
    end
  end

  context "ceremony in Cambodia" do
    setup do
      worldwide_api_has_organisations_for_location('cambodia', read_fixture_file('worldwide/cambodia_organisations.json'))
      add_response 'cambodia'
    end

    context "resident in Cambodia, partner other" do
      setup do
        add_response 'ceremony_country'
        add_response 'partner_other'
        add_response 'opposite_sex'
      end
      should "go to os affirmation outcome" do
        assert_current_node :outcome_opposite_sex_marriage_in_cambodia
      end
    end

    context "lives elsewhere, same sex marriage, non british partner" do
      setup do
        add_response 'third_country'
        add_response 'partner_other'
        add_response 'same_sex'
      end
      should "go to outcome_same_sex_marriage_and_civil_partnership" do
        assert_current_node :outcome_same_sex_marriage_and_civil_partnership
      end
    end
  end

  #tests for no cni or consular services
  context "ceremony in aruba, resident in the UK, partner other" do
    setup do
      worldwide_api_has_organisations_for_location('aruba', read_fixture_file('worldwide/aruba_organisations.json'))
      add_response 'aruba'
      add_response 'uk'
      add_response 'partner_other'
      add_response 'opposite_sex'
    end
    should "go to consular cni os outcome" do
      assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_uk_or_ceremony_country
    end
  end

  context "ceremony in aruba, resident in aruba, partner british" do
    setup do
      worldwide_api_has_organisations_for_location('aruba', read_fixture_file('worldwide/aruba_organisations.json'))
      add_response 'aruba'
      add_response 'ceremony_country'
      add_response 'partner_british'
      add_response 'opposite_sex'
    end
    should "go to consular cni os outcome" do
      assert_current_node :outcome_opposite_sex_in_no_cni_countries_when_residing_in_ceremony_or_third_country
    end
  end

  context "ceremony in aruba, lives elsewhere, partner other" do
    setup do
      worldwide_api_has_organisations_for_location('aruba', read_fixture_file('worldwide/aruba_organisations.json'))
      add_response 'aruba'
      add_response 'third_country'
      add_response 'partner_other'
      add_response 'opposite_sex'
    end
    should "go to consular cni os outcome" do
      assert_current_node :outcome_opposite_sex_in_no_cni_countries_when_residing_in_ceremony_or_third_country
    end
  end

  context "ceremony in cote-d-ivoire" do
    setup do
      worldwide_api_has_organisations_for_location('cote-d-ivoire', read_fixture_file('worldwide/cote-d-ivoire_organisations.json'))
      add_response 'cote-d-ivoire'
    end

    should "lead to outcome_ceremonies_in_netherlands_or_marriage_via_local_authority_countries when in the UK" do
      add_response 'uk'
      add_response 'partner_british'
      add_response 'opposite_sex'
      assert_current_node :outcome_ceremonies_in_netherlands_or_marriage_via_local_authority_countries
    end

    should "lead to outcome_ceremonies_in_netherlands_or_marriage_via_local_authority_countries when in a third country" do
      add_response 'third_country'
      add_response 'partner_british'
      add_response 'opposite_sex'
      assert_current_node :outcome_ceremonies_in_netherlands_or_marriage_via_local_authority_countries
    end
  end

  context "ceremony in monaco, maps to France, marriage" do
    setup do
      worldwide_api_has_organisations_for_location('monaco', read_fixture_file('worldwide/monaco_organisations.json'))
      add_response 'monaco'
      add_response 'marriage'
    end
    should "go to outcome_marriage_in_monaco" do
      assert_current_node :outcome_marriage_in_monaco
    end
  end

  context "ceremony in monaco, maps to France, pacs" do
    setup do
      worldwide_api_has_organisations_for_location('monaco', read_fixture_file('worldwide/monaco_organisations.json'))
      add_response 'monaco'
      add_response 'pacs'
    end
    should "go to outcome_civil_partnership_in_monaco" do
      assert_current_node :outcome_civil_partnership_in_monaco
    end
  end

  context "user lives in 3rd country, ceremony in macedonia, partner os (any nationality)" do
    setup do
      worldwide_api_has_organisations_for_location('macedonia', read_fixture_file('worldwide/macedonia_organisations.json'))
      add_response 'macedonia'
      add_response 'third_country'
      add_response 'partner_other'
      add_response 'opposite_sex'
    end
    should "go to outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_third_country" do
      assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_third_country
    end
  end

  context "user lives in macedonia, ceremony in macedonia" do
    setup do
      worldwide_api_has_organisations_for_location('macedonia', read_fixture_file('worldwide/macedonia_organisations.json'))
      add_response 'macedonia'
      add_response 'ceremony_country'
      add_response 'partner_other'
      add_response 'opposite_sex'
    end
    should "go to consular cni os outcome" do
      assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_uk_or_ceremony_country
    end
  end

  context "ceremony in usa, lives elsewhere, partner other" do
    should "go to outcome_ceremonies_in_netherlands_or_marriage_via_local_authority_countries" do
      worldwide_api_has_organisations_for_location('usa', read_fixture_file('worldwide/usa_organisations.json'))
      add_response 'usa'
      add_response 'third_country'
      add_response 'partner_other'
      add_response 'opposite_sex'
      assert_current_node :outcome_ceremonies_in_netherlands_or_marriage_via_local_authority_countries
    end
  end

  context "ceremony in argentina, lives elsewhere, partner other" do
    should "go to outcome_ceremonies_in_netherlands_or_marriage_via_local_authority_countries" do
      worldwide_api_has_organisations_for_location('argentina', read_fixture_file('worldwide/argentina_organisations.json'))
      add_response 'argentina'
      add_response 'third_country'
      add_response 'partner_other'
      add_response 'opposite_sex'
      assert_current_node :outcome_ceremonies_in_netherlands_or_marriage_via_local_authority_countries
    end
  end

  context "ceremony in burma, resident in the UK, partner local" do
    setup do
      worldwide_api_has_organisations_for_location('burma', read_fixture_file('worldwide/burma_organisations.json'))
      add_response 'burma'
      add_response 'uk'
      add_response 'partner_local'
      add_response 'opposite_sex'
    end
    should "go to outcome_opposite_sex_marriage_in_burma" do
      assert_current_node :outcome_opposite_sex_marriage_in_burma
    end
  end

  context "ceremony in burundi, resident in 3rd country, partner anywhere" do
    setup do
      worldwide_api_has_organisations_for_location('burundi', read_fixture_file('worldwide/burundi_organisations.json'))
      add_response 'burundi'
      add_response 'third_country'
      add_response 'partner_other'
      add_response 'opposite_sex'
    end
    should "go to consular cni os outcome" do
      assert_current_node :outcome_opposite_sex_in_no_cni_countries_when_residing_in_ceremony_or_third_country
    end
  end

  context "ceremony in north korea, resident in the UK, partner local" do
    setup do
      worldwide_api_has_organisations_for_location('north-korea', read_fixture_file('worldwide/north-korea_organisations.json'))
      add_response 'north-korea'
      add_response 'uk'
      add_response 'partner_local'
      add_response 'opposite_sex'
    end
    should "go to outcome_opposite_sex_marriage_in_north_korea" do
      assert_current_node :outcome_opposite_sex_marriage_in_north_korea
    end
  end

  context "ceremony in iran, resident in the UK, partner local" do
    setup do
      worldwide_api_has_organisations_for_location('iran', read_fixture_file('worldwide/iran_organisations.json'))
      add_response 'iran'
      add_response 'uk'
      add_response 'partner_local'
      add_response 'opposite_sex'
    end
    should "go to consular cni os outcome" do
      assert_current_node :outcome_opposite_sex_marriage_in_other_countries
    end
  end

  context "ceremony in yemen, resident in the UK, partner local" do
    setup do
      worldwide_api_has_organisations_for_location('yemen', read_fixture_file('worldwide/yemen_organisations.json'))
      add_response 'yemen'
      add_response 'uk'
      add_response 'partner_local'
      add_response 'opposite_sex'
    end
    should "go to outcome_opposite_sex_marriage_in_yemen" do # Consular services in Yemen are temporarily ceased. Normal outcome: consular cni os outcome
      assert_current_node :outcome_opposite_sex_marriage_in_yemen
    end
  end

  context "ceremony in saudi arabia, resident in the UK, partner other" do
    setup do
      worldwide_api_has_organisations_for_location('saudi-arabia', read_fixture_file('worldwide/saudi-arabia_organisations.json'))
      add_response 'saudi-arabia'
      add_response 'uk'
      add_response 'partner_other'
      add_response 'opposite_sex'
    end
    should "go to outcome_opposite_sex_marriage_in_saudi_arabia" do
      assert_current_node :outcome_opposite_sex_marriage_in_saudi_arabia
    end
  end

  context "ceremony in saudi arabia, resident in saudi arabia, partner british" do
    setup do
      worldwide_api_has_organisations_for_location('saudi-arabia', read_fixture_file('worldwide/saudi-arabia_organisations.json'))
      add_response 'saudi-arabia'
      add_response 'ceremony_country'
      add_response 'partner_british'
      add_response 'opposite_sex'
    end
    should "go to outcome_opposite_sex_marriage_in_saudi_arabia" do
      assert_current_node :outcome_opposite_sex_marriage_in_saudi_arabia
    end
  end

  context "ceremony in saudi arabia, resident in saudi arabia, partner other" do
    setup do
      worldwide_api_has_organisations_for_location('saudi-arabia', read_fixture_file('worldwide/saudi-arabia_organisations.json'))
      add_response 'saudi-arabia'
      add_response 'ceremony_country'
      add_response 'partner_other'
      add_response 'opposite_sex'
    end
    should "go to outcome_opposite_sex_marriage_in_saudi_arabia" do
      assert_current_node :outcome_opposite_sex_marriage_in_saudi_arabia
    end
  end

  context "ceremony in russia, resident in russia, partner british" do
    setup do
      worldwide_api_has_organisations_for_location('russia', read_fixture_file('worldwide/russia_organisations.json'))
      add_response 'russia'
      add_response 'ceremony_country'
      add_response 'partner_local'
      add_response 'opposite_sex'
    end
    should "go to russia CNI outcome" do
      assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_uk_or_ceremony_country
    end
  end

  context "ceremony in denmark, resident in england, partner other" do
    setup do
      worldwide_api_has_organisations_for_location('denmark', read_fixture_file('worldwide/denmark_organisations.json'))
      add_response 'denmark'
      add_response 'uk'
      add_response 'partner_other'
      add_response 'same_sex'
    end
    should "go to cp or equivalent outcome" do
      assert_current_node :outcome_same_sex_civil_partnership
    end
  end

  context "ceremony in czech republic, lives elsewhere, partner local" do
    setup do
      worldwide_api_has_organisations_for_location('czech-republic', read_fixture_file('worldwide/czech-republic_organisations.json'))
      add_response 'czech-republic'
      add_response 'third_country'
      add_response 'partner_local'
      add_response 'same_sex'
    end
    should "go to cp or equivalent outcome" do
      assert_current_node :outcome_same_sex_civil_partnership
      assert_equal 'the Czech Republic', current_state.calculator.country_name_lowercase_prefix
    end
  end

  context "ceremony in sweden," do
    setup do
      worldwide_api_has_organisations_for_location('sweden', read_fixture_file('worldwide/sweden_organisations.json'))
      add_response 'sweden'
    end
    context "resident in uk," do
      setup { add_response 'uk' }
      context "partner is british," do
        setup { add_response 'partner_british' }
        context "opposite sex" do
          setup { add_response 'opposite_sex' }
          should "go to cp or equivalent os outcome" do
            assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_uk_or_ceremony_country
          end
        end
        context "same sex" do
          setup { add_response 'same_sex' }
          should "go to cp or equivalent os outcome" do
            assert_current_node :outcome_same_sex_civil_partnership
          end
        end
      end
      context "partner is local," do
        setup { add_response 'partner_local' }
        context "opposite sex" do
          setup { add_response 'opposite_sex' }
          should "go to cp or equivalent os outcome" do
            assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_uk_or_ceremony_country
          end
        end
        context "same sex" do
          setup { add_response 'same_sex' }
          should "go to cp or equivalent os outcome" do
            assert_current_node :outcome_same_sex_civil_partnership
          end
        end
      end
      context "partner is other," do
        setup { add_response 'partner_other' }
        context "opposite sex" do
          setup { add_response 'opposite_sex' }
          should "go to cp or equivalent os outcome" do
            assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_uk_or_ceremony_country
          end
        end
        context "same sex" do
          setup { add_response 'same_sex' }
          should "go to cp or equivalent os outcome" do
            assert_current_node :outcome_same_sex_civil_partnership
          end
        end
      end
    end
    context "resident in ceremony country" do
      setup { add_response 'ceremony_country' }
      context "partner is british," do
        setup { add_response 'partner_british' }
        context "opposite sex" do
          setup { add_response 'opposite_sex' }
          should "go to cp or equivalent os outcome" do
            assert_current_node :outcome_ceremonies_in_sweden_when_residing_in_sweden
          end
        end
        context "same sex" do
          setup { add_response 'same_sex' }
          should "go to cp or equivalent os outcome" do
            assert_current_node :outcome_ceremonies_in_sweden_when_residing_in_sweden
          end
        end
      end
      context "partner is local," do
        setup { add_response 'partner_local' }
        context "opposite sex" do
          setup { add_response 'opposite_sex' }
          should "go to cp or equivalent os outcome" do
            assert_current_node :outcome_ceremonies_in_sweden_when_residing_in_sweden
          end
        end
        context "same sex" do
          setup { add_response 'same_sex' }
          should "go to cp or equivalent os outcome" do
            assert_current_node :outcome_ceremonies_in_sweden_when_residing_in_sweden
          end
        end
      end
      context "partner is other," do
        setup { add_response 'partner_other' }
        context "opposite sex" do
          setup { add_response 'opposite_sex' }
          should "go to cp or equivalent os outcome" do
            assert_current_node :outcome_ceremonies_in_sweden_when_residing_in_sweden
          end
        end
        context "same sex" do
          setup { add_response 'same_sex' }
          should "go to cp or equivalent os outcome" do
            assert_current_node :outcome_ceremonies_in_sweden_when_residing_in_sweden
          end
        end
      end
    end
    context "resident in elsewhere," do
      setup { add_response 'third_country' }
      context "partner is british," do
        setup { add_response 'partner_british' }
        context "opposite sex" do
          setup { add_response 'opposite_sex' }
          should "go to cp or equivalent os outcome" do
            assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_third_country
          end
        end
        context "same sex" do
          setup { add_response 'same_sex' }
          should "go to cp or equivalent os outcome" do
            assert_current_node :outcome_same_sex_civil_partnership
          end
        end
      end
      context "partner is local," do
        setup { add_response 'partner_local' }
        context "opposite sex" do
          setup { add_response 'opposite_sex' }
          should "go to cp or equivalent os outcome" do
            assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_third_country
          end
        end
        context "same sex" do
          setup { add_response 'same_sex' }
          should "go to cp or equivalent os outcome" do
            assert_current_node :outcome_same_sex_civil_partnership
          end
        end
      end
      context "partner is other," do
        setup { add_response 'partner_other' }
        context "opposite sex" do
          setup { add_response 'opposite_sex' }
          should "go to cp or equivalent os outcome" do
            assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_third_country
          end
        end
        context "same sex" do
          setup { add_response 'same_sex' }
          should "go to cp or equivalent os outcome" do
            assert_current_node :outcome_same_sex_civil_partnership
          end
        end
      end
    end
  end

  context "ceremony in france, " do
    setup do
      worldwide_api_has_organisations_for_location('france', read_fixture_file('worldwide/france_organisations.json'))
      add_response 'france'
      add_response 'pacs'
    end
    should "go to fran ce ot fot PACS outcome" do
      assert_current_node :outcome_civil_partnership_in_france_or_french_overseas_territory
    end
  end

  context "ceremony in wallis and futuna, pacs" do
    setup do
      worldwide_api_has_organisations_for_location('wallis-and-futuna', read_fixture_file('worldwide/wallis-and-futuna_organisations.json'))
      add_response 'wallis-and-futuna'
      add_response 'pacs'
    end
    should "go to france or fot pacs outcome" do
      assert_current_node :outcome_civil_partnership_in_france_or_french_overseas_territory
    end
  end

  context "ceremony in US, same sex local partner" do
    setup do
      worldwide_api_has_organisations_for_location('usa', read_fixture_file('worldwide/usa_organisations.json'))
      add_response 'usa'
    end

    should "go to cp no cni required outcome and suggest both legal and travel advice to a UK resident" do
      add_response 'uk'
      add_response 'partner_local'
      add_response 'same_sex'
      assert_current_node :outcome_same_sex_civil_partnership_in_no_cni_countries
      assert_equal 'the USA', current_state.calculator.country_name_lowercase_prefix
    end

    should "go to cp no cni required outcome and suggest legal advice to a US resident" do
      add_response 'ceremony_country'
      add_response 'partner_local'
      add_response 'same_sex'
      assert_current_node :outcome_same_sex_civil_partnership_in_no_cni_countries
      assert_equal 'the USA', current_state.calculator.country_name_lowercase_prefix
    end
  end

  context "ceremony in bonaire, resident in the UK, partner other" do
    setup do
      worldwide_api_has_organisations_for_location('bonaire-st-eustatius-saba', read_fixture_file('worldwide/bonaire-st-eustatius-saba_organisations.json'))
      add_response 'bonaire-st-eustatius-saba'
      add_response 'uk'
      add_response 'partner_other'
      add_response 'same_sex'
    end
    should "go to cp no cni required outcome" do
      assert_current_node :outcome_same_sex_civil_partnership_in_no_cni_countries
    end
  end

  context "ceremony in bonaire, resident in bonaire, partner british" do
    setup do
      worldwide_api_has_organisations_for_location('bonaire-st-eustatius-saba', read_fixture_file('worldwide/bonaire-st-eustatius-saba_organisations.json'))
      add_response 'bonaire-st-eustatius-saba'
      add_response 'ceremony_country'
      add_response 'partner_british'
      add_response 'same_sex'
    end
    should "go to cp no cni required outcome" do
      assert_current_node :outcome_same_sex_civil_partnership_in_no_cni_countries
    end
  end

  context "ceremony in bonaire, resident in third country, partner other" do
    setup do
      worldwide_api_has_organisations_for_location('bonaire-st-eustatius-saba', read_fixture_file('worldwide/bonaire-st-eustatius-saba_organisations.json'))
      add_response 'bonaire-st-eustatius-saba'
      add_response 'third_country'
      add_response 'partner_other'
      add_response 'same_sex'
    end
    should "go to cp no cni required outcome" do
      assert_current_node :outcome_same_sex_civil_partnership_in_no_cni_countries
    end
  end

  context "ceremony in canada, UK resident, partner other" do
    setup do
      worldwide_api_has_organisations_for_location('canada', read_fixture_file('worldwide/canada_organisations.json'))
      add_response 'canada'
      add_response 'uk'
      add_response 'partner_other'
      add_response 'same_sex'
    end
    should "go to cp commonwealth countries outcome" do
      assert_current_node :outcome_same_sex_civil_partnership_in_commonwealth_countries
    end
  end

  context "ceremony in czech-republic, uk resident, partner other" do
    setup do
      worldwide_api_has_organisations_for_location('czech-republic', read_fixture_file('worldwide/czech-republic_organisations.json'))
      add_response 'czech-republic'
      add_response 'uk'
      add_response 'partner_other'
      add_response 'same_sex'
    end
    should "go to consular cni cp countries outcome" do
      assert_current_node :outcome_same_sex_civil_partnership
    end
  end

  context "ceremony in vietnam, uk resident, partner local" do
    setup do
      worldwide_api_has_organisations_for_location('vietnam', read_fixture_file('worldwide/vietnam_organisations.json'))
      add_response 'vietnam'
      add_response 'uk'
      add_response 'partner_local'
      add_response 'same_sex'
    end
    should "go to all other countries outcome" do
      assert_current_node :outcome_same_sex_marriage_and_civil_partnership_not_possible
    end
  end

  context "ceremony in turkmenistan" do
    setup do
      worldwide_api_has_organisations_for_location('turkmenistan', read_fixture_file('worldwide/turkmenistan_organisations.json'))
      add_response 'turkmenistan'
      add_response 'uk'
      add_response 'partner_local'
      add_response 'same_sex'
    end
    should "go to all other countries outcome" do
      assert_current_node :outcome_same_sex_marriage_and_civil_partnership_in_other_countries
    end
  end

  context "ceremony in latvia, lives elsewhere, partner british" do
    setup do
      worldwide_api_has_organisations_for_location('latvia', read_fixture_file('worldwide/latvia_organisations.json'))
      add_response 'latvia'
      add_response 'third_country'
      add_response 'partner_british'
      add_response 'same_sex'
    end
    should "go to consular cni cp countries outcome" do
      assert_current_node :outcome_same_sex_marriage_and_civil_partnership
    end
  end

  context "ceremony in serbia, lives elsewhere, partner british" do
    setup do
      worldwide_api_has_organisations_for_location('serbia', read_fixture_file('worldwide/serbia_organisations.json'))
      add_response 'serbia'
      add_response 'third_country'
      add_response 'partner_british'
      add_response 'same_sex'
    end
    should "go to cp all other countries outcome" do
      assert_current_node :outcome_same_sex_marriage_and_civil_partnership
    end
  end

  context "ceremony in Nicaragua" do
    setup do
      worldwide_api_has_organisations_for_location('nicaragua', read_fixture_file('worldwide/nicaragua_organisations.json'))
      add_response 'nicaragua'
    end

    should "go to consular cni os outcome when user resides in Nicaragua and show address of the Embassy in Costa Rica" do
      add_response 'ceremony_country'
      add_response 'partner_other'
      add_response 'opposite_sex'
      assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_uk_or_ceremony_country
      assert_equal "British Embassy San Jose", current_state.calculator.fco_organisation.title
    end

    should "go to outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_third_country and suggest arranging CNI through the Embassy in Costa Rica" do
      add_response 'third_country'
      add_response 'partner_other'
      add_response 'opposite_sex'
      assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_third_country
    end
  end

  context "ceremony in australia, resident in the UK" do
    setup do
      worldwide_api_has_organisations_for_location('australia', read_fixture_file('worldwide/australia_organisations.json'))
      add_response 'australia'
      add_response 'uk'
      add_response 'partner_local'
      add_response 'same_sex'
    end
    should "go to outcome_same_sex_marriage_and_civil_partnership" do
      assert_current_node :outcome_same_sex_marriage_and_civil_partnership
    end
  end

  context "australia opposite sex outcome" do
    should "bring you to australia os outcome" do
      worldwide_api_has_organisations_for_location('australia', read_fixture_file('worldwide/australia_organisations.json'))
      add_response 'australia'
      add_response 'ceremony_country'
      add_response 'partner_british'
      add_response 'same_sex'
      assert_current_node :outcome_same_sex_marriage_and_civil_partnership
    end
  end

  context "ceremony in china, partner is not from china, opposite sex" do
    should "render address from API" do
      worldwide_api_has_organisations_for_location('china', read_fixture_file('worldwide/china_organisations.json'))
      add_response 'china'
      add_response 'uk'
      add_response 'partner_other'
      add_response 'opposite_sex'
      assert_current_node :outcome_opposite_sex_marriage_in_affirmation_countries
    end
  end

  context "ceremony in china, partner is not from china, same sex" do
    should "render address from API" do
      worldwide_api_has_organisations_for_location('china', read_fixture_file('worldwide/china_organisations.json'))
      add_response 'china'
      add_response 'uk'
      add_response 'partner_other'
      add_response 'same_sex'
      assert_current_node :outcome_same_sex_marriage_and_civil_partnership
    end
  end

  context "ceremony in china, partner is national of china" do
    should "render address from API" do
      worldwide_api_has_organisations_for_location('china', read_fixture_file('worldwide/china_organisations.json'))
      add_response 'china'
      add_response 'ceremony_country'
      add_response 'partner_local'
      add_response 'opposite_sex'
      assert_current_node :outcome_opposite_sex_marriage_in_affirmation_countries
    end
  end

  context "ceremony in Japan" do
    setup do
      worldwide_api_has_organisations_for_location('japan', read_fixture_file('worldwide/japan_organisations.json'))
      add_response 'japan'
    end

    context "resident of Japan with a local resident" do
      setup do
        add_response 'ceremony_country'
        add_response 'partner_local'
      end

      should "give a japan-specific outcome" do
        add_response 'opposite_sex'
        assert_current_node :outcome_opposite_sex_marriage_in_japan
      end
      should "give ss outcome with japan variants" do
        add_response 'same_sex'
        assert_current_node :outcome_same_sex_marriage_and_civil_partnership
      end
    end

    context "opposite sex UK residents" do
      setup do
        add_response 'uk'
        add_response 'partner_british'
        add_response 'opposite_sex'
      end

      should "have a japan-specific intro" do
        assert_current_node :outcome_opposite_sex_marriage_in_japan
      end
    end

    context "resident of Japan with an opposite sex partner from anywhere" do
      setup do
        add_response 'ceremony_country'
        add_response 'partner_other'
        add_response 'opposite_sex'
      end

      should "give CNI outcome when marrying to an opposite sex non-local partner" do
        assert_current_node :outcome_opposite_sex_marriage_in_japan
      end
    end

    context "resident of third country" do
      setup do
        add_response 'third_country'
        add_response 'partner_other'
        add_response 'opposite_sex'
      end

      should "takes the user to a Japan specific outcome for opposite sex marriages" do
        assert_current_node :outcome_opposite_sex_marriage_in_japan
      end
    end
  end

  context 'Ceremony in Slovenia' do
    setup do
      worldwide_api_has_organisations_for_location('slovenia', read_fixture_file('worldwide/slovenia_organisations.json'))
      add_response 'slovenia'
    end

    context 'for opposite sex couples' do
      setup do
        add_response 'ceremony_country'
        add_response 'partner_other'
        add_response 'opposite_sex'
      end

      should 'give a Slovenia specific outcome' do
        assert_current_node :outcome_opposite_sex_marriage_in_slovenia_when_residing_in_uk_or_slovenia
      end
    end
  end

  context "testing that Vietnam is now affirmation to marry outcome" do
    should "give the outcome" do
      worldwide_api_has_organisations_for_location('vietnam', read_fixture_file('worldwide/vietnam_organisations.json'))
      add_response 'vietnam'
      add_response 'uk'
      add_response 'partner_local'
      add_response 'opposite_sex'
      assert_current_node :outcome_opposite_sex_marriage_in_affirmation_countries
    end
  end

  context "ceremony in switzerland, resident in switzerland, partner opposite sex" do
    should "give swiss outcome with variants (gender variant)" do
      worldwide_api_has_organisations_for_location('switzerland', read_fixture_file('worldwide/switzerland_organisations.json'))
      add_response 'switzerland'
      add_response 'uk'
      add_response 'opposite_sex'
      assert_current_node :outcome_ceremonies_in_switzerland
    end
  end

  context "ceremony in switzerland, resident in switzerland, partner same sex" do
    should "give swiss outcome with variants" do
      worldwide_api_has_organisations_for_location('switzerland', read_fixture_file('worldwide/switzerland_organisations.json'))
      add_response 'switzerland'
      add_response 'ceremony_country'
      add_response 'same_sex'
      assert_current_node :outcome_ceremonies_in_switzerland
    end
  end

  context "ceremony in switzerland, not resident in switzerland, partner opposite sex" do
    should "give swiss outcome with variants" do
      worldwide_api_has_organisations_for_location('switzerland', read_fixture_file('worldwide/switzerland_organisations.json'))
      add_response 'switzerland'
      add_response 'uk'
      add_response 'same_sex'
      assert_current_node :outcome_ceremonies_in_switzerland
    end
  end

  context "ceremony in switzerland, not resident in switzerland, partner same sex" do
    should "give swiss outcome with variants" do
      worldwide_api_has_organisations_for_location('switzerland', read_fixture_file('worldwide/switzerland_organisations.json'))
      add_response 'switzerland'
      add_response 'third_country'
      add_response 'opposite_sex'
      assert_current_node :outcome_ceremonies_in_switzerland
    end
  end

  context "peru outcome mapped to lebanon for same sex" do
    should "go to outcome cp all other countries" do
      worldwide_api_has_organisations_for_location('peru', read_fixture_file('worldwide/peru_organisations.json'))
      add_response 'peru'
      add_response 'uk'
      add_response 'partner_british'
      add_response 'same_sex'
      assert_current_node :outcome_same_sex_marriage_and_civil_partnership
    end
  end

  context "peru outcome mapped to lebanon for opposite sex" do
    should "go to outcome os affirmation" do
      worldwide_api_has_organisations_for_location('peru', read_fixture_file('worldwide/peru_organisations.json'))
      add_response 'peru'
      add_response 'uk'
      add_response 'partner_british'
      add_response 'opposite_sex'
      assert_current_node :outcome_opposite_sex_marriage_in_affirmation_countries
    end
  end

  context "portugal has his own outcome" do
    should "go to portugal outcome" do
      worldwide_api_has_organisations_for_location('portugal', read_fixture_file('worldwide/portugal_organisations.json'))
      add_response 'portugal'
      add_response 'uk'
      add_response 'partner_british'
      add_response 'opposite_sex'
      assert_current_node :outcome_ceremonies_in_portugal
    end
  end

  context "ceremony in finland, resident in the UK, partner british" do
    setup do
      worldwide_api_has_organisations_for_location('finland', read_fixture_file('worldwide/finland_organisations.json'))
      add_response 'finland'
      add_response 'uk'
      add_response 'partner_british'
      add_response 'opposite_sex'
    end
    should "go to cni outcome" do
      assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_uk_or_ceremony_country
    end
  end

  context "ceremony in finland, resident in the UK, partner local" do
    setup do
      worldwide_api_has_organisations_for_location('finland', read_fixture_file('worldwide/finland_organisations.json'))
      add_response 'finland'
      add_response 'uk'
      add_response 'partner_local'
      add_response 'opposite_sex'
    end
    should "go to cni outcome" do
      assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_uk_or_ceremony_country
    end
  end

  context "ceremony in finland, resident in Australia, partner other" do
    setup do
      worldwide_api_has_organisations_for_location('finland', read_fixture_file('worldwide/finland_organisations.json'))
      add_response 'finland'
      add_response 'third_country'
      add_response 'partner_other'
      add_response 'opposite_sex'
    end
    should "go to affirmation outcome with specific fee table" do
      assert_current_node :outcome_opposite_sex_marriage_in_affirmation_countries
    end
  end

  context "ceremony in finland, resident in the UK, partner other" do
    setup do
      worldwide_api_has_organisations_for_location('finland', read_fixture_file('worldwide/finland_organisations.json'))
      add_response 'finland'
      add_response 'uk'
      add_response 'partner_other'
      add_response 'opposite_sex'
    end
    should "go to outcome cni with specific fee table" do
      assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_uk_or_ceremony_country
    end
  end

  context "ceremony in finland, resident in the UK, partner other, SS" do
    setup do
      worldwide_api_has_organisations_for_location('finland', read_fixture_file('worldwide/finland_organisations.json'))
      add_response 'finland'
      add_response 'uk'
      add_response 'partner_other'
      add_response 'same_sex'
    end
    should "go to affirmation outcome with specific fee table" do
      assert_current_node :outcome_same_sex_civil_partnership
    end
  end

  context "south-korea new outcome" do
    should "go to :outcome_opposite_sex_marriage_in_affirmation_countries outcome" do
      worldwide_api_has_organisations_for_location('south-korea', read_fixture_file('worldwide/south-korea_organisations.json'))
      add_response 'south-korea'
      add_response 'uk'
      add_response 'partner_british'
      add_response 'opposite_sex'
      assert_current_node :outcome_opposite_sex_marriage_in_affirmation_countries
    end
  end

  context "ceremony in philippines, uk resident, partner other" do
    setup do
      worldwide_api_has_organisations_for_location('philippines', read_fixture_file('worldwide/philippines_organisations.json'))
      add_response 'philippines'
      add_response 'uk'
      add_response 'partner_local'
      add_response 'opposite_sex'
    end
    should "go to os affirmation outcome" do
      assert_current_node :outcome_opposite_sex_marriage_in_affirmation_countries
    end
  end

  context "Slovakia" do
    should "lead to outcome_ceremonies_in_netherlands_or_marriage_via_local_authority_countries" do
      worldwide_api_has_organisations_for_location('slovakia', read_fixture_file('worldwide/slovakia_organisations.json'))
      add_response 'slovakia'
      add_response 'uk'
      add_response 'partner_british'
      add_response 'opposite_sex'
      assert_current_node :outcome_ceremonies_in_netherlands_or_marriage_via_local_authority_countries
    end
  end

  context "Ukraine" do
    should "lead to outcome_ceremonies_in_netherlands_or_marriage_via_local_authority_countries" do
      worldwide_api_has_organisations_for_location('ukraine', read_fixture_file('worldwide/ukraine_organisations.json'))
      add_response 'ukraine'
      add_response 'uk'
      add_response 'partner_british'
      add_response 'opposite_sex'
      assert_current_node :outcome_ceremonies_in_netherlands_or_marriage_via_local_authority_countries
    end
  end

  context "Netherlands" do
    should "bring you to outcome_ceremonies_in_netherlands_or_marriage_via_local_authority_countries" do
      worldwide_api_has_organisations_for_location('netherlands', read_fixture_file('worldwide/netherlands_organisations.json'))
      add_response 'netherlands'
      add_response 'uk'
      add_response 'partner_british'
      add_response 'opposite_sex'
      assert_current_node :outcome_ceremonies_in_netherlands_or_marriage_via_local_authority_countries
    end
  end

  context "Indonesia, opposite sex outcome" do
    setup do
      worldwide_api_has_organisations_for_location('indonesia', read_fixture_file('worldwide/indonesia_organisations.json'))
      add_response 'indonesia'
    end

    should "bring you to the custom Indonesia os outcome for uk residents" do
      add_response 'uk'
      add_response 'partner_british'
      add_response 'opposite_sex'
      assert_current_node :outcome_opposite_sex_marriage_in_indonesia
    end

    should "bring you to the custom Indonesia os outcome for third country residents" do
      add_response 'third_country'
      add_response 'partner_british'
      add_response 'opposite_sex'
      assert_current_node :outcome_opposite_sex_marriage_in_indonesia
    end
  end

  context "aruba opposite sex outcome" do
    should "bring you to aruba os outcome" do
      worldwide_api_has_organisations_for_location('aruba', read_fixture_file('worldwide/aruba_organisations.json'))
      add_response 'aruba'
      add_response 'uk'
      add_response 'partner_british'
      add_response 'opposite_sex'
      assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_uk_or_ceremony_country
    end
  end

  context "ceremony in azerbaijan, resident in the UK, same sex non-local partner" do
    setup do
      worldwide_api_has_organisations_for_location('azerbaijan', read_fixture_file('worldwide/azerbaijan_organisations.json'))
      add_response 'azerbaijan'
      add_response 'uk'
      add_response 'partner_other'
      add_response 'same_sex'
    end
    should "go to outcome_same_sex_marriage_and_civil_partnership" do
      assert_current_node :outcome_same_sex_marriage_and_civil_partnership
    end
  end

  context "uk resident, ceremony in estonia, partner same sex british" do
    setup do
      worldwide_api_has_organisations_for_location('estonia', read_fixture_file('worldwide/estonia_organisations.json'))
      add_response 'estonia'
      add_response 'uk'
      add_response 'partner_british'
      add_response 'same_sex'
    end
    should "go to ss outcome" do
      assert_current_node :outcome_same_sex_marriage_and_civil_partnership
    end
  end

  context "ceremony in russia, lives elsewhere, same sex marriage, non british partner" do
    setup do
      worldwide_api_has_organisations_for_location('russia', read_fixture_file('worldwide/russia_organisations.json'))
      add_response 'russia'
      add_response 'third_country'
      add_response 'partner_other'
      add_response 'same_sex'
    end
    should "go to outcome_same_sex_marriage_and_civil_partnership_not_possible" do
      assert_current_node :outcome_same_sex_marriage_and_civil_partnership_not_possible
    end
  end

  context "Marrying anywhere in the world > British National living in third country > Partner of any nationality > Opposite sex" do
    setup do
      worldwide_api_has_organisations_for_location('vietnam', read_fixture_file('worldwide/vietnam_organisations.json'))
      add_response 'vietnam'
      add_response 'third_country'
      add_response 'partner_other'
      add_response 'opposite_sex'
    end
    should "go to affirmation_os_outcome" do
      assert_current_node :outcome_opposite_sex_marriage_in_affirmation_countries
    end
  end

  context "kazakhstan should show its correct embassy page" do
    setup do
      worldwide_api_has_organisations_for_location('kazakhstan', read_fixture_file('worldwide/kazakhstan_organisations.json'))
      add_response 'kazakhstan'
      add_response 'third_country'
      add_response 'partner_british'
      add_response 'opposite_sex'
    end
    should "go to outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_third_country" do
      assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_third_country
    end
  end

  context "Marrying in Portugal > British National not living in the UK > Resident anywhere > Partner of any nationality > Opposite sex" do
    setup do
      worldwide_api_has_organisations_for_location('portugal', read_fixture_file('worldwide/portugal_organisations.json'))
      add_response 'portugal'
      add_response 'third_country'
      add_response 'partner_other'
      add_response 'opposite_sex'
    end
    should "go to portugal outcome" do
      assert_current_node :outcome_ceremonies_in_portugal
    end
  end

  context "Marrying in Portugal > British National living in the UK > Partner of any nationality > Opposite sex" do
    setup do
      worldwide_api_has_organisations_for_location('portugal', read_fixture_file('worldwide/portugal_organisations.json'))
      add_response 'portugal'
      add_response 'uk'
      add_response 'partner_other'
      add_response 'opposite_sex'
    end
    should "go to portugal outcome" do
      assert_current_node :outcome_ceremonies_in_portugal
    end
  end

  context "Residency Country and ceremony country = Croatia" do
    setup do
      worldwide_api_has_organisations_for_location('croatia', read_fixture_file('worldwide/croatia_organisations.json'))
      add_response 'croatia'
      add_response 'ceremony_country'
      add_response 'partner_other'
      add_response 'opposite_sex'
    end
    should "go to :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_uk_or_ceremony_country outcome" do
      assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_uk_or_ceremony_country
    end
  end

  context "Marrying in Qatar" do
    setup do
      worldwide_api_has_organisations_for_location('qatar', read_fixture_file('worldwide/croatia_organisations.json'))
      add_response 'qatar'
    end
    should "go to :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_uk_or_ceremony_country outcome" do
      add_response 'ceremony_country'
      add_response 'partner_other'
      add_response 'opposite_sex'
      assert_current_node :outcome_opposite_sex_marriage_in_affirmation_countries
    end

    should "go to outcome_opposite_sex_marriage_in_affirmation_countries outcome" do
      add_response 'third_country'
      add_response 'partner_other'
      add_response 'opposite_sex'
      assert_current_node :outcome_opposite_sex_marriage_in_affirmation_countries
    end
  end

  context "ceremony in Lithuania, partner same sex, partner british" do
    setup do
      worldwide_api_has_organisations_for_location('lithuania', read_fixture_file('worldwide/lithuania_organisations.json'))
      add_response 'lithuania'
      add_response 'ceremony_country'
      add_response 'partner_british'
      add_response 'same_sex'
    end
    should "go to outcome_same_sex_marriage_and_civil_partnership" do
      assert_current_node :outcome_same_sex_marriage_and_civil_partnership
    end
  end

  context "ceremony in Lithuania, partner same sex, partner not british" do
    setup do
      worldwide_api_has_organisations_for_location('lithuania', read_fixture_file('worldwide/lithuania_organisations.json'))
      add_response 'lithuania'
      add_response 'ceremony_country'
      add_response 'partner_local'
      add_response 'same_sex'
    end
    should "go to outcome 'no same sex marriage allowed' because partner is not british" do
      assert_current_node :outcome_same_sex_marriage_and_civil_partnership_in_other_countries
    end
  end

  context "Ceremony in Belarus" do
    setup do
      worldwide_api_has_organisations_for_location('belarus', read_fixture_file('worldwide/belarus_organisations.json'))
      add_response 'belarus'
    end
    should "go to outcome_opposite_sex_marriage_in_belarus and show correct link for appointments in Minsk, opposite sex marriage" do
      add_response 'ceremony_country'
      add_response 'partner_british'
      add_response 'opposite_sex'
      assert_current_node :outcome_opposite_sex_marriage_in_belarus
      assert_match /Make an appointment at the embassy in Minsk/, outcome_body
    end

    should "go to outcome_opposite_sex_marriage_in_belarus when in third country" do
      add_response 'third_country'
      add_response 'partner_british'
      add_response 'opposite_sex'
      assert_current_node :outcome_opposite_sex_marriage_in_belarus
    end
  end

  context "test morocco specific, living in the UK" do
    setup do
      worldwide_api_has_organisations_for_location('morocco', read_fixture_file('worldwide/morocco_organisations.json'))
      add_response 'morocco'
      add_response 'uk'
      add_response 'partner_british'
      add_response 'opposite_sex'
    end
    should "go to os affirmation outcome" do
      assert_current_node :outcome_opposite_sex_marriage_in_affirmation_countries
    end
  end

  context "test morocco specific, living elsewhere" do
    setup do
      worldwide_api_has_organisations_for_location('morocco', read_fixture_file('worldwide/morocco_organisations.json'))
      add_response 'morocco'
      add_response 'third_country'
      add_response 'partner_british'
      add_response 'opposite_sex'
    end
    should "go to os affirmation outcome" do
      assert_current_node :outcome_opposite_sex_marriage_in_affirmation_countries
    end
  end

  context "Mexico" do
    setup do
      worldwide_api_has_organisations_for_location('mexico', read_fixture_file('worldwide/mexico_organisations.json'))
      add_response 'mexico'
    end

    should "go to outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_third_country" do
      add_response 'third_country'
      add_response 'partner_british'
      add_response 'opposite_sex'
      assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_third_country
    end

    should "show outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_uk_or_ceremony_country when partner is local" do
      add_response 'ceremony_country'
      add_response 'partner_local'
      add_response 'opposite_sex'
      assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_uk_or_ceremony_country
    end

    should "show outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_uk_or_ceremony_country when partner is british" do
      add_response 'ceremony_country'
      add_response 'partner_british'
      add_response 'opposite_sex'
      assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_uk_or_ceremony_country
    end
  end

  context "Marriage in Albania, living elsewhere, partner British, opposite sex" do
    setup do
      worldwide_api_has_organisations_for_location('albania', read_fixture_file('worldwide/albania_organisations.json'))
      add_response 'albania'
      add_response 'third_country'
      add_response 'partner_british'
      add_response 'opposite_sex'
    end
    should "lead to outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_third_country" do
      assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_third_country
    end
  end

  context "Marriage in Democratic Republic of Congo, living elsewhere, partner British, opposite sex" do
    setup do
      worldwide_api_has_organisations_for_location('democratic-republic-of-congo', read_fixture_file('worldwide/democratic-republic-of-congo_organisations.json'))
      add_response 'democratic-republic-of-congo'
      add_response 'third_country'
      add_response 'partner_british'
      add_response 'opposite_sex'
    end
    should "lead to outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_third_country" do
      assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_third_country
    end
  end

  context "Marriage in Mexico, living in the UK, partner British, opposite sex" do
    setup do
      worldwide_api_has_organisations_for_location('mexico', read_fixture_file('worldwide/mexico_organisations.json'))
      add_response 'mexico'
      add_response 'uk'
      add_response 'partner_british'
      add_response 'opposite_sex'
    end
    should "show outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_uk_or_ceremony_country" do
      assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_uk_or_ceremony_country
    end
  end

  context "Marriage in Albania, living in the UK, partner British, opposite sex" do
    setup do
      worldwide_api_has_organisations_for_location('albania', read_fixture_file('worldwide/albania_organisations.json'))
      add_response 'albania'
      add_response 'uk'
      add_response 'partner_british'
      add_response 'opposite_sex'
    end
    should "show outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_uk_or_ceremony_country" do
      assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_uk_or_ceremony_country
    end
  end

  #Marriage that requires a 7 day notice to be given
  context "Marriage in Canada, living elsewhere" do
    setup do
      worldwide_api_has_organisations_for_location('canada', read_fixture_file('worldwide/canada_organisations.json'))
      add_response 'canada'
      add_response 'third_country'
      add_response 'partner_british'
      add_response 'opposite_sex'
    end
    should "show 7 day notice" do
      assert_current_node :outcome_opposite_sex_marriage_in_commonwealth_countries
    end
  end

  context "Marriage in Rwanda, living elsewhere" do
    setup do
      worldwide_api_has_organisations_for_location('rwanda', read_fixture_file('worldwide/rwanda_organisations.json'))
      add_response 'rwanda'
      add_response 'third_country'
      add_response 'partner_british'
      add_response 'opposite_sex'
    end
    should "show 7 day notice" do
      assert_current_node :outcome_opposite_sex_in_no_cni_countries_when_residing_in_ceremony_or_third_country
    end
  end

  context "same sex marriage in San Marino is not allowed" do
    setup do
      worldwide_api_has_organisations_for_location('san-marino', read_fixture_file('worldwide/san-marino_organisations.json'))
      add_response 'san-marino'
      add_response 'uk'
      add_response 'partner_british'
      add_response 'same_sex'
    end
    should "do not allow marriage" do
      assert_current_node :outcome_same_sex_marriage_and_civil_partnership_not_possible
    end
  end

  context "same sex marriage in Malta" do
    setup do
      worldwide_api_has_organisations_for_location('malta', read_fixture_file('worldwide/malta_organisations.json'))
      add_response 'malta'
      add_response 'uk'
      add_response 'partner_british'
      add_response 'same_sex'
    end
    should "do not allow marriage" do
      assert_current_node :outcome_same_sex_marriage_and_civil_partnership_in_malta
    end
  end

  context "opposite sex marriage in Malta" do
    setup do
      worldwide_api_has_organisations_for_location('malta', read_fixture_file('worldwide/malta_organisations.json'))
      add_response 'malta'
      add_response 'uk'
      add_response 'partner_british'
      add_response 'opposite_sex'
    end
    should "do not allow marriage" do
      assert_current_node :outcome_opposite_sex_marriage_in_commonwealth_countries
    end
  end

  context "opposite sex marriage in Brazil with local partner" do
    setup do
      worldwide_api_has_organisations_for_location('brazil', read_fixture_file('worldwide/brazil_organisations.json'))
      add_response 'brazil'
    end

    should "divert to the correct download link for the Affidavit for Marriage document when in a third country" do
      add_response 'third_country'
      add_response 'partner_local'
      add_response 'opposite_sex'
      assert_current_node :outcome_marriage_in_brazil_when_residing_in_brazil_or_third_country
    end

    should "suggest to swear affidavit in front of notary public when in ceremony country" do
      add_response 'ceremony_country'
      add_response 'partner_local'
      add_response 'opposite_sex'
      assert_current_node :outcome_marriage_in_brazil_when_residing_in_brazil_or_third_country
    end
  end

  context "ceremony in Greece" do
    setup do
      worldwide_api_has_organisations_for_location('greece', read_fixture_file('worldwide/greece_organisations.json'))
      add_response 'greece'
    end

    context "lives in 3rd country, all opposite-sex outcomes" do
      setup do
        add_response 'third_country'
        add_response 'partner_other'
        add_response 'opposite_sex'
      end

      should "leads to outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_third_country" do
        assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_third_country
      end
    end

    context "resident in Greece, all opposite-sex outcomes" do
      setup do
        add_response 'ceremony_country'
        add_response 'partner_other'
        add_response 'opposite_sex'
      end
      should "lead to outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_uk_or_ceremony_country with Greece-specific appoitnment link and document requirements" do
        assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_uk_or_ceremony_country
      end
    end
  end

  context "ceremony in Uzbekistan, resident in the UK, partner from anywhere, opposite sex" do
    setup do
      worldwide_api_has_organisations_for_location('uzbekistan', read_fixture_file('worldwide/uzbekistan_organisations.json'))
      add_response 'uzbekistan'
      add_response 'uk'
      add_response 'partner_other'
      add_response 'opposite_sex'
    end
    should "not include the links to download documents" do
      assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_uk_or_ceremony_country
    end
  end

  context "ceremony in Laos" do
    setup do
      worldwide_api_has_organisations_for_location('laos', read_fixture_file('worldwide/laos_organisations.json'))
      add_response 'laos'
    end

    context "resident in the UK, opposite sex partner from Laos" do
      setup do
        add_response 'uk'
        add_response 'partner_local'
        add_response 'opposite_sex'
      end
      should "lead to outcome_opposite_sex_marriage_in_laos_with_lao_national" do
        assert_current_node :outcome_opposite_sex_marriage_in_laos_with_lao_national
      end
    end

    context "resident in 3rd country, opposite sex partner from Laos" do
      setup do
        add_response 'third_country'
        add_response 'partner_local'
        add_response 'opposite_sex'
      end
      should "lead to outcome_opposite_sex_marriage_in_laos_with_lao_national" do
        assert_current_node :outcome_opposite_sex_marriage_in_laos_with_lao_national
      end
    end

    context "resident in Laos, opposite sex partner from Laos" do
      setup do
        add_response 'ceremony_country'
        add_response 'partner_local'
        add_response 'opposite_sex'
      end
      should "lead to outcome_opposite_sex_marriage_in_laos_with_lao_national" do
        assert_current_node :outcome_opposite_sex_marriage_in_laos_with_lao_national
      end
    end

    context "opposite sex partner, no Laos nationals" do
      setup do
        add_response 'uk'
        add_response 'partner_other'
        add_response 'opposite_sex'
      end
      should "lead to outcome_opposite_sex_marriage_in_laos_without_lao_national" do
        assert_current_node :outcome_opposite_sex_marriage_in_laos_without_lao_national
      end
    end
  end

  context "Albania" do
    should "allow same sex marriage and civil partnership conversion to marriage, has custom appointment booking link" do
      worldwide_api_has_organisations_for_location('albania', read_fixture_file('worldwide/albania_organisations.json'))
      add_response 'albania'
      add_response 'ceremony_country'
      add_response 'partner_local'
      add_response 'same_sex'

      assert_current_node :outcome_same_sex_marriage_and_civil_partnership
    end
  end

  context "Costa Rica" do
    should "indicate that same sex marriage or civil partnership is not recognised anymore" do
      worldwide_api_has_organisations_for_location('costa-rica', read_fixture_file('worldwide/costa-rica_organisations.json'))
      add_response 'costa-rica'
      add_response 'ceremony_country'
      add_response 'partner_local'
      add_response 'same_sex'

      assert_current_node :outcome_same_sex_marriage_and_civil_partnership_in_other_countries
    end
  end

  context "Kosovo" do
    setup do
      worldwide_api_has_organisations_for_location('kosovo', read_fixture_file('worldwide/kosovo_organisations.json'))
      add_response 'kosovo'
    end

    should "lead to outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_third_country if in third country" do
      add_response 'third_country'
      add_response 'partner_local'
      add_response 'opposite_sex'

      assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_third_country
    end

    should "lead to a :outcome_opposite_sex_marriage_in_kosovo_when_residing_in_uk_or_kosovo outcome for uk, partner_local and opposite_sex" do
      add_response 'uk'
      add_response 'partner_local'
      add_response 'opposite_sex'

      assert_current_node :outcome_opposite_sex_marriage_in_kosovo_when_residing_in_uk_or_kosovo
    end

    should "lead to a :outcome_opposite_sex_marriage_in_kosovo_when_residing_in_uk_or_kosovo outcome for ceremony_country, partner_local and opposite_sex" do
      add_response 'ceremony_country'
      add_response 'partner_local'
      add_response 'opposite_sex'

      assert_current_node :outcome_opposite_sex_marriage_in_kosovo_when_residing_in_uk_or_kosovo
    end
  end

  context "Montenegro" do
    setup do
      worldwide_api_has_organisations_for_location('montenegro', read_fixture_file('worldwide/montenegro_organisations.json'))
      add_response 'montenegro'
      add_response 'ceremony_country'
    end

    should "lead to outcome_same_sex_marriage_and_civil_partnership when both partners are same sex british" do
      add_response 'partner_british'
      add_response 'same_sex'
      assert_current_node :outcome_same_sex_marriage_and_civil_partnership
    end

    should "lead to outcome_same_sex_marriage_and_civil_partnership_not_possible when both partners are same sex not british" do
      add_response 'partner_local'
      add_response 'same_sex'
      assert_current_node :outcome_same_sex_marriage_and_civil_partnership_not_possible
    end
  end

  context "Saint-Barthélemy" do
    setup do
      worldwide_api_has_no_organisations_for_location('st-martin')
      worldwide_api_has_no_organisations_for_location('saint-barthelemy')
      add_response 'saint-barthelemy'
      add_response 'third_country'
      add_response 'partner_british'
    end

    should "suggest to contact local authorities even if the user is in third country for OS (because they don't have many embassies)" do
      add_response 'opposite_sex'

      assert_current_node :outcome_opposite_sex_in_no_cni_countries_when_residing_in_ceremony_or_third_country
    end

    should "suggest to contact local authorities even if the user is in third country for SS (because they don't have many embassies)" do
      add_response 'same_sex'

      assert_current_node :outcome_opposite_sex_in_no_cni_countries_when_residing_in_ceremony_or_third_country
    end
  end

  context "St Martin" do
    setup do
      worldwide_api_has_no_organisations_for_location('st-martin')
      worldwide_api_has_no_organisations_for_location('saint-barthelemy')
      add_response 'st-martin'
      add_response 'third_country'
      add_response 'partner_british'
    end

    should "suggest to contact local authorities even if the user is in third country for OS (because they don't have many embassies)" do
      add_response 'opposite_sex'

      assert_current_node :outcome_opposite_sex_in_no_cni_countries_when_residing_in_ceremony_or_third_country
    end

    should "suggest to contact local authorities even if the user is in third country for SS (because they don't have many embassies)" do
      add_response 'same_sex'

      assert_current_node :outcome_opposite_sex_in_no_cni_countries_when_residing_in_ceremony_or_third_country
    end
  end

  context "Macao" do
    should "lead to an affirmation outcome for opposite sex marriages directing users to Hong Kong" do
      worldwide_api_has_no_organisations_for_location('macao')
      add_response 'macao'
      add_response 'ceremony_country'
      add_response 'partner_british'
      add_response 'opposite_sex'

      assert_current_node :outcome_opposite_sex_marriage_in_affirmation_countries
    end

    should "lead to an affirmation outcome for opposite sex marriages directing users to Hong Kong with an intro about residency" do
      worldwide_api_has_no_organisations_for_location('macao')
      add_response 'macao'
      add_response 'third_country'
      add_response 'partner_british'
      add_response 'opposite_sex'

      assert_current_node :outcome_opposite_sex_marriage_in_affirmation_countries
    end
  end

  context "Hong Kong" do
    should "lead to the custom outcome directing users to the local Immigration Department for opposite sex marriages" do
      worldwide_api_has_no_organisations_for_location('hong-kong')
      add_response 'hong-kong'
      add_response 'ceremony_country'
      add_response 'partner_british'
      add_response 'opposite_sex'

      assert_current_node :outcome_opposite_sex_marriage_in_hong_kong
    end
  end

  context "Norway" do
    setup do
      worldwide_api_has_organisations_for_location('norway', read_fixture_file('worldwide/norway_organisations.json'))
      add_response 'norway'
    end

    should "lead to the affirmation outcome when in Norway" do
      add_response 'ceremony_country'
      add_response 'partner_british'
      add_response 'opposite_sex'
      assert_current_node :outcome_opposite_sex_marriage_in_affirmation_countries
    end

    should "lead to the CNI outcome for opposite sex marriages for UK residents" do
      add_response 'uk'
      add_response 'partner_british'
      add_response 'opposite_sex'
      assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_uk_or_ceremony_country
    end

    should "lead to a custom CNI third country outcome when in a thiord country" do
      add_response 'third_country'
      add_response 'partner_british'
      add_response 'opposite_sex'
      assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_third_country
    end

    should "lead to SS affirmation outcome" do
      add_response 'ceremony_country'
      add_response 'partner_british'
      add_response 'same_sex'

      assert_current_node :outcome_same_sex_civil_partnership_in_affirmation_countries
    end
  end

  context "Seychelles" do
    should "lead to outcome_same_sex_marriage_and_civil_partnership for same sex marriages" do
      worldwide_api_has_organisations_for_location('seychelles', read_fixture_file('worldwide/seychelles_organisations.json'))
      add_response 'seychelles'
      add_response 'ceremony_country'
      add_response 'partner_local'
      add_response 'same_sex'
      assert_current_node :outcome_same_sex_marriage_and_civil_partnership_not_possible
    end
  end

  context "Kyrgyzstan" do
    should "lead to the CNI outcome with a suggestion to post notice in Almaty, Kazakhstan" do
      worldwide_api_has_no_organisations_for_location('kyrgyzstan')
      add_response 'kyrgyzstan'
      add_response 'ceremony_country'
      add_response 'partner_british'
      add_response 'opposite_sex'
      assert_current_node :outcome_opposite_sex_marriage_in_consular_cni_countries_when_residing_in_uk_or_ceremony_country
    end
  end
end
