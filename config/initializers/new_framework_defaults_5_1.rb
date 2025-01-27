# frozen_string_literal: true

# Be sure to restart your server when you modify this file.
#
# This file contains migration options to ease your Rails 5.1 upgrade.
#
# Once upgraded flip defaults one by one to migrate to the new default.
#
# Read the Guide for Upgrading Ruby on Rails for more info on each option.

# Make `form_with` generate non-remote forms.
# Default used to be false
Rails.application.config.action_view.form_with_generates_remote_forms = true

# Unknown asset fallback will return the path passed in when the given
# asset is not present in the asset pipeline.
# Default used to be false
Rails.application.config.assets.unknown_asset_fallback = true
