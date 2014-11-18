#-------------------------------------------------------------------------------
#
# Copyright 2013-2014 Trimble Navigation Ltd.
# License: The MIT License (MIT)
#
#-------------------------------------------------------------------------------

require 'su_safeframe.rb'

module Sketchup::Extensions::SafeFrameTools

  # Thin syntax-sugar wrapper to simpify and shorten access to persistent
  # settings.
  #
  # @since 1.0.0
  class Settings

    # @since 1.0.0
    def initialize(extension_id)
      @extension_id = extension_id
      @defaults = {}
    end

    # @since 1.0.0
    def [](key)
      Sketchup.read_default(@extension_id, key.to_s, @defaults[key])
    end

    # @since 1.0.0
    def []=(key, value)
      Sketchup.write_default(@extension_id, key.to_s, value)
    end

    def set_default(key, value)
      @defaults[key] = value
      nil
    end

  end # class


end # module
