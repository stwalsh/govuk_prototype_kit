module SmartAnswer
  class AdditionalCommodityCodeFlow < Flow
    def define
      content_id "bfda3b4f-166b-48e7-9aaf-21bfbd606207"
      name 'additional-commodity-code'

      status :published
      satisfies_need "100233"

      # Q1
      multiple_choice :how_much_starch_glucose? do
        option 0
        option 5
        option 25
        option 50
        option 75

        save_input_as :starch_glucose_weight

        calculate :milk_protein_weight do
          nil
        end

        next_node do |response|
          case response.to_i
          when 25
            question :how_much_sucrose_2?
          when 50
            question :how_much_sucrose_3?
          when 75
            question :how_much_sucrose_4?
          else
            question :how_much_sucrose_1?
          end
        end
      end

      # Q2ab
      multiple_choice :how_much_sucrose_1? do
        option 0
        option 5
        option 30
        option 50
        option 70

        save_input_as :sucrose_weight
        next_node do
          question :how_much_milk_fat?
        end
      end

      # Q2c
      multiple_choice :how_much_sucrose_2? do
        option 0
        option 5
        option 30
        option 50

        save_input_as :sucrose_weight
        next_node do
          question :how_much_milk_fat?
        end
      end

      # Q2d
      multiple_choice :how_much_sucrose_3? do
        option 0
        option 5
        option 30

        save_input_as :sucrose_weight
        next_node do
          question :how_much_milk_fat?
        end
      end

      # Q2e
      multiple_choice :how_much_sucrose_4? do
        option 0
        option 5

        save_input_as :sucrose_weight
        next_node do
          question :how_much_milk_fat?
        end
      end

      # Q3
      multiple_choice :how_much_milk_fat? do
        option 0
        option 1
        option 3
        option 6
        option 9
        option 12
        option 18
        option 26
        option 40
        option 55
        option 70
        option 85

        save_input_as :milk_fat_weight

        next_node do |response|
          case response.to_i
          when 0, 1
            question :how_much_milk_protein_ab?
          when 3
            question :how_much_milk_protein_c?
          when 6
            question :how_much_milk_protein_d?
          when 9, 12
            question :how_much_milk_protein_ef?
          when 18, 26
            question :how_much_milk_protein_gh?
          else
            outcome :commodity_code_result
          end
        end
      end

      # Q3ab
      multiple_choice :how_much_milk_protein_ab? do
        option 0
        option 2
        option 6
        option 18
        option 30
        option 60

        save_input_as :milk_protein_weight

        next_node do
          outcome :commodity_code_result
        end
      end

      # Q3c
      multiple_choice :how_much_milk_protein_c? do
        option 0
        option 2
        option 12

        save_input_as :milk_protein_weight

        next_node do
          outcome :commodity_code_result
        end
      end

      # Q3d
      multiple_choice :how_much_milk_protein_d? do
        option 0
        option 4
        option 15

        save_input_as :milk_protein_weight

        next_node do
          outcome :commodity_code_result
        end
      end

      # Q3ef
      multiple_choice :how_much_milk_protein_ef? do
        option 0
        option 6
        option 18

        save_input_as :milk_protein_weight

        next_node do
          outcome :commodity_code_result
        end
      end

      # Q3gh
      multiple_choice :how_much_milk_protein_gh? do
        option 0
        option 6

        save_input_as :milk_protein_weight

        next_node do
          outcome :commodity_code_result
        end
      end

      outcome :commodity_code_result do
        precalculate :calculator do
          Calculators::CommodityCodeCalculator.new(
            starch_glucose_weight: starch_glucose_weight,
            sucrose_weight: sucrose_weight,
            milk_fat_weight: milk_fat_weight,
            milk_protein_weight: milk_protein_weight)
        end
      end
    end
  end
end
