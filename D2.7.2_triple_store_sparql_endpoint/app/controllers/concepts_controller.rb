class ConceptsController < ApplicationController

	def index
		set_session(params)

		if params[:uri] || params[:ppn] || params[:q]
			@concepts = Concept.find(params) 
		elsif session[:q] || session[:ppn] || session[:uri]
			@concepts = Concept.find(session) 
		end

		if params[:uri] || params[:ppn] || session[:uri] || session[:ppn]
			@concept = @concepts
			if params[:do] == "edit"
				render :template => "concepts/edit"
				return
			elsif params[:do] == "delete"
				@concept.delete
				redirect_to :back
			else
				render :template => "concepts/show"
				return
			end
		end
	end

	def update
		@concept = Concept.find(params)
		@concept.update_attributes(params[:concept])
		redirect_to concepts_path(:uri => CGI.escape(@concept.uri))
	end

	private

	def set_session(p)
		if p[:q]
			session[:q] = p[:q] 
			session[:uri] = nil
			session[:ppn] = nil
		elsif p[:uri]
			session[:uri] = p[:uri] if p[:uri]
			session[:q] = nil
			session[:ppn] = nil
		elsif p[:ppn]
			session[:ppn] = p[:ppn] if p[:ppn]
			session[:q] = nil
			session[:uri] = nil
		end	
	end
end
