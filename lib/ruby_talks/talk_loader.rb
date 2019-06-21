require 'pry'
require 'yaml'
require 'nokogiri'
require 'open-uri'

module RubyTalks
  class TalkLoader
    DEFAULT_MAPPING = {
      title: '.presentation-content__title',
      announce: '.presentation-content__description',
      slides_url: '.presentation-materials__list',
      video_url: '.presentation-video__link',
      speaker: '.speaker__name',
      speaker_bio: '.speaker__bio',
      speaker_photo_url: '.speaker__img'
    }

    def initialize base_url:, css_mapping: DEFAULT_MAPPING, url_marker: 'presentation'
      @base_url = base_url
      @css_mapping = css_mapping
      @root_doc = Nokogiri::HTML(open(@base_url))
      @url_marker = url_marker
    end

    def load_conference
      puts @root_doc.search('a').select{|element| presentation_path?(element['href']) }
        .map{ |path| load_talk(path['href']) }
        .to_yaml
    end

    def load_talk path
      doc = Nokogiri::HTML(open(URI.join(@base_url, path)))
      slides = doc.css(@css_mapping[:slides_url]).search('a').last || {}
      video = doc.css(@css_mapping[:video_url]).search('a').first || {}
      photo = doc.css(@css_mapping[:speaker_photo_url]).search('img').last || {}

      {
        title: doc.css(@css_mapping[:title]).children.map{|c| c.text.strip}.join(' '),
        announce: doc.css(@css_mapping[:announce]).children.map{|c| c.text.strip}.join(' '),
        slides_url: slides['href'],
        video_url: video['href'],
        speaker: doc.css(@css_mapping[:speaker]).children.map{|c| c.text.strip}.join(' '),
        speaker_bio: doc.css(@css_mapping[:speaker_bio]).children.map{|c| c.text.strip}.join(' '),
        speaker_photo_url: photo['src']
      }
    end

    private

    def presentation_path? url
      url.include?(@url_marker)
    end
  end
end