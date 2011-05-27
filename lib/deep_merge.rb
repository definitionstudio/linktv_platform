# [PATCH] Deep merge in Rails 2.3.8 fails on HashWithIndifferentAccess
# https://rails.lighthouseapp.com/projects/8994/tickets/2732-deep_merge-does-not-work-on-hashwithindifferentaccess
# https://rails.lighthouseapp.com/projects/8994/tickets/2732/a/239457/deep_merge_replace_master.diff

# this should probably be in config/initializers, but it's not being loaded in time for the APP_CONFIG merge in linktv_platform.rb

module ActiveSupport #:nodoc:
  module CoreExtensions #:nodoc:
    module Hash #:nodoc:
      # Allows for deep merging
      module DeepMerge
        # Returns a new hash with +self+ and +other_hash+ merged recursively.
        def deep_merge(other_hash)
          target = dup
          other_hash.each_pair do |k,v|
            target[k].is_a?(::Hash) && v.is_a?(::Hash) ? target[k] = target[k].deep_merge(v) : target[k] = v
          end
          target
        end

        # Returns a new hash with +self+ and +other_hash+ merged recursively.
        # Modifies the receiver in place.
        def deep_merge!(other_hash)
          replace(deep_merge(other_hash))
        end
      end
    end
  end
end
