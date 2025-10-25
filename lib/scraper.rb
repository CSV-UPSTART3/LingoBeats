# frozen_string_literal: true

require 'nokogiri'

def extract_lyrics(doc)
  # Ensure input is a Nokogiri HTML document
  doc = Nokogiri::HTML(doc) unless doc.is_a?(Nokogiri::HTML::Document)

  # Preserve <br> tags as line breaks before extracting text
  raw_lyrics = doc.css('div[class^="Lyrics__Container"]').map do |div|
    div.inner_html.gsub('<br>', "\n")
  end.join("\n")

  # Extract plain text from HTML
  text_only = Nokogiri::HTML(raw_lyrics).text

  # Find the first section label (e.g. [Intro], [Verse 1], [Chorus])
  lyrics_start = text_only.index(/\[[A-Za-z0-9\s#]+\]/)
  trimmed_lyrics = lyrics_start ? text_only[lyrics_start..] : text_only

  # Format sections and ensure proper line breaks
  formatted_lyrics = trimmed_lyrics
    .gsub(/\s*\[([^\]]+)\]\s*/, "\n\n[\\1]\n") # Separate section headers
    .gsub(/([a-z\)])(\[)/, "\\1\n\\2")         # Force new line before each header
    .strip

  formatted_lyrics
end