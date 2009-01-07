require 'test/unit'

require 'rubygems'
gem 'activerecord'
require 'active_record'

require File.expand_path(File.dirname(__FILE__) + "/../lib/magic_meta_methods")

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :dbfile => ":memory:")

def setup_db
  ActiveRecord::Schema.define(:version => 1) do
    create_table :base_meta_models do |t|
      t.column :magic_meta_methods, :text
      t.column :type, :string
      t.column :alternate_meta, :text
    end
  end
end

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

class BaseMetaModel < ActiveRecord::Base
  magic_meta_methods([
    :a_string,
    [:a_hash, :hash],
    [:hours, :array],
    [:cats, :indifferent_hash]]
  )
end

class MetaModel < BaseMetaModel
  magic_meta_methods([
    :a_string,
    [:a_hash, :hash],
    [:hours, :array],
    [:cats, :indifferent_hash]]
  )
end

class MetaModelChild < MetaModel
  magic_meta_methods(
  [:a_string]
  )
end

class EmptyMetaModel < MetaModel
  magic_meta_methods
end

class AlternateColumnMetaModel < BaseMetaModel
  magic_meta_methods([:a_string,
                     [:a_hash, :hash],
                     [:hours, :array],
                     [:cats, :indifferent_hash]], :column => 'alternate_meta')
end

class MagicMetaMethodsTest < Test::Unit::TestCase

  def setup
    setup_db
    (1..4).each do  |counter|
      m = MetaModel.create!
      m.a_string = "yes"
      m.a_hash = {:a => 1}
      m.hours = ["1", "2", "3"]
      m.cats = HashWithIndifferentAccess.new(:cat => "cat", :cat2 => "cat2", "cat3" => "cat3")
      m.save!
    end
    MetaModelChild.create!
  end

  def teardown
    teardown_db
  end

  def test_alternate_column_name
    assert_equal AlternateColumnMetaModel.meta_methods_column, :alternate_meta
  end

  def test_meta_method_persistance
    assert_equal "yes", MetaModel.first.a_string
  end

  def test_alternate_column_create_with_meta_data
    a = AlternateColumnMetaModel.create!(:a_string => 'hello', :a_hash => {:a => 1, :b => 2})
    a = AlternateColumnMetaModel.first
    assert_equal('hello', a.a_string)
    assert_equal({:a => 1, :b => 2}, a.a_hash)
    assert_not_nil(a.alternate_meta)
  end

  def test_meta_method_hashes
    assert_equal({:a => 1}, MetaModel.first.a_hash)
  end

  def test_meta_method_indifferent_hashes
    assert_equal({"cat"=>"cat", "cat2"=>"cat2", "cat3"=>"cat3"}, MetaModel.first.cats)
  end


  def test_update_meta_method_value
    m = MetaModel.first
    m.a_string = "changed"
    m.save!
    assert_equal "changed", MetaModel.first.a_string
  end

  def test_empty_meta_method_should_return_nil
    assert_equal nil, MetaModelChild.first.a_string
  end

  def test_blank_declaration_of_meta_methods_class
    assert_nothing_raised do
      EmptyMetaModel.create!
    end
  end

  def test_init_meta_methods_should_return_hash_if_nil
    assert_equal({}, MetaModel.new.send(:init_meta_methods))
  end

  def test_should_convert_string_type
    assert_equal("String", MetaModel.new.send(:convert_to_type, "String", :string))
  end

  def test_should_convert_hash_type
    assert_equal({:a => 1, :b => 2}, MetaModel.new.send(:convert_to_type, {:a => 1, :b => 2}, :hash))
  end

  def test_should_convert_date_type
    d = Date.parse("12/5/1982")
    assert_equal(d, MetaModel.new.send(:convert_to_type, d, :date))
  end

  def test_should_raise_an_error_if_an_invalid_hash
    d = Date.parse("2/5/1998")
    assert_raise(InvalidMetaTypeError) do
      MetaModel.new.send(:convert_to_type, d, :hash)
    end
  end

  def test_should_convert_time_type
    t = Time.now
    assert_equal(t, MetaModel.new.send(:convert_to_type, t, :time))
  end

  def test_should_convert_datetime_type
    t = DateTime.now
    assert_equal(t, MetaModel.new.send(:convert_to_type, t, :datetime))
  end

  def test_should_convert_array_type
    a = [1, 2, "3"]
    assert_equal(a, MetaModel.new.send(:convert_to_type, a, :array))
  end

  def test_should_convert_integer_type
    assert_equal(1, MetaModel.new.send(:convert_to_type, 1, :integer))
  end

  def test_should_convert_float_type
    assert_equal(1.123456789, MetaModel.new.send(:convert_to_type, 1.123456789, :float) )
  end

  def test_should_convert_hash_with_indifferent_access
    hida = HashWithIndifferentAccess.new(:a => 1, :b => 2)
    assert_equal(hida, MetaModel.new.send(:convert_to_type, hida, :indifferent_hash))
  end
end