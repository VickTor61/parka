require "test_helper"

class ApiTokenTest < ActiveSupport::TestCase
  setup { @user = users(:one) }

  test "a new token exposes its plaintext once and stores only a digest" do
    token = @user.api_tokens.create!(name: "CI")

    assert token.token.start_with?("#{ApiToken.prefix}_")
    assert_not_equal token.token, token.token_digest
    assert_equal ApiToken.digest(token.token), token.token_digest
  end

  test "the prefix marks non-production tokens as test keys" do
    assert_equal ApiToken::TEST_PREFIX, ApiToken.prefix
    assert @user.api_tokens.create!(name: "CI").token.start_with?("sk_test_")
  end

  test "production issues live keys" do
    assert_equal ApiToken::LIVE_PREFIX, ApiToken.prefix(ActiveSupport::StringInquirer.new("production"))
    assert_equal ApiToken::TEST_PREFIX, ApiToken.prefix(ActiveSupport::StringInquirer.new("development"))
  end

  test "a token issued under an older prefix still authenticates" do
    legacy = @user.api_tokens.new(name: "Legacy")
    plaintext = "parka_#{SecureRandom.urlsafe_base64(32)}"
    legacy.token_digest = ApiToken.digest(plaintext)
    legacy.token_prefix = plaintext.first(ApiToken::PREVIEW_LENGTH)
    legacy.save!(validate: false)

    assert_equal legacy, ApiToken.authenticate(plaintext)
  end

  test "the plaintext is gone once the record is reloaded" do
    token = @user.api_tokens.create!(name: "CI")

    assert_nil ApiToken.find(token.id).token
  end

  test "authenticate finds the owner of a valid token" do
    token = @user.api_tokens.create!(name: "CI")

    assert_equal token, ApiToken.authenticate(token.token)
  end

  test "authenticate rejects an unknown or blank token" do
    assert_nil ApiToken.authenticate("parka_nope")
    assert_nil ApiToken.authenticate("")
    assert_nil ApiToken.authenticate(nil)
  end

  test "authenticate rejects a deactivated token" do
    token = @user.api_tokens.create!(name: "CI")
    plaintext = token.token
    token.update!(active: false)

    assert_nil ApiToken.authenticate(plaintext)
  end

  test "rotating invalidates the previous value" do
    token = @user.api_tokens.create!(name: "CI")
    original = token.token

    token.rotate!

    assert_nil ApiToken.authenticate(original)
    assert_equal token, ApiToken.authenticate(token.token)
  end

  test "a name is required" do
    token = @user.api_tokens.new

    assert_not token.valid?
    assert_includes token.errors[:name], "can't be blank"
  end

  test "the preview masks everything after the prefix" do
    token = @user.api_tokens.create!(name: "CI")

    assert token.preview.start_with?(token.token.first(ApiToken::PREVIEW_LENGTH))
    assert_not token.preview.include?(token.token.last(10))
  end

  test "tokens go away with their user" do
    @user.api_tokens.create!(name: "CI")

    assert_difference -> { ApiToken.count }, -1 do
      @user.destroy
    end
  end
end
