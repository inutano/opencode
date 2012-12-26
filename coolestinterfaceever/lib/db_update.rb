# -*- coding: utf-8 -*-

require "active_record"
require "logger"
require "yaml"
require "csv"

class ProfileInit < ActiveRecord::Migration
  def self.up
    create_table(:profiles) do |t|
      #t.string :gene_name
      t.string :gene_id, :null => false
      t.float :c1_tss1500
      t.float :c1_tss200
      t.float :c1_gb
      t.float :c2_tss1500
      t.float :c2_tss200
      t.float :c2_gb
      t.float :c3_tss1500
      t.float :c3_tss200
      t.float :c3_gb
      t.timestamps
    end
    #add_index :profiles, :gene_name, :name => :genename_idx
    add_index :profiles, :gene_id, :name => :geneid_idx
  end
  def self.down
    drop_table(:profiles)
  end
end

class Profile < ActiveRecord::Base
end

if __FILE__ == $0
  config = YAML.load_file("./config.yaml")
  ActiveRecord::Base.configurations = config["db"]
  ActiveRecord::Base.establish_connection("development")
  ActiveRecord::Base.logger = Logger.new(config["log"])
  
  case ARGV.first
  when "--up"
    ProfileInit.migrate(:up)
    
  when "--down"
    ProfileInit.migrate(:down)
    
  when "--insert"
    file_path = ARGV[1]
    if ARGV[1] =~ /\.csv$/
      lines = CSV.read(file_path)
      #rm_header = lines.shift
    
    elsif ARGV[1] =~ /\.tsv$/
      lines = open(file_path).readlines.map{|l| l.split("\t")}
      rm_header = lines.shift
    end
    
    inserts = lines.map do |row|
      # { gene_name: row.first,
      { gene_id: row[0],
        c1_tss1500: row[1],
        c1_tss200: row[2],
        c1_gb: row[3],
        c2_tss1500: row[4],
        c2_tss200: row[5],
        c2_gb: row[6],
        c3_tss1500: row[7],
        c3_tss200: row[8],
        c3_gb: row[9] }
    end
    
    Profile.transaction do
      inserts.each do |insert|
        Profile.create(insert)
      end
    end
  
  when "-f"
    c1_path = ARGV[1]
    c2_path = ARGV[2]
    c3_path = ARGV[3]
    
    [c1_path, c2_path, c3_path].each do |csv|
      rows = CSV.read(csv)
      rows.each do ||
      end
    end
  end
end
