require_relative './base.rb'
require_relative './akav.rb'
require_relative './kav.rb'

$available_modules = [MCollectorModule::KAV.new, MCollectorModule::AKAV.new]
$available_modules.freeze
