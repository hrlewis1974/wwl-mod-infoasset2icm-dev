# IMPORT NETWORK DATA FROM CSV FILES INTO AN ICM NETWORK

## Import the 'date' library
require 'date'
WSApplication.use_arcgis_desktop_licence

## parameters
folder='C:/Users/HLewis/Downloads/wwl-mod-infoasset2icm-dev/'
db=WSApplication.open('//10.0.29.43:40000/wastewater ongoing/system_performance',false)
nw = db.model_object_from_type_and_id('Model Network',4765)

## reserve network so no-one else can use it
nw.reserve

## Define a useful class
class ImportTable
	attr_accessor :tbl_format, :in_table, :cfg_file, :csv_file, :cb_class

	def initialize(tbl_format, in_table, cfg_file, csv_file, cb_class)
		@tbl_format = tbl_format
		@in_table = in_table
		@cfg_file = cfg_file
		@csv_file = csv_file
		@cb_class = cb_class
	end
end

## Attribute Conversion from InfoAsset CSV Files into InfoWorks ICM

# Callback Classes
# Node - from InfoAsset manhole

class ImporterClassNode
	def ImporterClassNode.onBeginNode(obj)
	
		@systemTypeLookup={
			'PWDB' => 'water',    	#Potable Water Distribution
			'PWSC' => 'water',    	#Potable Water Service Connection
			'PWST' => 'water',    	#Potable Water Storage
			'PWTM' => 'water',    	#Potable Water Transmission
			'PWTP' => 'water',    	#Potable Water Treatment 
			'RWST' => 'water',    	#Raw Water Storage
			'RWTN' => 'water',    	#Raw Water Transfer
			'SWCO' => 'storm',    	#Stormwater Collection
			'SWSC' => 'storm',    	#Stormwater Service Connection
			'SWTD' => 'storm',    	#Stormwater Treatment Device
			'WWCO' => 'foul',    	#Wastewater Collection 
			'WWSC' => 'foul',    	#Wasterwater Service Connection
			'WWST' => 'foul',    	#Wastewater Storage
			'WWTP' => 'foul'     	#Wastewater Treatment 
		}
	
		@nodeTypeLookup = {		
			'ACBH' => 'manhole',    #Bore Hole  (Well / Wellhead )
			'ACCL' => 'break',    	#Chlorination Point
			'ACDP' => 'break',    	#Cable Draw Point
			'ACDW' => 'manhole',    #Dry Well 
			'ACFM' => 'manhole',    #Flowmeter Chamber
			'ACMH' => 'manhole',    #Access Chamber Manhole
			'ACPU' => 'manhole',    #Pump Chamber
			'ACSY' => 'break',    	#Syphon Chamber 
			'ACVP' => 'break',    	#Vent Point
			'ACVU' => 'manhole',    #Vacuum Chamber / Pit
			'ACVX' => 'manhole',    #Vortex Chamber
			'ACWW' => 'manhole',    #Wet Well 
			'BEND' => 'break',    	#Bend
			'END' => 'manhole',    	#End
			'HHLD' => 'break',    	#Household
			'INGD' => 'gully',    	#Inlet Grated Open End
			'INND' => 'gully',    	#Inlet Open End
			'JOIN' => 'manhole',    #Join
			'LHCE' => 'break',    	#Lamphole Cleaning Eye
			'METR' => 'break',    	#Meter
			'OTGD' => 'gully',    	#Outlet Grated Open End
			'OTND' => 'gully',    	#Outlet Open End
			'PSTN' => 'manhole',    #Pump Station
			'RGDN' => 'manhole',    #Rain Garden
			'SMP1' => 'gully',    	#Sump Single Side Entry
			'SMP2' => 'gully',    	#Sump Double Side Entry
			'SMPD' => 'gully',    	#Sump Dome
			'TEE' => 'break',     	#Tee
			'VALV' => 'break'     	#Valve
		}
	end
	
	def ImporterClassNode.onEndRecordNode(obj)
		
		inNodeType = obj['node_type']
		inSystemType = obj['system_type']
		
		if !inNodeType.nil?
			inNodeType = inNodeType#.downcase
		end
		
		if !inSystemType.nil?
			inSystemType = inSystemType#.downcase
		end
				
		if @nodeTypeLookup.has_key? inNodeType
			icmNodeNodeType = @nodeTypeLookup[inNodeType]
		else
			icmNodeNodeType = 'manhole'
		end
		
		if @systemTypeLookup.has_key? inSystemType
			icmNodeSystemType = @systemTypeLookup[inSystemType]
		else
			icmNodeSystemType = 'other'
		end
		
		obj['node_type'] = icmNodeNodeType
		obj['system_type'] = icmNodeSystemType
		
	end
