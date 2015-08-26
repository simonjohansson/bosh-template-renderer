#!/usr/bin/env ruby
require 'yaml'
require 'erb'
require 'bosh/template/evaluation_context'

template_path, spec_path, manifest_path = ARGV

class Hash
  def dig(dotted_path)
    key, rest = dotted_path.split '.', 2
    match = self[key]
    if !rest or match.nil?
      return match
    else
      return match.dig(rest)
    end
  end

  def dig_add(dotted_path, value)
    key, rest = dotted_path.split '.', 2
    match = self[key]
    if not rest
      return self[key] = value
    elsif match.nil?
      self[key] = {}
    end
    self[key].dig_add(rest, value)
  end
end

def merge_spec_and_manifest(spec, manifest)
  spec["properties"].each do |key, val|
    prop_key = "properties.#{key}"
    default = val["default"]
    if not default.nil?
      if not manifest.dig(prop_key)
        manifest.dig_add(prop_key, default)
      end
    end
  end
end

template = File.read(template_path)
spec = YAML.load_file(spec_path)
manifest = YAML.load_file(manifest_path)

merge_spec_and_manifest(spec, manifest)
# Sometimes we want "spec.index" in the tempates
manifest.dig_add "index", 0
context = Bosh::Template::EvaluationContext.new(manifest)

erb = ERB.new(template)
puts erb.result(context.get_binding)
