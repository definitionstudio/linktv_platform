class Transcript

  # Parse transcript formatted text and return structured version
  def self.markup text
    text = CGI.escapeHTML text

    text = text.gsub(/&gt;&gt;\s*([^:]+)?:\s*/, '<dt>\1</dt>')
    text = text.gsub(/(<\/dt>)(.*?)(<dt>|\Z)/m, '\1<dd>\2</dd>\3')

    text = CGI.unescapeHTML text
  end

  # Parse transcript formatted text and return content only
  def self.content text
    markup(text).gsub(/.*?<dd>(.*?)<\/dd>/m, '\1 ')
  end

end
