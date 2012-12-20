# -*- coding: utf-8 -*-

require "active_record"
require "yaml"
require "csv"

class ProfileInit < ActiveRecord::Migration
  def self.up
    create_table(:encode_demos) do |t|
      t.string :gene, :null => false, :limit => 20
      t.float :score, :null => false
      t.timestamps
    end
    add_index :encode_demos, :gene, :name => :gene_idx
  end
  def self.down
    drop_table(:encode_demos)
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
      { gene: row.first,
        score: row[1]
        }
    end
    
    Profile.transaction do
      inserts.each do |insert|
        Profile.create(insert)
        puts insert
      end
    end
  end
end
