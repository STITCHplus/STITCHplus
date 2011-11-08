require "sinatra"
require "cgi"
require "json"
require "simple_get_response"

class Timeline
	attr_accessor :ppn, :preflabels, :results
	def initialize(ppn, preflabels = nil)
		self.ppn = ppn
		self.preflabels = ppn.nil? ? preflabels : resolve_preflabels
	end

	def resolve_preflabels(id = nil)
		preflabels = []
		id ||= self.ppn
		get = SimpleGetResponse.new("http://www.kbresearch.nl/solr/ggc-thes/select/?wt=json&q=id:%22#{id}%22&fl=prefLabel,altLabel")
		if get.success?
			resp = JSON.parse(get.body)
			preflabels = resp["response"]["docs"][0]["prefLabel"] + (resp["response"]["docs"][0]["altLabel"] || [])
		end
		get = SimpleGetResponse.new("http://www.kbresearch.nl/general/lod/get/#{id.sub(/[^:]+:[^:]+:/, "")}")
		if get.success? && get.body != "null"
			resp = JSON.parse(get.body)
			preflabels += resp["prefLabel"].map{|k, v| v}
		end
		return preflabels.uniq
	end

	def build_query
		label_part = preflabels.map{|lbl| "%22#{lbl}%22"}.join("%20OR%20")
		label_part = "%20OR%20#{label_part}" unless label_part.empty? || ppn.nil?
		ppn_part = ppn.nil? ? "" : "(PPN:%22#{ppn.sub(/^[^:]+:/, "")}%22)"
		return %(http://kbresearch.nl/solr/anp-expand/select/?q=#{ppn_part}#{label_part})
	end
end

set :public, File.dirname(__FILE__) + "/public"

get "/" do
	timeline = Timeline.new(nil, params[:q])
	@query = timeline.build_query
	erb :index
end

get "/:ppn" do
	timeline = Timeline.new(params[:ppn])
	@query = timeline.build_query
	erb :index
end
