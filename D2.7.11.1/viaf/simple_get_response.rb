#    SimpleGetResponse class: A wrapper to simplify doing GET requests via http/net
#    Copyright (C) 2010  R. van der Ark
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

require "net/http"
require "uri"

# A wrapper class to simplify doing GET requests via http/net
class SimpleGetResponse
  attr_accessor :response, :http, :url, :host, :port

	public
	# Initialize net/http and do request
	#	  resp = SimpleGetResponse.new("http://foo/bar")
	#	  resp = SimpleGetResponse.new("http://foo/bar", {:timeout => 1, :max_tries => 5})
  def initialize(set_url, params = {})
		set_url = "http://#{self.host}#{set_url}" if !(set_url =~ /^http:\/\//) && self.host
    self.url = URI.parse(set_url)
		self.host = url.host
    self.http = Net::HTTP.new(url.host || self.host, url.port || self.port)

	  self.http.read_timeout = params[:timeout] || 5
    self.http.open_timeout = params[:timeout] || 5
    get_response(params[:max_tries] || 1)
  end

	# Return the response body
	#		resp = SimpleGetResponse.new("http://foo/bar/")
	#		doc = resp.body if resp.success?
  def body
    return self.response.body
  end

	# Check whether the request was succesful
  def success?
    case self.response
      when Net::HTTPSuccess
        return true
      else
        return false
    end
  end

	private
	# Try to GET the response body a given number of times (called from constructor)
	# Follows redirects, retries in case of timeouts
  def get_response(tries = 1)
    (1..tries).each do |i|
      success = true
      begin
        self.response = http.start {|http|
					begin
	          http.request_get(url.request_uri)
					rescue Timeout::Error
						$stderr.puts "Timeout on #{self.url.request_uri}"
						success = false
					end
        }
        break if success
      rescue
        $stderr.puts puts "Try #{i} on #{self.url.request_uri}: #{$!}"
        sleep 1
      end
    end
		initialize(redirect_url) if response.kind_of?(Net::HTTPRedirection)
  end

	# Generate a redirect URL from a response body in case of a HTTPRedirection
  def redirect_url
    if response['location'].nil?
      response.body.match(/<a href=\"([^>]+)\">/i)[1]
    else
      response['location']
    end
  end
end
