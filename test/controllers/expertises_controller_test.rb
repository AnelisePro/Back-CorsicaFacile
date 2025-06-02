require "test_helper"

class ExpertisesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get expertises_index_url
    assert_response :success
  end
end
