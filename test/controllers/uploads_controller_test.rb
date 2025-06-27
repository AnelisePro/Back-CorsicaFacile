require "test_helper"

class UploadsControllerTest < ActionDispatch::IntegrationTest
  test "should get presigned_url" do
    get uploads_presigned_url_url
    assert_response :success
  end
end
