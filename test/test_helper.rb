require "minitest"
require "minitest/autorun"

lib = File.expand_path('../../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

test = File.expand_path('../test/', __FILE__)
$:.unshift test unless $:.include?(test)

require 'absolute_time'
require 'simple_tracing'
