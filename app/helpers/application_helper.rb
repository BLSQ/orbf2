module ApplicationHelper
  def d_to_s(decimal)
    return format("%.2f", decimal) if decimal.is_a? Numeric
    decimal.to_s
  end

  # Renders a font-awesome icon, usage:
  #       style - one of 'fas', 'far', 'fab'
  #       name - name of the icon (without the prefix 'fa-')
  #       text - Either a string or a hash with html options
  #       html_options - Only used when text is not a hash
  #
  #      icon("fas", "home")
  #      => '<i class"fa fa-home"></i>
  def icon(style, name, text = nil, html_options = {})
    # Our own, personal, icon helper. This is relying on
    # `font-awesome-rails` to include all the assets for font-awesome
    # to work. It's mimicking the API of the `font-awesome-sass` gem,
    # which uses font-awesome version 5 but we can't use it because of
    # a sass naming clash.
    #
    # So in the ideal world, rails_admin drops the font-awesome-rails
    # dependency and we migrate to font-awesome-sass (if we do: search
    # for 'fa5' in the codebase to fix some icons in the JS).
    #
    # At the moment we can't use them both, because the line:
    #      @import "font-awesome"
    #
    # Will import the stylesheet of the `font-awesome-rails` gem
    # instead of the `font-awesome-sass` gem, so we're back to using
    # `font-awesome` version 4.
    #
    # That's why this helper is there, it uses the API of
    # `font-awesome-sass` but transforms it into version 4 of
    # `font-awesome`.
    text, html_options = nil, text if text.is_a?(Hash)

    # Font awesome 4 only has 'fa', so while the views pretend to use version 5,
    # we're just using version 4.
    style = 'fa'
    name.gsub!("trash-alt", "trash")
    content_class = "#{style} fa-#{name}"
    content_class << " #{html_options[:class]}" if html_options.key?(:class)
    html_options[:class] = content_class

    html = content_tag(:i, nil, html_options)
    html << ' ' << text.to_s unless text.blank?
    html
  end
end
