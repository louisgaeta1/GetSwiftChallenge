require 'net/http'
require 'json'
require 'pry'
require_relative 'DroneDispatcher'


drones = Net::HTTP.get(URI('https://codetest.kube.getswift.co/drones'))
packages = Net::HTTP.get(URI('https://codetest.kube.getswift.co/packages'))

dispatcher = DroneDispatcher.new(JSON.parse(drones), JSON.parse(packages))

results = JSON.pretty_generate(dispatcher.dispatch)

puts results
