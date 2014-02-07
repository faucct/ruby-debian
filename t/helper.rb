# encoding: UTF-8
lib_dir = File.dirname(__FILE__) + '/../lib'
$:.unshift lib_dir unless $:.include?(lib_dir)

require 'minitest/autorun'
require 'debian'
