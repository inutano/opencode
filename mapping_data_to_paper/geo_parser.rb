# -*- coding: utf-8 -*-

require "open-uri"
require "nokogiri"

class GEOparser
  def initialize(geo_id)
    @geo_id = geo_id

    base_url = "http://www.ncbi.nlm.nih.gov/projects/geo/query/acc.cgi?"
    prefix = "targ=self&form=xml&view=full&acc=#{@geo_id}"
    @parser = Nokogiri::XML(open(base_url + prefix))
  end
  attr_accessor :parser
  
  def fax_number
    @parser.css("Fax").inner_text
  end
  
  def platform_id
    @parser.css("Platform").attribute("iid").to_s
  end
  
  def sample_id
    @parser.css("Sample").attribute("iid").to_s
  end
  
  def title
    @parser.css("Title").inner_text
  end
  
  def type
    @parser.css("Type").inner_text
  end
  
  def instrument_model
    @parser.css("Instrument-Model Predefined").inner_text
  end
  
  def sra_relation
    @parser.css("Relation").select{|n| n.attr("type") == "SRA" }.map{|n| n.attr("target") }
  end
  
  def all
    { platform_id: self.platform_id,
      sample_id: self.sample_id,
      type: self.type,
      instrument_model: self.instrument_model,
      sra_relation: self.sra_relation
    }
  end
end

if __FILE__ == $0
  require "ap"
  #id = "GSM970285"
  ids = open("./encode_GEO_accessions.txt").readlines
  ids.each do |id|
    p = GEOparser.new(id.chomp)
    ap p.all
  end
end
