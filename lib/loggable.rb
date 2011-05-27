module Loggable
  
  def self.included base
  end

  def log user, string
    str = log_text || ""
    str += "\r\n" unless str.blank?
    str += Time.now.utc.to_s + ": user\##{user.nil? ? "None" : user.id} #{string}"
    self.update_attribute :log_text, str
  end

end