end

# Pipe - from InfoAsset Pipe
#
class ImporterClassPipe
	def ImporterClassPipe.onEndRecordConduit(obj)

		@systemTypeLookup={
			'PWDB' => 'water',    	#Potable Water Distribution
			'PWSC' => 'water',    	#Potable Water Service Connection
			'PWST' => 'water',    	#Potable Water Storage
			'PWTM' => 'water',    	#Potable Water Transmission
			'PWTP' => 'water',    	#Potable Water Treatment 
			'RWST' => 'water',    	#Raw Water Storage
			'RWTN' => 'water',    	#Raw Water Transfer
			'SWCO' => 'storm',    	#Stormwater Collection
			'SWSC' => 'storm',    	#Stormwater Service Connection
			'SWTD' => 'storm',    	#Stormwater Treatment Device
			'WWCO' => 'foul',    	#Wastewater Collection 
			'WWSC' => 'foul',    	#Wasterwater Service Connection
			'WWST' => 'foul',    	#Wastewater Storage
			'WWTP' => 'foul'     	#Wastewater Treatment 
		}

		inSystemType = obj['system_type']
		
		if !inSystemType.nil?
			inSystemType = inSystemType#.upcase
		end
		
		if @systemTypeLookup.has_key? inSystemType
			icmPipeSystemType = @systemTypeLookup[inSystemType]
		else
			icmPipeSystemType = 'other'
		end
		
		obj['system_type'] = icmPipeSystemType
		
	end
end

# Pump - from InfoAsset Pump
#
class ImporterClassPump
	def ImporterClassPump.OnEndRecordPump(obj)
		
		@systemTypeLookup={
			'PWDB' => 'water',    	#Potable Water Distribution
			'PWSC' => 'water',    	#Potable Water Service Connection
			'PWST' => 'water',    	#Potable Water Storage
			'PWTM' => 'water',    	#Potable Water Transmission
			'PWTP' => 'water',    	#Potable Water Treatment 
			'RWST' => 'water',    	#Raw Water Storage
			'RWTN' => 'water',    	#Raw Water Transfer
			'SWCO' => 'storm',    	#Stormwater Collection
			'SWSC' => 'storm',    	#Stormwater Service Connection
			'SWTD' => 'storm',    	#Stormwater Treatment Device
			'WWCO' => 'foul',    	#Wastewater Collection 
			'WWSC' => 'foul',    	#Wasterwater Service Connection
			'WWST' => 'foul',    	#Wastewater Storage
			'WWTP' => 'foul'     	#Wastewater Treatment 
		}
		
		obj['link_suffix'] = obj['id'][-1]
		
		inSystemType=obj['system_type']
		
		if !inSystemType.nil?
			inSystemType = inSystemType#.downcase
		end
		
		if @systemTypeLookup.has_key? inSystemType
			icmPipeSystemType = @systemTypeLookup[inSystemType]
		else
			icmPipeSystemType = 'other'
		end
		
		obj['system_type'] = icmPipeSystemType
		
		if obj['type'].upcase == 'F' 
			obj['link_type'] == 'FIXPMP'
		elsif obj['type'].upcase == 'V' 
			obj['link_type'] == 'VSPPMP'
		elsif obj['type'].upcase == 'R' 
			obj['link_type'] = 'ROTPMP'
		elsif obj['type'].upcase == 'S' 
			obj['link_type'] = 'SCRPMP'
		end
		
	end
end

