# frozen_string_literal: true

require 'yaml'
require 'nokogiri'
require 'open-uri'

module RubyTalks
  class TalkLoader

    def initialize(base_url:, mapping_path:, url_marker: 'presentation')
      @base_url = base_url
      @css_mapping = YAML.load(File.read(mapping_path))
      @root_doc = Nokogiri::HTML(open(@base_url))
      @url_marker = url_marker
    end

    def load_conference
      puts @root_doc.search('a').select { |element| presentation_path?(element['href']) }
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
      url.include?(@url_marker)
    end

    def attr_value(doc, lookup_config)
      target = doc.css(lookup_config[:css])
      if tag = lookup_config[:search] # attribute value
        elem = target.search(tag)[lookup_config[:fetch]] || {}
        return elem[lookup_config[:attr]]
      elsif lookup_config[:text_nodes]
        elem = target.children.map { |c| c.public_send(lookup_config[:value]).strip }.join(' ')
      end
    end
  end
end
