# -*- coding: utf-8 -*-

require "active_record"
require "logger"
require "yaml"
require "csv"

class ProfileInit < ActiveRecord::Migration
  def self.up
    create_table(:profiles) do |t|
      t.string :gene_name, :null => false, :limit => 20
      t.string :gene_id, :null => false

      t.string :expression, :null => false, :limit => 5
      t.float :pvalue, :null => false
      t.string :ucsc_url, :null => false
      t.timestamps
    end
    add_index :profiles, :gene_name, :name => :genename_idx
    add_index :profiles, :gene_id, :name => :geneid_idx
    add_index :profiles, :exp_acc, :name => :expacc_idx
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
    csv_path = ARGV[1]
    csv = CSV.read(csv_path)
    rm_header = csv.shift
    
    inserts = csv.map do |row|
      { gene_name: row.first,
        gene_id: row[1],
        exp_acc: row[2],
        expression: row[3],
        pvalue: row[4],
        ucsc_url: row[5] }
    end
    
    Profile.transaction do
      inserts.each do |insert|
        Profile.create(insert)
      end
    end
  end
end
