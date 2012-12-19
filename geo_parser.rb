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
end

if __FILE__ == $0
  require "ap"
  id = "GSM970285"
  p = GEOparser.new(id)
  ap p.parser
end
