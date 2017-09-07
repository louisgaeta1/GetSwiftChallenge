require 'date'
require 'geokit'


Geokit::default_units = :kms

class DroneDispatcher

  def initialize(drones, packages)
    @drones = drones
    @packages = packages
    @base = Geokit::Geocoders::GoogleGeocoder.geocode("303 Collins Street, Melbourne, VIC 3000")
  end

  def unassigned_drones
    @drones.select { |drone| drone["packages"].length == 0 }
  end

  def assigned_drones
    @drones.select { |drone| drone["packages"].length > 0 }
  end

  def assigned_packageIds
    assigned_drones.map { |drone| drone["packages"].first["packageId"] }
  end

  def unassigned_packages
    @packages.reject { |package| assigned_packageIds.include?(package["packageId"])}
  end

  def unassigned_packageIds
    unassigned_packages.map { |package| package["packageId"] }
  end

  def hashify(drone, package)
    Hash["droneId", drone["droneId"], "packageId", package["packageId"]]
  end

  def assignments
    assigned_drones.map { |drone| hashify(drone, drone["packages"].first) }
  end

  def dispatch
    unassigned_packages.each do |package|
      closest_drone = find_closest_unassigned_drone(package)
      closest_drone["packages"].push(package) if closest_drone
    end
    results = Hash["assignments", assignments, "unassigned_packageIds", unassigned_packageIds]
  end

  def minimum_speed(package, drone)
    location = Geokit::LatLng.new(drone["location"]["latitude"], drone["location"]["longitude"])
    destination = "#{package["destination"]["latitude"]}, #{package["destination"]["longitude"]}"
    total_distance = location.distance_to(@base) + @base.distance_to(destination)
    hours = (DateTime.strptime(package["deadline"].to_s, '%s').to_time - Time.now)/3600
    total_distance/hours
  end

  def drones_that_can_reach_destination(package)
    unassigned_drones.select { |drone| minimum_speed(package, drone) < 50 }
  end

  def find_closest_unassigned_drone(package)
    drones_that_can_reach_destination(package).min do |a, b|
        minimum_speed(package, a) <=> minimum_speed(package, b)
    end
  end

end
