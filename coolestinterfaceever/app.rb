# -*- coding: utf-8 -*-

require "sinatra"
require "haml"
require "sass"
require "active_record"
require "logger"
require "yaml"

config = YAML.load_file("./lib/config.yaml")
ActiveRecord::Base.configurations = config["db"]
ActiveRecord::Base.establish_connection("development")
ActiveRecord::Base.logger = Logger.new(config["log"])

class Profile < ActiveRecord::Base
end

def get_result(genes, assays, cell_type)
  genes.split("\n").map do |gene|
    Profile.where(:gene => gene)
  end
end

set :haml, :format => :html5 

get "/style.css" do
  sass :style
end

get "/" do
  haml :index
end

post "/result" do
  @genes = params[:genes]
  @assays = params[:assays]
  @cell_type = params[:cell_type]
  @result = get_result(@genes, @assays, @cell_type)
  haml :result
end
