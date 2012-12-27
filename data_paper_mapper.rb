# -*- coding: utf-8 -*-

require "open-uri"
require "nokogiri"
require "json"
require "parallel"
require "ap"

def pmid_to_gseid(pmid)
  base_url = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?"
  prefix = "db=pubmed&retmode=xml&id=#{pmid}"
  nkgr = Nokogiri::XML(open(base_url+prefix))
  gseid = nkgr.css("AccessionNumber").map{|n| n.inner_text }
  { pmid: pmid, gseid: gseid }
end

def gse_to_gsm(gseid)
  base_url = "http://www.ncbi.nlm.nih.gov/projects/geo/query/acc.cgi?"
  prefix = "targ=self&form=xml&view=full&acc=#{gseid}"
  nkgr = Nokogiri::XML(open(base_url+prefix))
  nkgr.css("Sample").map{|n| n.attribute("iid").to_s }
end

if __FILE__ == $0
  case ARGV.first
  when "--pmid2gseid"
    pmids = open("publication_pmid.txt").readlines
    pmid_gseid = Parallel.map(pmids) do |pmid|
      pmid_to_gseid(pmid.chomp)
    end
    open("pmid_gseid.json","w"){|f| JSON.dump(pmid_gseid, f)}
    
  when "--gseid2gsmid"
    pmid_gseid = open("pmid_gseid.json"){|f| JSON.load(f) }
    pmid_gsmid = Parallel.map(pmid_gseid) do |pair|
      gsmids = pair[:gseid].map{|gseid| gse_to_gsm(gseid) }.flatten
      { pmid: pair[:pmid], gsmid: gsmids }
    end
    open("pmid_gsmid.json","w"){|f| JSON.dump(pmid_gsmid, f)}
  
  when "--gsmid"
  summary = []
  pmid_geoid.each do |pair|
    pmid = pair[:pmid]
    geoids = pair[:geoid]
    
    geoids.each do |geoid|
      lines = `grep #{geoid} ./experiment_list.csv`.split("\n")
      lines.each do |line|
        cs = line.split(",")
        data_type = cs.first
        cell_type = cs[1]
        if cs.size == 12
          fward = cs[2].sub("\"","")
          bward = cs[3].sub("\"","")
          experimental_factors = fward + bward
          treatment = cs[4]
        else
          experimental_factors = cs[2]
          treatment = cs[4]
        end
        
        summary << { pmid: pmid,
                     geoid: geoid,
                     data_type: data_type,
                     cell_type: cell_type,
                     expermental_factors: experimental_factors,
                     treatment: treatment }
      end
    end
  end
  
  open("./data_paper_map.json","w"){|f| JSON.dump(summary, f) }
=end
end
