require_relative './base.rb'
require_relative './akav.rb'
require_relative './kav.rb'
require_relative './csv.rb'

$available_modules = [MCollectorModule::KAV.new, MCollectorModule::AKAV.new, MCollectorModule::CSV.new]
$available_modules.freeze
