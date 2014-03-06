#-------------------------------------------------------------------------------
#
# Copyright 2013, Trimble Navigation Limited
#
# This software is provided as an example of using the Ruby interface
# to SketchUp.
#
# Permission to use, copy, modify, and distribute this software for
# any purpose and without fee is hereby granted, provided that the above
# copyright notice appear in all copies.
#
# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
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
