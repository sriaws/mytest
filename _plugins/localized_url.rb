Jekyll::Hooks.register :site, :post_read do |site|
  site.languages.each do |locale|
    Jekyll::Page::ATTRIBUTES_FOR_LIQUID << "url_#{locale}"
  end
end

module Jekyll
  class Page
    alias_method :url_orig, :url
    def url(locale = nil)
      return url_orig if locale.nil?

      u = URL.new({
        template: template,
        placeholders: url_placeholders,
        permalink: (data['permalink_localized'] && data['permalink_localized'][locale])
      }).to_s
      u = '/' + locale + u unless locale == site.default_lang

      u
    end

    def method_missing(name, *arguments, &block)
      if name.to_s =~ /url_(#{site.languages.join('|')})/
        url($1)
      else
        super
      end
    end

    def respond_to_missing?(name, include_private = false)
      name.to_s =~ /url_(#{site.languages.join('|')})/ || super
    end
  end

  module LocalizedPageUrlFilter
    def url(page, language = nil)
      key = 'url' + (language.nil? ? '' : "_#{language}" )
      if page.key? key
        page[key]
      else
        "Error: invalid parameters, there is no '#{key}' property!"
      end
    end
  end
end

Liquid::Template.register_filter(Jekyll::LocalizedPageUrlFilter)
