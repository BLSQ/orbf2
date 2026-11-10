# frozen_string_literal: true

require "rails_helper"

RSpec.describe "cookies issued before the rails 7.0 defaults" do
  def legacy_cookie(name, value)
    config = Rails.application.config.action_dispatch
    key_generator = ActiveSupport::KeyGenerator.new(
      Rails.application.secret_key_base, iterations: 1000, hash_digest_class: OpenSSL::Digest::SHA1
    )
    secret = key_generator.generate_key(config.authenticated_encrypted_cookie_salt, ActiveSupport::MessageEncryptor.key_len)
    # as written by rails < 7.1 (load_defaults 6.0 here): SHA1 derived key, legacy metadata envelope
    ActiveSupport::MessageEncryptor.new(secret, cipher: "aes-256-gcm", serializer: JSON,
                                                force_legacy_metadata_serializer: true)
                                   .encrypt_and_sign(value, purpose: "cookie.#{name}")
  end

  def cookie_jar_with(cookies)
    request = ActionDispatch::TestRequest.create(Rails.application.env_config)
    cookies.each { |name, value| request.cookie_jar[name] = value }
    request.cookie_jar
  end

  it "uses the SHA256 key generator (load_defaults 7.0)" do
    expect(Rails.application.config.active_support.key_generator_hash_digest_class).to eq(OpenSSL::Digest::SHA256)
  end

  it "still reads encrypted cookies (session) issued with the SHA1 key generator" do
    jar = cookie_jar_with("_scorpio_session" => legacy_cookie("_scorpio_session", "user_id" => 42))
    expect(jar.encrypted["_scorpio_session"]).to eq("user_id" => 42)
  end
end
