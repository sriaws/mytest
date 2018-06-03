# Jekyll Polyglot v1.1.0
# Fast, painless, open source i18n plugin for Jekyll 3.0 Blogs.
#   author Samuel Volin (@untra)
#   github: https://github.com/untra/polyglot
#   license: MIT
include Process
module Jekyll
  # Alteration to Jekyll Site class
  # provides aliased methods to direct site.write to output into seperate
  # language folders
  class Site
    attr_reader :default_lang, :languages
    attr_accessor :file_langs, :active_lang

    def prepare
      @file_langs = {}
      @default_lang = config['default_lang'] || 'en'
      @languages = config['languages'] || ['en']
      (@keep_files << @languages - [@default_lang]).flatten!
      @active_lang = @default_lang
    end

    alias_method :process_orig, :process
    def process
      prepare
      pids = {}
      languages.each do |lang|
        pids[lang] = Process.fork do
          process_language lang
        end
      end
      old_handler = Signal.trap('INT') do
        old_handler.call

        languages.each do |lang|
          begin
            puts "Killing #{pids[lang]} : #{lang}"
            Process.kill('INT', pids[lang])
          rescue Errno::ESRCH
            puts "Process #{pids[lang]} : #{lang} not running"
          end
        end
      end
      languages.each do |lang|
        Process.waitpid pids[lang]
        Process.detach pids[lang]
      end
    end

    alias_method :site_payload_orig, :site_payload
    def site_payload
      payload = site_payload_orig
      payload['site']['default_lang'] = default_lang
      payload['site']['languages'] = languages
      payload['site']['active_lang'] = active_lang
      payload
    end

    def process_language(lang)
      @active_lang = lang
      config['active_lang'] = @active_lang
      return process_orig if @active_lang == @default_lang
      process_active_language
    end

    def process_active_language
      @dest = @dest + '/' + @active_lang
      process_orig
    end

    # hook to coordinate blog posts into distinct urls,
    # and remove duplicate multilanguage posts
    Jekyll::Hooks.register :site, :post_read do |site|
      langs = {}
      approved = {}
      n = ''
      site.languages.each do |lang|
        n += "([\/\.]#{lang}[\/\.])|"
      end
      n.chomp! '|'
      site.posts.docs.each do |doc|
        language = doc.data['lang'] || site.default_lang
        url = doc.url.gsub(%r{#{n}}, '/')
        doc.data['permalink'] = url
        next if langs[url] == site.active_lang
        if langs[url] == site.default_lang
          next if language != site.active_lang
        end
        approved[url] = doc
        langs[url] = language
      end
      site.posts.docs = approved.values
    end
  end

  # Alteration to Jekyll Convertible module
  # provides aliased methods to direct Convertible to skip files for write under
  # certain conditions
  module Convertible
    def lang
      data['lang'] || site.config['default_lang']
    end

    def lang=(str)
      data['lang'] = str
    end

    alias_method :write_orig, :write
    def write(dest)
      path = polypath(dest)
      return if skip?(path)
      output_orig = output.clone
      write_orig(dest)
      self.output = output_orig
      site.file_langs[path] = lang
    end

    def polypath(dest)
      n = ''
      site.languages.each do |lang|
        n += "(\\\.#{lang}\\/)|"
      end
      n.chomp! '|'
      destination(dest).gsub(%r{#{n}}, '/')
    end

    def skip?(path)
      return false if site.file_langs[path].nil?
      return false if lang == site.active_lang
      if lang == site.default_lang
        return site.file_langs[path] == site.active_lang
      end
      true
    end
  end

  class StaticFile
    alias_method :write_orig, :write
    def write(dest)
      return false unless @site.active_lang == @site.default_lang
      write_orig(dest)
    end
  end
end
