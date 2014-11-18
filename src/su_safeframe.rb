#-------------------------------------------------------------------------------
#
# Copyright 2013-2014 Trimble Navigation Ltd.
# License: The MIT License (MIT)
#
#-------------------------------------------------------------------------------

require 'sketchup.rb'
require 'extensions.rb'

#-------------------------------------------------------------------------------

module Sketchup
 module Extensions
  module SafeFrameTools

  ### CONSTANTS ### ------------------------------------------------------------

  # Plugin information
  PLUGIN_ID       = 'SafeFrameTools'.freeze
  PLUGIN_NAME     = 'Safe Frame Tools'.freeze
  PLUGIN_VERSION  = '1.0.3'.freeze

  # Resource paths
  FILENAMESPACE = File.basename(__FILE__, '.*')
  PATH_ROOT     = File.dirname(__FILE__).freeze
  PATH          = File.join(PATH_ROOT, FILENAMESPACE).freeze
  PATH_ICONS    = File.join(PATH, 'icons').freeze


  ### EXTENSION ### ------------------------------------------------------------

  unless file_loaded?(__FILE__)
    loader = File.join( PATH, 'core.rb' )
    ex = SketchupExtension.new(PLUGIN_NAME, loader)
    ex.description = 'Manipulate safe frames and export 2D images.'
    ex.version     = PLUGIN_VERSION
    ex.copyright   = 'Trimble Navigation Limited © 2013-2014'
    ex.creator     = 'SketchUp'
    Sketchup.register_extension(ex, true)
  end

  end # module SafeFrameTools
 end # module Extensions
end # module Sketchup

#-------------------------------------------------------------------------------

file_loaded(__FILE__)

#-------------------------------------------------------------------------------
