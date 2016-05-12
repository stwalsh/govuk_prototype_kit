module CurrentQuestionHelper
  def calculate_current_question_path(presenter)
    attrs = params.slice(:id, :started).symbolize_keys
    attrs[:responses] = presenter.accepted_responses if presenter.accepted_responses.any?
    smart_answer_path(attrs)
  end

  def prefill_value_is?(value)
    if params[:previous_response]
      params[:previous_response] == value
    elsif params[:response]
      params[:response] == value
    end
  end

  def prefill_value_includes?(question, value)
    if params[:previous_response]
      question.to_response(params[:previous_response]).include?(value)
    elsif params[:response]
      params[:response].include?(value)
    end
  end

  def default_for_date(value)
    value.blank? ? nil : value.to_i
  end

  def prefill_value_for(question, attribute = nil)
    if params[:previous_response]
      response = question.to_response(params[:previous_response])
    elsif params[:response]
      response = params[:response]
    end
    if !response.blank? && attribute
      begin
        response[attribute]
      rescue TypeError
        response
      end
    else
      response
    end
  end
end
