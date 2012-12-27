# -*- coding: utf-8 -*-

require "open-uri"
require "nokogiri"
require "json"
require "parallel"
require "haml"
require "ap"

def pmid_to_gseid(pmid)
  base_url = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?"
  prefix = "db=pubmed&retmode=xml&id=#{pmid}"
  nkgr = Nokogiri::XML(open(base_url+prefix))
  gseid = nkgr.css("AccessionNumber").map{|n| n.inner_text }
  { pmid: pmid, gseid: gseid }
end

def pmid_to_article_info(pmid)
  base_url = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?"
  prefix = "db=pubmed&retmode=xml&id=#{pmid}"
  nkgr = Nokogiri::XML(open(base_url+prefix))
  { title: nkgr.css("ArticleTitle").inner_text,
    affiliation: nkgr.css("Affiliation").inner_text }
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
    pmids = open("../publication_pmid.txt").readlines
    pmid_gseid = Parallel.map(pmids) do |pmid|
      pmid_to_gseid(pmid.chomp)
    end
    open("./pmid_gseid.json","w"){|f| JSON.dump(pmid_gseid, f)}
    
  when "--gseid2gsmid"
    pmid_gseid_raw = open("./pmid_gseid.json").read
    pmid_gseid = JSON.parse(pmid_gseid_raw, :symbolize_names => true)
    pmid_gsmid = Parallel.map(pmid_gseid) do |pair|
      gsmids = pair[:gseid].map{|gseid| gse_to_gsm(gseid) }.flatten
      { pmid: pair[:pmid], gsmid: gsmids }
    end
    open("./pmid_gsmid.json","w"){|f| JSON.dump(pmid_gsmid, f)}
  
  when "--paper-data"
    summary = []
    pmid_gsmid_raw = open("./pmid_gsmid.json").read
    pmid_gsmid = JSON.parse(pmid_gsmid_raw, :symbolize_names => true)
    pmid_gsmid.each do |pair|
      pmid = pair[:pmid]
      gsmids = pair[:gsmid]
    
      gsmids.each do |gsmid|
        lines = `grep #{gsmid} ../experiment_list.csv`.split("\n")
        lines.each do |line|
          cs = line.split(",")
          data_type = cs.first
          cell_type = cs[1]
          ap cs.size if cs.size != 11
          if cs.size == 12
            fward = cs[2].sub("\"","")
            bward = cs[3].sub("\"","")
            experimental_factors = fward + bward
            ap experimental_factors
            treatment = cs[4]
          else
            experimental_factors = cs[2]
            treatment = cs[3]
          end
          
          article_info = pmid_to_article_info(pmid)
          title = article_info[:title]
          affiliation = article_info[:affiliation]
          
          summary << { pmid: pmid,
                       title: title,
                       affiliation: affiliation,
                       gsmid: gsmid,
                       data_type: data_type,
                       cell_type: cell_type,
                       experimental_factors: experimental_factors,
                       treatment: treatment }
        end
      end
    end
    open("./paper_data.json","w"){|f| JSON.dump(summary, f) }
  
  when "--collection"
    paper_data_raw = open("./paper_data.json").read
    paper_data = JSON.parse(paper_data_raw, :symbolize_names => true)
    
    collection = {}
    paper_data.each do |record|
      collection[record[:pmid]] ||= []
      collection[record[:pmid]] << record
    end
    open("./collection.json","w"){|f| JSON.dump(collection, f) }
  
  when "--build"
    collection = open("./collection.json"){|f| JSON.load(f) }
    haml_temp = <<EOS
!!! XML
!!!
%html
  %head
    %title ENCODE paper -> data
    %meta{ :charset => "utf-8" }
    %link{ :rel => :stylesheet, :href => "./style.css", :type => "text/css" }
    %link{ :rel => :stylesheet, :href => "http://g86.dbcls.jp/~iNut/bootstrap/css/bootstrap.css", :type => "text/css"}
    %link{ :rel => :stylesheet, :href => "http://floating-fog-3562.heroku.com/fontin_sans.css", :type => "text/css" }
  %body
    .navbar.navbar-fixed-top
      .navbar-inner
        .container
          %a.btn.btn-navbar{ "data-toggle" => "collapse", "data-target" => ".nav-collapse"}
            %span.icon-bar
            %span.icon-bar
            %span.icon-bar
          %a.brand
            op.ENcode
          .nav-collapse
            %ul.nav
              %li
                %a{:href => "http://wiki.lifesciencedb.jp/mw/index.php/BH12.12/op.ENcode" } BH12.12
              %li
                %a{:href => "https://github.com/inutano/opencode/" } GitHub
              %li
                %a{:href => "https://github.com/inutano/opencode/wiki" } Wiki
    %h4= "mapping ENCODE data to publised article."
    %section{ :class => "table_section" }
    - collection.each_pair do |k,v|
      %hr
      %h3= v.first["title"]
      %table{ :class => "table table-hover" }
        %tr
          %td pmid
          %td
            %a{ :href => "http://www.ncbi.nlm.nih.gov/pubmed/" + v.first["pmid"] }= v.first["pmid"]
        %tr
          %td affiliation
          %td= v.first["affiliation"]
      
      %hr
      %h3= "total number of dataset: " + v.size.to_s
      %table{ :class => "table table-hover"}
        %tr{ :class => "info" }
          %th GSMID
          %th data type
          %th cell type
          %th experimental factors
          %th treatment
        - v.each do |data|
          %tr
            %td
              %a{ :href => "http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=" + data["gsmid"] }= data["gsmid"]
            %td= data["data_type"]
            %td= data["cell_type"]
            %td= data["experimental_factors"]
            %td= data["treatment"]
    %footer
      op.ENCODE 2012
EOS
    obj = Object.new
    engine = Haml::Engine.new(haml_temp).def_method(obj, :render, :collection)
    html = obj.render( :collection => collection )
    open("./mapping_data_to_paper.html","w"){|f| f.puts(html) }
  end
end