# Screen - from InfoAsset Screen
#
class ImporterClassScreen
	def ImporterClassScreen.OnEndRecordScreen(obj)
		
		@systemTypeLookup={
			'PWDB' => 'water',    	#Potable Water Distribution
			'PWSC' => 'water',    	#Potable Water Service Connection
			'PWST' => 'water',    	#Potable Water Storage
			'PWTM' => 'water',    	#Potable Water Transmission
			'PWTP' => 'water',    	#Potable Water Treatment 
			'RWST' => 'water',    	#Raw Water Storage
			'RWTN' => 'water',    	#Raw Water Transfer
			'SWCO' => 'storm',    	#Stormwater Collection
			'SWSC' => 'storm',    	#Stormwater Service Connection
			'SWTD' => 'storm',    	#Stormwater Treatment Device
			'WWCO' => 'foul',    	#Wastewater Collection 
			'WWSC' => 'foul',    	#Wasterwater Service Connection
			'WWST' => 'foul',    	#Wastewater Storage
			'WWTP' => 'foul'     	#Wastewater Treatment 
		}
		
		obj['link_suffix'] = obj['id'][-1]
		
		inSystemType=obj['system_type']
		
		if !inSystemType.nil?
			inSystemType = inSystemType#.downcase
		end
		
		if @systemTypeLookup.has_key? inSystemType
			icmPipeSystemType = @systemTypeLookup[inSystemType]
		else
			icmPipeSystemType = 'other'
		end
		
		obj['system_type'] = icmPipeSystemType
		
	end
end

# Orifice - from InfoAsset Orifice
#
class ImporterClassOrifice
	def ImporterClassOrifice.OnEndRecordOrifice(obj)
		
		@systemTypeLookup={
			'PWDB' => 'water',    	#Potable Water Distribution
			'PWSC' => 'water',    	#Potable Water Service Connection
			'PWST' => 'water',    	#Potable Water Storage
			'PWTM' => 'water',    	#Potable Water Transmission
			'PWTP' => 'water',    	#Potable Water Treatment 
			'RWST' => 'water',    	#Raw Water Storage
			'RWTN' => 'water',    	#Raw Water Transfer
			'SWCO' => 'storm',    	#Stormwater Collection
			'SWSC' => 'storm',    	#Stormwater Service Connection
			'SWTD' => 'storm',    	#Stormwater Treatment Device
			'WWCO' => 'foul',    	#Wastewater Collection 
			'WWSC' => 'foul',    	#Wasterwater Service Connection
			'WWST' => 'foul',    	#Wastewater Storage
			'WWTP' => 'foul'     	#Wastewater Treatment 
		}
		
		obj['link_suffix'] = obj['id'][-1]
		
		inSystemType=obj['system_type']
		
		if !inSystemType.nil?
			inSystemType = inSystemType#.downcase
		end
		
		if @systemTypeLookup.has_key? inSystemType
			icmPipeSystemType = @systemTypeLookup[inSystemType]
		else
			icmPipeSystemType = 'other'
		end
		
		obj['system_type'] = icmPipeSystemType
		
	end
end

# Sluice - from InfoAsset Sluice
#
class ImporterClassSluice
	def ImporterClassSluice.OnEndRecordSluice(obj)
		
		@systemTypeLookup={
			'PWDB' => 'water',    	#Potable Water Distribution
			'PWSC' => 'water',    	#Potable Water Service Connection
			'PWST' => 'water',    	#Potable Water Storage
			'PWTM' => 'water',    	#Potable Water Transmission
			'PWTP' => 'water',    	#Potable Water Treatment 
			'RWST' => 'water',    	#Raw Water Storage
			'RWTN' => 'water',    	#Raw Water Transfer
			'SWCO' => 'storm',    	#Stormwater Collection
			'SWSC' => 'storm',    	#Stormwater Service Connection
			'SWTD' => 'storm',    	#Stormwater Treatment Device
			'WWCO' => 'foul',    	#Wastewater Collection 
			'WWSC' => 'foul',    	#Wasterwater Service Connection
			'WWST' => 'foul',    	#Wastewater Storage
			'WWTP' => 'foul'     	#Wastewater Treatment 
		}
		
		obj['link_suffix'] = obj['id'][-1]
		
		inSystemType=obj['system_type']
		
		if !inSystemType.nil?
			inSystemType = inSystemType#.downcase
		end
		
		if @systemTypeLookup.has_key? inSystemType
			icmPipeSystemType = @systemTypeLookup[inSystemType]
		else
			icmPipeSystemType = 'other'
		end
		
		obj['system_type'] = icmPipeSystemType
		
	end
