require "hpricot"
class QueriesController < ApplicationController
	def new
		@query = Query.new
		@query.sparql_str = Query.find(params[:from_query]).sparql_str if params[:from_query]
		@query.sparql_str ||= "SELECT ?x\nWHERE {\n \n}" 
	end

	def create
		cached_query = Digest::SHA2.hexdigest(params[:query][:sparql_str].gsub(/\n/, "").gsub(/\s+/, ""))
		@query = Query.find_or_create_by_cached_query(:cached_query => cached_query, :sparql_str => params[:query][:sparql_str])
		if @query.cached_query.nil?
			render :action => :new
			return
		else
			redirect_to query_path(@query.id)
		end
	end

	def show
		@query = Query.find(params[:id])
		respond_to do |format|
			format.html { @results = File.open("#{RAILS_ROOT}/public/cached_results/#{@query.result_file}", "r") {|f| Hpricot::XML(f)} }
			format.xml { render :action => :create }
		end
	end

	def index
		if params[:is_shown]
			@queries = Query.find(:all, :order => "created_at DESC")
      if params[:delete_all]
        @queries.each {|q| q.delete}
      end

		else
			@queries = Query.find(:all, :conditions => {:is_shown => true}, :order => "created_at DESC")
		end
	end

	def update
		@query = Query.find(params[:id])
		@query.update_attributes(params[:query])
		redirect_to :action => :index
	end

	def destroy
		@query = Query.find(params[:id])
		@query.destroy
		redirect_to :action => :index
	end

	def common
		respond_to do |format|
			format.json { render :text => Query.common_relations(params[:ppn]).to_json }
		end
	end
end
