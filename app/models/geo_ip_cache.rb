class GeoIpCache < ActiveRecord::Base
  
  belongs_to :country

  validates_presence_of :ip, :country_id

  def self.lookup ip
    record = find_by_ip(ip)
    return record.country if record.present?
    return nil
  end

  def self.query ip

    logger.info("*** GeoIP query: #{ip} ***")
    
    begin
      country = Yql.geoip ip
    rescue => exc
      logger.error("*** GeoIpCache lookup failed: #{exc.message} ***")
      return nil
    end

    unless country.present?
      logger.error("*** GeoIP lookup for #{ip} returned no matching Country ***")
      return nil
    end

    self.create! :ip => ip, :country => country
    country
  end

  # run from cron:daily
  def self.cleanup
    # Delete any old entries
    logger.info("deleting geo_ip_caches older than #{1.week.ago.utc.to_s}")
    self.delete_all ["created_at < ?", 1.week.ago.utc.to_s]
  end

end

# == Schema Information
#
# Table name: geo_ip_caches
#
#  id         :integer(4)      not null, primary key
#  ip         :string(15)
#  country_id :integer(4)
#  created_at :datetime
#  updated_at :datetime
#