end

# Flume - from InfoAsset Flume
#
class ImporterClassFlume
	def ImporterClassFlume.OnEndRecordFlume(obj)
		
		@systemTypeLookup={
			'PWDB' => 'water',    	#Potable Water Distribution
			'PWSC' => 'water',    	#Potable Water Service Connection
			'PWST' => 'water',    	#Potable Water Storage
			'PWTM' => 'water',    	#Potable Water Transmission
			'PWTP' => 'water',    	#Potable Water Treatment 
			'RWST' => 'water',    	#Raw Water Storage
			'RWTN' => 'water',    	#Raw Water Transfer
			'SWCO' => 'storm',    	#Stormwater Collection
			'SWSC' => 'storm',    	#Stormwater Service Connection
			'SWTD' => 'storm',    	#Stormwater Treatment Device
			'WWCO' => 'foul',    	#Wastewater Collection 
			'WWSC' => 'foul',    	#Wasterwater Service Connection
			'WWST' => 'foul',    	#Wastewater Storage
			'WWTP' => 'foul'     	#Wastewater Treatment 
		}
		
		obj['link_suffix'] = obj['id'][-1]
		
		inSystemType=obj['system_type']
		
		if !inSystemType.nil?
			inSystemType = inSystemType#.downcase
		end
		
		if @systemTypeLookup.has_key? inSystemType
			icmPipeSystemType = @systemTypeLookup[inSystemType]
		else
			icmPipeSystemType = 'other'
		end
		
		obj['system_type'] = icmPipeSystemType
		
	end
end

# Siphon - from InfoAsset Siphon
#
class ImporterClassSiphon
	def ImporterClassSiphon.OnEndRecordSiphon(obj)
		
		@systemTypeLookup={
			'PWDB' => 'water',    	#Potable Water Distribution
			'PWSC' => 'water',    	#Potable Water Service Connection
			'PWST' => 'water',    	#Potable Water Storage
			'PWTM' => 'water',    	#Potable Water Transmission
			'PWTP' => 'water',    	#Potable Water Treatment 
			'RWST' => 'water',    	#Raw Water Storage
			'RWTN' => 'water',    	#Raw Water Transfer
			'SWCO' => 'storm',    	#Stormwater Collection
			'SWSC' => 'storm',    	#Stormwater Service Connection
			'SWTD' => 'storm',    	#Stormwater Treatment Device
			'WWCO' => 'foul',    	#Wastewater Collection 
			'WWSC' => 'foul',    	#Wasterwater Service Connection
			'WWST' => 'foul',    	#Wastewater Storage
			'WWTP' => 'foul'     	#Wastewater Treatment 
		}
		
		obj['link_suffix'] = obj['id'][-1]
		
		inSystemType=obj['system_type']
		
		if !inSystemType.nil?
			inSystemType = inSystemType#.downcase
		end
		
		if @systemTypeLookup.has_key? inSystemType
			icmPipeSystemType = @systemTypeLookup[inSystemType]
		else
			icmPipeSystemType = 'other'
		end
		
		obj['system_type'] = icmPipeSystemType
		
	end
end

# Weir - from InfoAsset Weir
#
class ImporterClassWeir
	def ImporterClassWeir.OnEndRecordWeir(obj)
		
		@systemTypeLookup={
			'PWDB' => 'water',    	#Potable Water Distribution
			'PWSC' => 'water',    	#Potable Water Service Connection
			'PWST' => 'water',    	#Potable Water Storage
			'PWTM' => 'water',    	#Potable Water Transmission
			'PWTP' => 'water',    	#Potable Water Treatment 
			'RWST' => 'water',    	#Raw Water Storage
			'RWTN' => 'water',    	#Raw Water Transfer
			'SWCO' => 'storm',    	#Stormwater Collection
			'SWSC' => 'storm',    	#Stormwater Service Connection
			'SWTD' => 'storm',    	#Stormwater Treatment Device
			'WWCO' => 'foul',    	#Wastewater Collection 
			'WWSC' => 'foul',    	#Wasterwater Service Connection
			'WWST' => 'foul',    	#Wastewater Storage
			'WWTP' => 'foul'     	#Wastewater Treatment 
		}
		
		obj['link_suffix'] = obj['id'][-1]
		
		inSystemType=obj['system_type']
		
		if !inSystemType.nil?
			inSystemType = inSystemType#.downcase
		end
		
		if @systemTypeLookup.has_key? inSystemType
			icmPipeSystemType = @systemTypeLookup[inSystemType]
		else
			icmPipeSystemType = 'other'
		end
		
		obj['system_type'] = icmPipeSystemType
		
	end
