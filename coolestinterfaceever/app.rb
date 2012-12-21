# -*- coding: utf-8 -*-

require "sinatra"
require "haml"
require "sass"
require "active_record"
require "logger"
require "yaml"
require "ap"

config = YAML.load_file("./lib/config.yaml")
ActiveRecord::Base.configurations = config["db"]
ActiveRecord::Base.establish_connection("development")
ActiveRecord::Base.logger = Logger.new(config["log"])

class Profile < ActiveRecord::Base
end

def get_result(genes, assays, cell_type)
  records = genes.split("\n").map do |gene|
    if gene =~ /^NM_/
      Profile.where(:gene_id => gene.chomp)
    else
      Profile.where(:gene_name => gene.chomp)
    end
  end
  records.flatten
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
  @assays = [params[:a1], params[:a2]].join(", ")
  @cell_type = [params[:c1], params[:c2], params[:c3]].join(", ")
  @result = get_result(@genes, @assays, @cell_type)
  haml :result
end
