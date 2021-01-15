require 'pry'
require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord

  def self.table_name #pluralize method available through active_support/inflector library
    self.to_s.downcase.pluralize
  end
  
  def self.column_names
    table_info = DB[:conn].execute("PRAGMA table_info('#{table_name}')")
    column_names = []

    table_info.each do |col_hash| #pull only the column names from the hash
      column_names << col_hash["name"]
    end
    column_names.compact
  end

  def initialize(attributes={})  #must have attr_accessors created in order to call them
    attributes.each do |attribute, value|
      self.send("#{attribute}=", value)
    end
  end

  def table_name_for_insert #create 'instance' wrapper for class method
    self.class.table_name
  end

  #create 'instance' wrapper for class method column_names
  #remove reference to 'id' column since we won't insert that
  def col_names_for_insert 
    self.class.column_names.delete_if{|col| col == "id"}.join(', ')
  end

  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    values.join(", ")
  end

  def save
    vals = values_for_insert.split(', ').map{|str| str[1..-2]}
    DB[:conn].execute("INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{vals.map{|v| '?'}.join(', ')})", vals)
    #Alternative SQL "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end
  
  def self.find_by_name(name)
    DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE name = ?", [name])
  end

  def self.find_by(attribute_hash)
    col_name = attribute_hash.keys[0].to_s
    value = attribute_hash.values[0]
    DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE #{col_name} = ?", [value])
  end

end