end

## Set up the config files and table names
import_tables = Array.new

import_tables.push ImportTable.new('csv', 'Node', folder + '/_network.cfg', folder + '/exports/csv/network.csv_cams_manhole.csv', ImporterClassNode)
import_tables.push ImportTable.new('csv', 'Conduit', folder + '/_network.cfg', folder + '/exports/csv/network.csv_cams_pipe.csv', ImporterClassPipe)
import_tables.push ImportTable.new('tsv', 'Pump', folder + '/_network.cfg', folder + '/exports/tsv/pump.txt', ImporterClassPump)
import_tables.push ImportTable.new('tsv', 'Screen', folder + '/_network.cfg', folder + '/exports/tsv/screen.txt', ImporterClassScreen)
import_tables.push ImportTable.new('tsv', 'Orifice', folder + '/_network.cfg', folder + '/exports/tsv/orifice.txt', ImporterClassOrifice)
import_tables.push ImportTable.new('tsv', 'Sluice', folder + '/_network.cfg', folder + '/exports/tsv/sluice.txt', ImporterClassSluice)
import_tables.push ImportTable.new('tsv', 'Flume', folder + '/_network.cfg', folder + '/exports/tsv/flume.txt', ImporterClassFlume)
import_tables.push ImportTable.new('tsv', 'Siphon', folder + '/_network.cfg', folder + '/exports/tsv/siphon.txt', ImporterClassSiphon)
import_tables.push ImportTable.new('tsv', 'Weir', folder + '/_network.cfg', folder + '/exports/tsv/weir.txt', ImporterClassWeir)
#import_tables.push ImportTable.new('tsv', 'User control', folder + '/_network.cfg', folder + '/exports/tsv/valve.txt',	'')

puts 'Import tables and config file setup'

puts 'Start import'

##set options
options=Hash.new
#options['Error File'] = 'C:\Temp\ImportErrorLog.txt'		## String | blank | Path of error file
#options['Set Value Flag'] = '#A'							## String | blank | Flag used for fields set from data
options['Default Value Flag'] = '#A'						## String | blank | Flag used for fields set from the default value column
#options['Image Folder'] = 'C:\Temp\'						## String | blank | Folder to import images from (Asset networks only)
options['Duplication Behaviour'] = 'Overwrite'				## String | Merge | One of Duplication Behaviour:'Overwrite','Merge','Ignore'
#options['Units Behaviour'] = 'Native'						## String | Native | One of 'Native','User','Custom'
#options['Update Based On Asset ID'] = false				## Boolean | false
#options['Update Only'] = false								## Boolean | false
options['Delete Missing Objects'] = true					## Boolean | false
#options['Allow Multiple Asset IDs'] = false				## Boolean | false
options['Update Links From Points'] = false					## Boolean | false
#options['Blob Merge'] = true								## Boolean | false
#options['Use Network Naming Conventions'] = false			## Boolean | false
#options['Import images'] = false							## Boolean | false | Asset networks only
#options['Group Type'] = false								## Boolean | false | Asset networks only
#options['Group Name'] = false								## Boolean | false | Asset networks only
puts 'specific import options defined'
	
## import tables into ICM
# Loop over table configs
import_tables.each{|table_info|
	
	options['Callback Class'] = table_info.cb_class
	
	# Do the import
	nw.odic_import_ex(
		table_info.tbl_format,	# input table format
		table_info.cfg_file,	# field mapping config file
		options,				# specified options override the default options
		table_info.in_table,	# import to ICM table name
		table_info.csv_file		# import from MapDrain table name
	)
}

puts 'End import'

## Commit changes and unreserve the network
nw.commit('Data imported from CSV and TSV files')
nw.unreserve
puts 'Committed'