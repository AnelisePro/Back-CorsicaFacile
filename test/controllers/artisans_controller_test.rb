require "test_helper"

class ArtisansControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get artisans_index_url
    assert_response :success
  end
end
