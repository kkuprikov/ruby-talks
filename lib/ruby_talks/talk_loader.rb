# frozen_string_literal: true

require 'yaml'
require 'nokogiri'
require 'open-uri'

module RubyTalks
  class TalkLoader
    DEFAULT_MAPPING = {
      title: {
        name: 'title',
        css: '.presentation-content__title',
        text_nodes: true,
        value: 'content'
      },
      announce: {
        name: 'announce',
        css: '.presentation-content__description',
        text_nodes: true,
        value: 'content'
      },
      slides_url: {
        name: 'slides_url',
        css: '.presentation-materials__list',
        search: 'a',
        fetch: -1,
        attr: 'href'
      },
      video_url: {
        name: 'video_url',
        css: '.presentation-video__link',
        search: 'a',
        fetch: -1,
        attr: 'href'
      },
      speaker: {
        name: 'speaker',
        css: '.speaker__name',
        text_nodes: true,
        value: 'content'
      },
      speaker_bio: {
        name: 'speaker_bio',
        css: '.speaker__bio',
        text_nodes: true,
        value: 'content'
      },
      speaker_photo_url: {
        name: 'speaker_photo_url',
        css: '.speaker__img',
        search: 'img',
        fetch: -1,
        attr: 'src'
      }
    }.freeze

    def initialize(base_url:, css_mapping: DEFAULT_MAPPING, url_marker: 'presentation')
      @base_url = base_url
      @css_mapping = css_mapping
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
