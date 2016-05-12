require 'test_helper'

class PanopticonRegistererTest < ActiveSupport::TestCase
  test 'sending item to panopticon' do
    request = stub_request(:put, %r[http://panopticon.dev.gov.uk/])
    flow_presenters = [OpenStruct.new, OpenStruct.new]

    silence_logging do
      PanopticonRegisterer.new(flow_presenters).register
    end

    assert_requested(request, times: 2)
  end

  test 'sending correct data to panopticon' do
    stub_request(:put, "http://panopticon.dev.gov.uk/artefacts/a-smart-answer.json")

    registerable = OpenStruct.new(
      slug: 'a-smart-answer',
      title: 'The Smart Answer.',
      content_id: 'be9adf07-ce73-468e-be81-31716b4492f2',
    )

    silence_logging do
      PanopticonRegisterer.new([registerable]).register
    end

    assert_requested(
      :put,
      "http://panopticon.dev.gov.uk/artefacts/a-smart-answer.json",
      body: {
        slug: "a-smart-answer",
        content_id: 'be9adf07-ce73-468e-be81-31716b4492f2',
        owning_app: "smartanswers",
        kind: "smart-answer",
        name: "The Smart Answer.",
        description: nil,
        state: nil,
      }
    )
  end

private

  # The registerer is quite noisy.
  def silence_logging
    silence_stream $stdout do
      yield
    end
  end
end
