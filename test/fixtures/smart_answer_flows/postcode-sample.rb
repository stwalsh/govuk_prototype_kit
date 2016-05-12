module SmartAnswer
  class PostcodeSampleFlow < Flow
    def define
      name "postcode-sample"
      status :draft

      postcode_question :user_input? do
        save_input_as :user_input

        next_node do
          outcome :outcome
        end
      end

      outcome :outcome
    end
  end
end
