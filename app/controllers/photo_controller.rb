require 'flickraw'

class FlickRaw::Response
  def url_q
    build_img_url.gsub('?', 'q')
  end

  def url_c
    build_img_url.gsub('?', 'c')
  end

  def build_img_url
    "https://farm#{self.farm}.staticflickr.com/#{self.server}/#{self.id}_#{self.secret}_?.jpg"
  end
end

# Main controller for the application. Handles searches and results.
class PhotoController < ApplicationController
  # Home page with no results
  def index
    @results = []
  end

  # Search Flickr for photos
  def search
    @results = []

    # Searching nothing throws an exception with the gem
    if params[:search_input].to_s.strip.empty?
      # Once-off error message -- need to use .now
      flash.now[:error_msg] = "Please enter some text to search for..."
    else
      # Cache results for faster pagination
      @results = Rails.cache.fetch(params[:search_input], :expires_in => AppConfig.cache_expiry_minutes.minutes,
                                   :race_condition_ttl => AppConfig.cache_race_ttl_minutes.minutes) do

        logger.info "Caching Flicker API results for: #{params[:search_input]}"

        # Only need to initialise when calling the API
        FlickRaw.api_key = Rails.application.secrets.flickr_api_key
        FlickRaw.shared_secret = Rails.application.secrets.flickr_shared_secret

        # API call results from Flickr then add to an Array so we can paginate
        flickr.photos.search(:tags => params[:search_input], :per_page => AppConfig.flickr_max_results).each do |a|
          @results << a
        end
      end

      @results = @results.paginate(:page => params[:page], :per_page => AppConfig.results_per_page)
    end
  end
end
