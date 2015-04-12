#

# This file is part of the Opsview puppet module
#
# The Opsview puppet module is free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
require File.join(File.dirname(__FILE__), '..', 'opsview')

begin
  require 'json'
rescue LoadError => e
  Puppet.info "You need the `json` gem for communicating with Opsview servers."
end
begin
  require 'rest-client'
rescue LoadError => e
  Puppet.info "You need the `rest-client` gem for communicating wtih Opsview servers."
end

require 'puppet'
# Config file parsing
require 'yaml'

Puppet::Type.type(:opsview_attribute).provide :opsview, :parent => Puppet::Provider::Opsview do
  @req_type = 'attribute'

  mk_resource_methods

  def self.attribute_map(attribute)
    p = { :name      => attribute["name"],
          :attribute => attribute["name"],
          :full_json => attribute,
          :ensure    => :present }

    # optional properties
    if defined? attribute["value"]
      p[:value] = attribute["value"]
    end
    if defined? attribute["arg1"]
      p[:arg1] = attribute["arg1"]
    end
    if defined? attribute["arg2"]
      p[:arg2] = attribute["arg2"]
    end
    if defined? attribute["arg3"]
      p[:arg3] = attribute["arg3"]
    end
    if defined? attribute["arg4"]
      p[:arg4] = attribute["arg4"]
    end

    if defined? attribute["encrypted_arg1"]
      p[:encrypted_arg1] = attribute["encrypted_arg1"]
    end

    if defined? attribute["encrypted_arg2"]
      p[:encrypted_arg2] = attribute["encrypted_arg2"]
    end

    if defined? attribute["encrypted_arg3"]
      p[:encrypted_arg3] = attribute["encrypted_arg3"]
    end

    if defined? attribute["encrypted_arg4"]
      p[:encrypted_arg4] = attribute["encrypted_arg4"]
    end

    if defined? attribute["label1"]
      p[:label1] = attribute["label1"]
    end

    if defined? attribute["label2"]
      p[:label2] = attribute["label2"]
    end

    if defined? attribute["label3"]
      p[:label3] = attribute["label3"]
    end

    if defined? attribute["label4"]
      p[:label4] = attribute["label4"]
    end

    if defined? attribute["secured1"]
      p[:secured1] = attribute["secured1"]
    end

    if defined? attribute["secured2"]
      p[:secured2] = attribute["secured2"]
    end

    if defined? attribute["secured3"]
      p[:secured3] = attribute["secured3"]
    end

    if defined? attribute["secured4"]
      p[:secured4] = attribute["secured4"]
    end

    p
  end

  # Query the current resource state from Opsview
  def self.prefetch(resources)
    instances.each do |provider|
      if attribute = resources[provider.name]
        attribute.provider = provider
      end
    end
  end

  def self.instances
    providers = []

    # Retrieve all attributes.  Expensive query.
    attributes = get_resources

    attributes.each do |attribute|
      providers << new(attribute_map(attribute))
    end

    providers
  end

  # Apply the changes to Opsview
  def flush
    if @attribute_json
      @updated_json = @attribute_json.dup
    else
      @updated_json = default_attribute
    end
 
    # Update the attribute's JSON values based on any new params.  Sadly due to the
    # structure of the JSON vs the flat nature of the puppet properties, this
    # is a bit of a manual task.
    if not @property_hash[:encrypted_arg1].to_s.empty?
      @updated_json["encrypted_arg1"] = @property_hash[:encrypted_arg1]
      @updated_json["secured1"] = "1"
    elsif not @property_hash[:value].to_s.empty?
      @updated_json["arg1"] = @property_hash[:arg1]
    end

    if not @property_hash[:encrypted_arg2].to_s.empty?
      @updated_json["encrypted_arg2"] = @property_hash[:encrypted_arg2]
      @updated_json["secured2"] = "1"
    elsif not @property_hash[:value].to_s.empty?
      @updated_json["arg2"] = @property_hash[:arg2]
    end

    if not @property_hash[:encrypted_arg3].to_s.empty?
      @updated_json["encrypted_arg3"] = @property_hash[:encrypted_arg3]
      @updated_json["secured3"] = "1"
    elsif not @property_hash[:value].to_s.empty?
      @updated_json["arg3"] = @property_hash[:arg3]
    end

    if not @property_hash[:encrypted_arg4].to_s.empty?
      @updated_json["encrypted_arg4"] = @property_hash[:encrypted_arg4]
      @updated_json["secured4"] = "1"
    elsif not @property_hash[:value].to_s.empty?
      @updated_json["arg4"] = @property_hash[:arg4]
    end

    if not @property_hash[:value].to_s.empty?
      @updated_json["value"] = @property_hash[:value]
    end

    if not @property_hash[:label1].to_s.empty?
      @updated_json["label1"] = @property_hash[:label1]
    end
    if not @property_hash[:label2].to_s.empty?
      @updated_json["label2"] = @property_hash[:label2]
    end
    if not @property_hash[:label3].to_s.empty?
      @updated_json["label3"] = @property_hash[:label3]
    end
    if not @property_hash[:label4].to_s.empty?
      @updated_json["label4"] = @property_hash[:label4]
    end

    if not @property_hash[:secured1].to_s.empty?
      @updated_json["secured1"] = @property_hash[:secured1]
    end
    if not @property_hash[:secured2].to_s.empty?
      @updated_json["secured2"] = @property_hash[:secured2]
    end
    if not @property_hash[:secured3].to_s.empty?
      @updated_json["secured3"] = @property_hash[:secured3]
    end
    if not @property_hash[:secured4].to_s.empty?
      @updated_json["secured4"] = @property_hash[:secured4]
    end

    @updated_json["name"] = @resource[:attribute]
  
    # Flush changes:
    put @updated_json.to_json

    if defined? @resource[:reload_opsview]
      if @resource[:reload_opsview].to_s == "true"
        Puppet.notice "Configured to reload opsview"
        do_reload_opsview
      else
        Puppet.notice "Configured NOT to reload opsview"
      end
    end

    @property_hash.clear
    @attribute_properties.clear

    false
  end

  def initialize(*args)
    super

    # Save the JSON for the attribute if it's present in the arguments
    if args[0].class == Hash and args[0].has_key?(:full_json)
      @attribute_json = args[0][:full_json]
    end

    @property_hash = @property_hash.inject({}) do |result, ary|
      param, values = ary

      # Skip any attributes we don't manage.
      next result unless self.class.resource_type.validattr?(param)

      paramclass = self.class.resource_type.attrclass(param)

      unless values.is_a?(Array)
        result[param] = values
        next result
      end

      # Only use the first value if the attribute class doesn't manage
      # arrays of values.
      if paramclass.superclass == Puppet::Parameter or paramclass.array_matching == :first
        result[param] = values[0]
      else
        result[param] = values
      end

      result
    end

    @attribute_properties = @property_hash.dup
  end

  # Return the current state of the attribute in Opsview.
  def attribute_properties
    @attribute_properties.dup
  end

  # Return (and look up if necessary) the desired state.
  def properties
    if @property_hash.empty?
      @property_hash = query || {:ensure => :absent}
      if @property_hash.empty?
        @property_hash[:ensure] = :absent
      end
    end
    @property_hash.dup
  end

  def default_attribute
    json = '
     {
       "value" :  "",
       "name" : "PUPPETUNKNOWN",
       "arg1" :  "",
       "arg2" :  "",
       "arg3" :  "",
       "arg4" :  ""
     }'

    JSON.parse(json.to_s)
  end
end
