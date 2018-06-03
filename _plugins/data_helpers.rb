def translate_data(content, locale, default_locale)
  map_content(content) do |key, value|
    if key.end_with?('_localized') && value.is_a?(Hash)
      [key.gsub('_localized', ''), value[locale] || value[default_locale]]
    end
  end
end

def assign_associations(content)
  map_content(content) do |key, value|
    if key.end_with?('_id') && value.is_a?(Fixnum)
      k = key.gsub('_id', '')
      obj = content[k + 's'].detect{|item| value == (item.kind_of?(Array) ? item.last['id'] || item.first : item['id']) }
      [k, content[k + 's'].kind_of?(Hash) && !obj.nil? ? obj.last : obj]
    end
  end
end

def map_content(content, &block)
  case content
  when Hash
    {}.tap do |h|
      content.each do |key, value|
        k, v = yield(key, value)

        if k.nil? & v.nil?
          h[key] = map_content(value, &block)
        else
          h[k] = v
          h[key] = value # leave original values
        end
      end
    end
  when Array
    content.map{|value| map_content(value, &block) }
  else
    content
  end
end

module Jekyll
  module ValuesFilter
    def values(input)
      case
        when input.instance_of?(Hash)
          input.values
        else
          input
      end
    end
  end
end

Liquid::Template.register_filter(Jekyll::ValuesFilter)
