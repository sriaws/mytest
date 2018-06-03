Jekyll::Hooks.register :site, :post_read do |site|
  locale = site.active_lang
  default_locale = site.default_lang

  site.pages.each do |page|
    page.data = translate_data(page.data, locale, default_locale)
  end
end
