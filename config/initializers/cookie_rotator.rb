# frozen_string_literal: true

# load_defaults 7.0 derives cookie secrets with SHA256 instead of SHA1: keep
# reading (and re-writing) cookies issued before the upgrade, so sessions survive.
# Can be removed once every session issued before the upgrade has expired.
Rails.application.config.after_initialize do
  Rails.application.config.action_dispatch.cookies_rotations.tap do |cookies|
    config = Rails.application.config.action_dispatch
    key_generator = ActiveSupport::KeyGenerator.new(
      Rails.application.secret_key_base, iterations: 1000, hash_digest_class: OpenSSL::Digest::SHA1
    )
    key_len = ActiveSupport::MessageEncryptor.key_len

    cookies.rotate :encrypted, key_generator.generate_key(config.authenticated_encrypted_cookie_salt, key_len)
    cookies.rotate :signed, key_generator.generate_key(config.signed_cookie_salt)
  end
end
