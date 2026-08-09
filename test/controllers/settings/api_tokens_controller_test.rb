require "test_helper"

class Settings::ApiTokensControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "index requires authentication" do
    sign_out

    get settings_api_tokens_path
    assert_redirected_to new_session_path
  end

  test "index shows an empty state before any token exists" do
    get settings_api_tokens_path

    assert_response :success
    assert_select "h2", text: "No API tokens yet"
  end

  test "index lists tokens by preview, never the full value" do
    token = users(:one).api_tokens.create!(name: "CI")
    plaintext = token.token

    get settings_api_tokens_path

    assert_select "td", text: token.preview
    assert_no_match plaintext, response.body
  end

  test "create reveals the token exactly once" do
    assert_difference -> { ApiToken.count }, 1 do
      post settings_api_tokens_path, params: { api_token: { name: "CI" } }
    end

    follow_redirect!
    revealed = ApiToken.order(:created_at).last

    assert_select "code", text: /\A#{ApiToken.prefix}_/
    assert_select "p", text: /only time the token is shown/

    get settings_api_tokens_path
    assert_select "code", count: 0
    assert_not_nil revealed
  end

  test "create without a name is rejected" do
    assert_no_difference -> { ApiToken.count } do
      post settings_api_tokens_path, params: { api_token: { name: "" } }
    end

    assert_response :unprocessable_content
  end

  test "rotate replaces the token and reveals the new one" do
    token = users(:one).api_tokens.create!(name: "CI")
    original_digest = token.token_digest

    post settings_api_token_rotation_path(token)

    assert_not_equal original_digest, token.reload.token_digest
    follow_redirect!
    assert_select "code", text: /\A#{ApiToken.prefix}_/
  end

  test "a token can be deactivated and activated again" do
    token = users(:one).api_tokens.create!(name: "CI")

    patch settings_api_token_path(token), params: { api_token: { active: false } }
    assert_not token.reload.active?

    patch settings_api_token_path(token), params: { api_token: { active: true } }
    assert token.reload.active?
  end

  test "destroy removes the token" do
    token = users(:one).api_tokens.create!(name: "CI")

    assert_difference -> { ApiToken.count }, -1 do
      delete settings_api_token_path(token)
    end
  end

  test "another user's token is not reachable" do
    token = users(:two).api_tokens.create!(name: "Theirs")

    delete settings_api_token_path(token)
    assert_redirected_to root_path

    post settings_api_token_rotation_path(token)
    assert_redirected_to root_path

    assert ApiToken.exists?(token.id)
  end

  test "tokens can be searched by name" do
    users(:one).api_tokens.create!(name: "CI pipeline")
    users(:one).api_tokens.create!(name: "Reporting job")

    get settings_api_tokens_path(q: { name_cont: "pipeline" })

    assert_select "td", text: "CI pipeline"
    assert_select "td", text: "Reporting job", count: 0
  end

  test "settings appears in the sidebar" do
    get root_path

    assert_select "a[href=?]", settings_api_tokens_path, text: /Settings/
  end
end
