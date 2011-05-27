# Utility functions
# TODO: move into static module

def parse_csv param
  param.gsub(/\s+/, '').match(/^(.*)$/)[1].split(',')
end

def query_params_string params
  params.collect {|k, v| "#{k}=#{CGI::escape(v.to_s)}" }.reverse.join('&')
end

def query_string params
  return '' if params.nil? || params.empty?
  return '?' + query_params_string(params)
end

# Strip XML tags.
# args[:add_links] Will look for links and generate anchor tags
#
def strip_xml_tags str, args = {}
  return nil unless str.present? && str.is_a?(String)
  str.gsub!(/<\/?[^>]*>/, "")
  str
end

def url_encode str
  CGI::escape str
end

def url_decode str
  CGI::unescape str
end

# May raise URI::InvalidURIError
def uri_to_hostname uri
   URI.parse(uri).host
end

# Parse URL query params into a hash
def uri_params uri
  CGI.parse(*URI.parse(uri).query)
end

# Format a time into HH:MM:SS
def format_time seconds
  seconds ||= 0
  [seconds / 3600, (seconds % 3600) / 60, seconds % 60 ].map{|t| t.to_s.rjust(2, '0')}.join(':')
end

# Convert time in HH:MM:SS to integer of seconds
def parse_time str
  match = str.match /((\d*):)?((\d*):)?(\d+)/
  time = (match[5] || 0).to_i + (match[4] || 0).to_i * 60 + (match[2] || 0).to_i * 3600
  time
end

# Based on http://railsforum.com/viewtopic.php?id=39222
def natural_time time
  time_str = '%I:%M %p'
  if time > Time.now
    # In the future
    return "#{time.strftime('%b')} #{time.day}, #{time.year} at #{time.strftime(time_str).downcase}"
  elsif time > Date.today
    return "#{time_ago_in_words(time)} ago"
  elsif time > Date.yesterday
    return "yesterday at #{time.strftime(time_str).downcase}"
  elsif time > 6.days.ago.to_date #in the last week
    return "last #{time.strftime('%A')} at #{time.strftime(time_str).downcase}"
  elsif time > Date.parse("1/1/#{Time.now.year}") #this year
    return "#{time.strftime('%b')} #{time.day} at #{time.strftime(time_str).downcase}"
  else
    return "#{time.strftime('%b')} #{time.day}, #{time.year} at #{time.strftime(time_str).downcase}"
  end
end

# Authenicate a URL
def md5_signature str
  require 'digest/md5'
  # Re-purpose the simple encryption secret key to sign the URL
  digest = Digest::MD5.hexdigest "#{str}-#{APP_CONFIG[:simple_encryption][:secret_key]}"
end