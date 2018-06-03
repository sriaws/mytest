require 'json'

module Jekyll
  class DataReader
    alias_method :read_orig, :read

    def read(dir)
      read_orig(dir)
      @locale = @site.active_lang
      @default_locale = @site.default_lang

      @content = assign_associations(translate_data(@content, @locale, @default_locale))
    end
  end
end

