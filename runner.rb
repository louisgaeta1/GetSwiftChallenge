require 'geokit'
require 'net/http'
require 'json'
require 'pry'
require 'date'

Geokit::default_units = :kms


def minimum_speed(package, drone, base)
  location = Geokit::LatLng.new(drone["location"]["latitude"], drone["location"]["longitude"])
  destination = "#{package["destination"]["latitude"]}, #{package["destination"]["longitude"]}"
  total_distance = location.distance_to(base) + base.distance_to(destination)
  hours = (DateTime.strptime(package["deadline"].to_s, '%s').to_time - Time.now)/3600
  total_distance/hours
end

def hashify(drone, package)
  Hash["droneId", drone["droneId"], "packageId", package["packageId"]]
end

def status(drones, packages)
  base = Geokit::Geocoders::GoogleGeocoder.geocode("303 Collins Street, Melbourne, VIC 3000")
  results = Hash["assignments",[], "unassigned_packageIds", []]
  unassigned_drones = drones.select { |drone| drone["packages"].length == 0 }
  assigned_drones = drones.select { |drone| drone["packages"].length > 0 }
  assigned_packageIds = assigned_drones.map { |drone| drone["packages"].first["packageId"] }
  unassigned_packages = packages.reject { |package| assigned_packageIds.include?(package["packageId"])}
  results["assignments"].concat(assigned_drones.map { |drone| hashify(drone, drone["packages"].first) })
  unassigned_packages.each do |package|
    unassigned_drones.each do |drone|
      if minimum_speed(package, drone, base) < 50
        results["assignments"].push(hashify(drone, package))
        drone["packages"].push(package)
        assigned_drones.push(unassigned_drones.delete(drone))
        assigned_packageIds.push(unassigned_packages.delete(package)["packageId"])
        break
      end
    end
  end
  results["unassigned_packageIds"].concat(unassigned_packages.map { |package| package["packageId"] })
  results
end



drones = Net::HTTP.get(URI('https://codetest.kube.getswift.co/drones'))
packages = Net::HTTP.get(URI('https://codetest.kube.getswift.co/packages'))

results = status(JSON.parse(drones), JSON.parse(packages))

binding.pry

hey = "waht"
