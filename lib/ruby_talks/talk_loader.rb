# frozen_string_literal: true

require 'pry'
require 'yaml'
require 'nokogiri'
require 'open-uri'

module RubyTalks
  class TalkLoader

    def initialize(config_path: )
      config = YAML.load(File.read(config_path))
      @base_url = config[:conference][:url]
      @talk_marker = config[:conference][:talk_marker] || 'presentation'
      @css_mapping = config[:mapping]
      @root_doc = Nokogiri::HTML(open(@base_url))
    end

    def load_conference
      puts @root_doc.search('a').select { |element| presentation_path?(element['href']) }.first(2)
                    .map { |path| load_talk(path['href']) }
                    .to_yaml
    end

    def load_talk(path)
      doc = Nokogiri::HTML(open(URI.join(@base_url, path)))
      @css_mapping.transform_values do |mapping|
        attr_value(doc, mapping)
      end
    end

    private

    def presentation_path?(url)
      return false unless url
      url.include?(@talk_marker)
    end

    def attr_value(doc, lookup_config)
      target = doc.css(lookup_config[:css])
      if tag = lookup_config[:search] # attribute value
        elem = target.search(tag)[lookup_config[:fetch]] || {}
        return elem[lookup_config[:attr]]
      elsif lookup_config[:text_nodes]
        binding.pry
        elem = target.children.map { |c| c.public_send(lookup_config[:value]).strip }.join(' ')
      end
    end
  end
end
