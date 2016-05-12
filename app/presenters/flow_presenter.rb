require 'node_presenter'

class FlowPresenter
  extend Forwardable
  include Rails.application.routes.url_helpers

  attr_reader :request, :params, :flow

  def_delegators :@flow, :need_id

  def initialize(request, flow)
    @request = request
    @params = request.params
    @flow = flow
    @node_presenters = {}
  end

  def artefact
    @artefact ||= Services.content_api.artefact(@flow.name.to_s)
  rescue GdsApi::HTTPErrorResponse
    {}
  end

  def title
    start_node.title
  end

  def started?
    params.has_key?(:started)
  end

  def finished?
    current_node.outcome?
  end

  def render_txt?
    finished? || !started?
  end

  def current_state
    @current_state ||= @flow.process(all_responses)
  end

  def collapsed_questions
    @flow.path(all_responses).map do |name|
      presenter_for(@flow.node(name))
    end
  end

  def presenter_for(node)
    presenter_class = case node
                      when SmartAnswer::Question::Date
                        DateQuestionPresenter
                      when SmartAnswer::Question::CountrySelect
                        CountrySelectQuestionPresenter
                      when SmartAnswer::Question::MultipleChoice
                        MultipleChoiceQuestionPresenter
                      when SmartAnswer::Question::Checkbox
                        CheckboxQuestionPresenter
                      when SmartAnswer::Question::Value
                        ValueQuestionPresenter
                      when SmartAnswer::Question::Money
                        MoneyQuestionPresenter
                      when SmartAnswer::Question::Salary
                        SalaryQuestionPresenter
                      when SmartAnswer::Question::Base
                        QuestionPresenter
                      when SmartAnswer::Outcome
                        OutcomePresenter
                      else
                        NodePresenter
                      end
    @node_presenters[node.name] ||= presenter_class.new(node, current_state)
  end

  def current_question_number
    current_state.path.size + 1
  end

  def current_node
    presenter_for(@flow.node(current_state.current_node))
  end

  def start_node
    node = SmartAnswer::Node.new(@flow, @flow.name.underscore.to_sym)
    @start_node ||= StartNodePresenter.new(node)
  end

  def change_collapsed_question_link(question_number)
    smart_answer_path(
      id: @params[:id],
      started: 'y',
      responses: accepted_responses[0...question_number - 1],
      previous_response: accepted_responses[question_number - 1]
    )
  end

  def normalize_responses_param
    case params[:responses]
    when NilClass
      []
    when Array
      params[:responses]
    else
      params[:responses].to_s.split('/')
    end
  end

  def accepted_responses
    @current_state.responses
  end

  def all_responses
    normalize_responses_param.dup.tap do |responses|
      responses << params[:response] if params[:next]
    end
  end
end
