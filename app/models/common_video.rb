module CommonVideo
  include Loggable

  class << self

    def included app
      app.module_eval do
        belongs_to :video_source

        named_scope :status_new, :conditions => {:status => :new}
        named_scope :status_accepted, :conditions => {:status => :accepted}
        named_scope :status_rejected, :conditions => {:status => :rejected}
      end
    end
    
  end

  def accepted?
    return true if imported_video.nil?
    self.imported_video.status == :accepted
  end

  def rejected?
    return false if imported_video.nil?
    self.imported_video.status == :rejected
  end

  def is_imported_video?
    false
  end

  def imported_video_keywords
    return [] if imported_video.nil?
    imported_video.nil? ? nil : imported_video.media_keywords.strip.split(/\s*,\s*/)
  end

  def published_now?
    false
  end

  def published_status
    self.published_now? ? 'Published' : 'Unpublished'
  end

  def imported_video
    # Defined only for Video objects
    nil
  end

end
