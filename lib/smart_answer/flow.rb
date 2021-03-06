require 'ostruct'

module SmartAnswer
  class Flow
    attr_reader :nodes
    attr_accessor :status, :need_id

    def self.build
      flow = new
      flow.define
      flow
    end

    def initialize(&block)
      @nodes = []
      instance_eval(&block) if block_given?
    end

    def append(flow)
      flow.nodes.each do |node|
        node.flow = self
        add_node(node)
      end
    end

    def content_id(cid = nil)
      @content_id = cid unless cid.nil?
      @content_id
    end

    def name(name = nil)
      @name = name unless name.nil?
      @name
    end

    def satisfies_need(need_id)
      self.need_id = need_id
    end

    def draft?
      status == :draft
    end

    def status(s = nil)
      if s
        raise Flow::InvalidStatus unless [:published, :draft].include? s
        @status = s
      end

      @status
    end

    def multiple_choice(name, &block)
      add_node Question::MultipleChoice.new(self, name, &block)
    end

    def country_select(name, options = {}, &block)
      add_node Question::CountrySelect.new(self, name, options, &block)
    end

    def date_question(name, &block)
      add_node Question::Date.new(self, name, &block)
    end

    def value_question(name, options = {}, &block)
      add_node Question::Value.new(self, name, options, &block)
    end

    def money_question(name, &block)
      add_node Question::Money.new(self, name, &block)
    end

    def salary_question(name, &block)
      add_node Question::Salary.new(self, name, &block)
    end

    def checkbox_question(name, &block)
      add_node Question::Checkbox.new(self, name, &block)
    end

    def postcode_question(name, &block)
      add_node Question::Postcode.new(self, name, &block)
    end

    def outcome(name, &block)
      add_node Outcome.new(self, name, &block)
    end

    def outcomes
      @nodes.select(&:outcome?)
    end

    def questions
      @nodes.select(&:question?)
    end

    def node_exists?(node_or_name)
      @nodes.any? { |n| n.name == node_or_name.to_sym }
    end

    def node(node_or_name)
      @nodes.find { |n| n.name == node_or_name.to_sym } || raise("Node '#{node_or_name}' does not exist")
    end

    def start_state
      State.new(questions.first.name).freeze
    end

    def process(responses)
      responses.inject(start_state) do |state, response|
        return state if state.error
        begin
          state = node(state.current_node).transition(state, response)
          node(state.current_node).evaluate_precalculations(state)
        rescue InvalidResponse => e
          state.dup.tap do |new_state|
            new_state.error = e.message
            new_state.freeze
          end
        end
      end
    end

    def path(responses)
      process(responses).path
    end

    def normalize_responses(responses)
      process(responses).responses
    end

    class InvalidStatus < StandardError; end

  private

    def add_node(node)
      raise "Node #{node.name} already defined" if node_exists?(node)
      @nodes << node
    end
  end
end
